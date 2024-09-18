CREATE OR REPLACE FUNCTION public.combined_service_line_sf_trigger()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
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