CREATE OR REPLACE FUNCTION public.combined_service_line_trigger()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
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

    RETURN NEW;
END;
$$;