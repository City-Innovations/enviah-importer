CREATE OR REPLACE FUNCTION public.service_line_visits_per_room()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
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
    RETURN NEW;
END;
$function$
