CREATE OR REPLACE FUNCTION public.combined_service_line_operations()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- Trigger #1: Visits and Capacity Calculations

    -- 1. Calculate service_line_visits_per_room
    IF NEW.type_of_service = 'Outpatient' OR NEW.type_of_service = 'Treatment' THEN
        IF NEW.cd_number_of_patient_rooms IS NULL OR NEW.cd_number_of_patient_rooms = 0 THEN
            NEW.visits_per_room := NULL;
        ELSE
            NEW.visits_per_room := NEW.cd_visits_annually / NEW.cd_number_of_patient_rooms;
        END IF;
    ELSIF NEW.type_of_service = 'Inpatient' THEN
        IF NEW.ip_number_of_licensed_beds IS NULL OR NEW.ip_number_of_licensed_beds = 0 THEN
            NEW.visits_per_room := NULL;
        ELSE
            NEW.visits_per_room := NEW.ip_patient_days_year_1 / NEW.ip_number_of_licensed_beds;
        END IF;
    ELSIF NEW.type_of_data = 'Rehab' THEN
        IF NEW.outpatient_sf IS NULL OR NEW.outpatient_sf = 0 THEN
            NEW.visits_per_room := NULL;
        ELSE
            NEW.visits_per_room := NEW.cd_visits_annually / NEW.outpatient_sf;
        END IF;
    ELSE
        NEW.visits_per_room := 0;
    END IF;

    -- 2. service_line_rehab_maximum_visits_per_room
    IF NEW.type_of_data <> 'Rehab' THEN
        NEW.rehab_maximum_visits_per_room := 0;
    ELSE
        SELECT s.rehab_maximum_visits_per_room
        INTO NEW.rehab_maximum_visits_per_room
        FROM standards s
        WHERE s.system_name = NEW.system_name
          AND s.type_of_data = NEW.type_of_data
          AND s.type_of_service = NEW.type_of_service
          AND s.header = 'Rehab_Maximum_Visits_Per_Room'
        LIMIT 1;
    END IF;

    -- 3. service_line_outpatient_treatment_maximum_visits_per_room
    IF NEW.type_of_service = 'Outpatient' OR NEW.type_of_service = 'Treatment' THEN
        IF (NEW.cd_length_of_time_a_visit_takes + NEW.cd_turnover_between_patients) = 0 THEN
            NEW.outpatient_treatment_maximum_visits_per_room := NULL;
        ELSE
            NEW.outpatient_treatment_maximum_visits_per_room := NEW.standard_minutes_available_for_clinic / (NEW.cd_length_of_time_a_visit_takes + NEW.cd_turnover_between_patients);
        END IF;
    ELSE
        NEW.outpatient_treatment_maximum_visits_per_room := 0;
    END IF;

    -- 4. service_line_inpatient_maximum_visits_per_year
    IF NEW.type_of_service = 'Inpatient' THEN
        BEGIN
            NEW.inpatient_maximum_visits_per_year := NEW.ip_maximum_patient_days / NEW.ip_number_of_licensed_beds;
        EXCEPTION WHEN division_by_zero THEN
            NEW.inpatient_maximum_visits_per_year := NULL;
        END;
    ELSE
        NEW.inpatient_maximum_visits_per_year := 0;
    END IF;

    -- 5. service_line_maximum_visits_per_room
    IF NEW.type_of_data = 'Rehab' THEN
        NEW.maximum_visits_per_room := NEW.rehab_maximum_visits_per_room;
    ELSE
        NEW.maximum_visits_per_room := NEW.outpatient_treatment_maximum_visits_per_room;
    END IF;

    -- 6. service_line_capacity_of_visits_available
    IF NEW.type_of_service = 'Outpatient' OR NEW.type_of_service = 'Treatment' THEN
        NEW.capacity_of_visits_available := NEW.maximum_visits_per_room * NEW.cd_number_of_patient_rooms;
    ELSE
        NEW.capacity_of_visits_available := NEW.inpatient_maximum_visits_per_year * NEW.ip_number_of_licensed_beds;
    END IF;

    -- 7. service_line_percent_capacity
    IF NEW.visits_per_room IS NULL OR NEW.visits_per_room = 0 THEN
        NEW.percent_capacity := NULL;
    ELSE
        NEW.percent_capacity := (NEW.capacity_of_visits_available / NEW.visits_per_room) * 100;
    END IF;

    -- 8. service_line_target_capacity
    SELECT s.target_capacity
    INTO NEW.target_capacity
    FROM standards s
    WHERE s.system_name = NEW.system_name
      AND s.type_of_data = NEW.type_of_data
      AND s.type_of_service = NEW.type_of_service
      AND s.header = 'Target_Capacity'
    LIMIT 1;

    -- 9. service_line_capacity_available_label
    IF NEW.percent_capacity < 50 THEN
        NEW.capacity_available_label := 'Low Capacity';
    ELSIF NEW.percent_capacity < 75 THEN
        NEW.capacity_available_label := 'Medium Capacity';
    ELSE
        NEW.capacity_available_label := 'High Capacity';
    END IF;

    -- 10. service_line_total_visit_capacity_given_rooms
    IF NEW.type_of_service = 'Outpatient' OR NEW.type_of_service = 'Treatment' THEN
        NEW.total_visit_capacity_given_rooms := NEW.target_capacity * NEW.cd_number_of_patient_rooms;
    ELSE
        NEW.total_visit_capacity_given_rooms := NEW.target_capacity * NEW.ip_number_of_licensed_beds;
    END IF;

    -- 11. service_line_total_visits_available
    IF NEW.percent_capacity IS NULL OR NEW.percent_capacity = NULL THEN
        NEW.total_visits_available := NULL;
    ELSE
        IF NEW.type_of_service = 'Inpatient' THEN
            NEW.total_visits_available := NEW.ip_available_pt_days_at_occupancy_rate;
        ELSE
            NEW.total_visits_available := NEW.total_visit_capacity_given_rooms - NEW.cd_visits_annually;
        END IF;
    END IF;

    -- 12. service_line_total_visits_available_per_room
    NEW.total_visits_available_per_room := NEW.target_capacity - NEW.visits_per_room;

    -- Trigger #2: Standard Minutes and Growth Calculations

    -- 1. service_line_standard_minutes_available_for_clinic
    IF NEW.type_of_service = 'Outpatient' THEN
        NEW.standard_minutes_available_for_clinic := NEW.cd_hours_of_operations_in_minutes * NEW.cd_days_open_per_week * 50;
    ELSE
        NEW.standard_minutes_available_for_clinic := 0;
    END IF;

    -- 2. service_line_visit_minutes_per_staff
    IF NEW.type_of_service IN ('Outpatient', 'Treatment') THEN
        IF NEW.cd_length_of_time_a_visit_takes IS NOT NULL AND 
           NEW.cd_turnover_between_patients IS NOT NULL AND 
           NEW.cd_visits_annually IS NOT NULL AND 
           NEW.cd_number_of_providers_or_patient_facing_staff IS NOT NULL AND 
           NEW.cd_number_of_pt_a_provider_sees_at_once IS NOT NULL THEN
            NEW.visit_minutes_per_staff := 
                ((NEW.cd_length_of_time_a_visit_takes + NEW.cd_turnover_between_patients) * NEW.cd_visits_annually) 
                / NEW.cd_number_of_providers_or_patient_facing_staff 
                / NEW.cd_number_of_pt_a_provider_sees_at_once;
        ELSE
            NEW.visit_minutes_per_staff := 0;
        END IF;
    ELSE
        NEW.visit_minutes_per_staff := 0;
    END IF;

    -- 3. service_line_rehab_std_mins_provider
    IF NEW.type_of_service = 'Rehab' THEN
        NEW.rehab_std_mins_provider := NEW.visit_minutes_per_staff * NEW.cd_number_of_pt_a_provider_sees_at_once;
    ELSE
        NEW.rehab_std_mins_provider := NULL;
    END IF;

    -- 4. service_line_outpatient_treatment_standard_minutes_per_provider
    IF NEW.type_of_service = 'Outpatient' OR NEW.type_of_service = 'Treatment' THEN
        IF NEW.cd_visits_annually IS NOT NULL AND 
           NEW.cd_number_of_providers_or_patient_facing_staff IS NOT NULL THEN
            NEW.outpatient_treatment_standard_minutes_per_provider := 
                NEW.cd_visits_annually / NEW.cd_number_of_providers_or_patient_facing_staff;
        ELSE
            NEW.outpatient_treatment_standard_minutes_per_provider := 0;
        END IF;
    ELSE
        NEW.outpatient_treatment_standard_minutes_per_provider := 0;
    END IF;

    -- 5. service_line_standard_minutes_for_each_staff
    IF NEW.cd_visits_annually IS NOT NULL AND 
       NEW.cd_number_of_providers_or_patient_facing_staff IS NOT NULL THEN
        NEW.standard_minutes_for_each_staff := 
            NEW.cd_visits_annually / NEW.cd_number_of_providers_or_patient_facing_staff;
    ELSE
        NEW.standard_minutes_for_each_staff := 0;
    END IF;

    -- 6. service_line_growth
    IF COALESCE(NEW.standard_minutes_for_each_staff, 0) = 0 OR COALESCE(NEW.visit_minutes_per_staff, 0) = 0 THEN 
        NEW.growth := NULL;
    ELSE
        NEW.growth := NEW.standard_minutes_for_each_staff - NEW.visit_minutes_per_staff;
    END IF;

    -- 7. service_line_percent_growth
    IF NEW.standard_minutes_for_each_staff = 0 THEN 
        NEW.percent_growth := NULL;
    ELSE
        NEW.percent_growth := NEW.visit_minutes_per_staff / NEW.standard_minutes_for_each_staff;
    END IF;

    -- 8. service_line_target_minutes
    NEW.target_minutes := NEW.standard_minutes * 0.75;

    -- 9. service_line_minutes_available
    NEW.minutes_available := NEW.target_minutes - NEW.visit_minutes_per_staff;
    IF NEW.minutes_available < 0 THEN
        NEW.minutes_available := 0;
    END IF;

    -- 10. service_line_minutes_available_label
    IF NEW.type_of_service = 'Inpatient' THEN 
        NEW.minutes_available_label := ' ';
    ELSIF NEW.type_of_service = 'Outpatient' THEN 
        NEW.minutes_available_label := 'Minutes';
    ELSIF NEW.type_of_service = 'Treatment' THEN 
        NEW.minutes_available_label := 'Minutes';
    ELSE 
        NEW.minutes_available_label := NULL;
    END IF;

    -- Trigger #3: Square Footage Calculations

    -- 1. service_line_actual_sf_per_room
    IF (NEW.type_of_data = 'Lab' OR NEW.type_of_data = 'Pharmacy') AND NEW.type_of_service = 'Inpatient' THEN
        NEW.actual_sf_per_room := NEW.support_services_sf / NEW.ip_number_of_licensed_beds;
    ELSIF NEW.type_of_service = 'Inpatient' THEN
        NEW.actual_sf_per_room := NEW.inpatient_sf / NEW.ip_number_of_licensed_beds;
    ELSIF NEW.type_of_data = 'Rehab' THEN
        NEW.actual_sf_per_room := NEW.cd_number_of_providers_or_patient_facing_staff / (NEW.total_sf / 100);
    ELSIF NEW.type_of_service = 'Outpatient' THEN
        NEW.actual_sf_per_room := NEW.outpatient_sf / NEW.cd_number_of_patient_rooms;
    ELSIF NEW.type_of_service = 'Treatment' THEN
        NEW.actual_sf_per_room := NEW.outpatient_sf / NEW.cd_number_of_patient_rooms;
    ELSE
        NEW.actual_sf_per_room := 0;
    END IF;

    -- 2. service_line_rehab_standard_sf_per_room
    IF NEW.type_of_data <> 'Rehab' THEN
        NEW.rehab_standard_sf_per_room := 0;
    ELSE
        SELECT s.rehab_standard_sf_per_room 
        INTO NEW.rehab_standard_sf_per_room
        FROM standards s
        WHERE s.system_name = NEW.system_name
          AND s.type_of_data = NEW.type_of_data
          AND s.type_of_service = NEW.type_of_service
        LIMIT 1;
        NEW.rehab_standard_sf_per_room := COALESCE(NEW.rehab_standard_sf_per_room, 0);
    END IF;

    -- 3. service_line_ip_standard_sf_per_room
    IF NEW.type_of_service = 'Inpatient' THEN
        SELECT s.ip_standard_sf_per_room 
        INTO NEW.ip_standard_sf_per_room
        FROM standards s
        WHERE s.type_of_data = NEW.type_of_data
          AND s.type_of_service = NEW.type_of_service
        LIMIT 1;
        NEW.ip_standard_sf_per_room := COALESCE(NEW.ip_standard_sf_per_room, 0);
    END IF;

    -- 4. service_line_lab_pharmacy_standard_sf_per_room
    IF NEW.type_of_data IN ('Lab', 'Pharmacy') AND NEW.type_of_service = 'Inpatient' THEN
        NEW.lab_pharmacy_standard_sf_per_room := NEW.support_services_sf / NEW.ip_number_of_licensed_beds;
    ELSE
        NEW.lab_pharmacy_standard_sf_per_room := 0;
    END IF;

    -- 5. service_line_outpatient_treatment_standard_sf_per_room
    IF NEW.type_of_service IN ('Outpatient', 'Treatment') THEN
        IF NEW.cd_visits_annually IS NOT NULL AND 
           NEW.cd_number_of_providers_or_patient_facing_staff IS NOT NULL THEN
            NEW.outpatient_treatment_standard_sf_per_room := 
                NEW.cd_visits_annually / NEW.cd_number_of_providers_or_patient_facing_staff;
        ELSE
            NEW.outpatient_treatment_standard_sf_per_room := 0;
        END IF;
    ELSE
        NEW.outpatient_treatment_standard_sf_per_room := 0;
    END IF;

    -- 6. service_line_standard_sf_per_room
    IF NEW.type_of_service = 'Outpatient' AND NEW.type_of_data = 'Rehab' THEN
        NEW.standard_sf_per_room := NEW.rehab_standard_sf_per_room;
    ELSEIF NEW.type_of_service IN ('Outpatient', 'Treatment') THEN
        NEW.standard_sf_per_room := NEW.outpatient_treatment_standard_sf_per_room;
    ELSEIF NEW.type_of_service = 'Inpatient' THEN
        NEW.standard_sf_per_room := NEW.ip_standard_sf_per_room;
    ELSEIF NEW.type_of_data IN ('Lab', 'Pharmacy') AND NEW.type_of_service = 'Inpatient' THEN
        NEW.standard_sf_per_room := NEW.lab_pharmacy_standard_sf_per_room;
    ELSE
        NEW.standard_sf_per_room := 0;
    END IF;

    -- 7. service_line_maximum_sf_per_room
    NEW.maximum_sf_per_room := NEW.standard_sf_per_room * 1.25;

    -- 8. service_line_percent_efficiency
    IF NEW.standard_sf_per_room = 0 THEN 
        NEW.percent_efficiency := 0;
    ELSE
        BEGIN
            NEW.percent_efficiency := NEW.actual_sf_per_room / NEW.standard_sf_per_room;
        EXCEPTION 
            WHEN OTHERS THEN 
                NEW.percent_efficiency := 0;
        END;
    END IF;

    -- 9. service_line_available_number_of_rooms
    IF NEW.sf IS NOT NULL AND NEW.standard_sf_per_room IS NOT NULL AND NEW.standard_sf_per_room != 0 THEN
        NEW.available_number_of_rooms := NEW.sf / NEW.standard_sf_per_room;
    ELSE
        NEW.available_number_of_rooms := NULL;
    END IF;

    RETURN NEW;
END;
$$;