CREATE OR REPLACE FUNCTION public.service_line_rehab_maximum_visits_per_room()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
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
    RETURN NEW;
END;
$function$
