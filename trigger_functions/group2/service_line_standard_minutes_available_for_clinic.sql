CREATE OR REPLACE FUNCTION public.service_line_standard_minutes_available_for_clinic()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.type_of_service = 'Outpatient' THEN
        NEW.standard_minutes_available_for_clinic := NEW.cd_hours_of_operations_in_minutes * NEW.cd_days_open_per_week * 50;
    ELSE
        NEW.standard_minutes_available_for_clinic := 0;
    END IF;
    RETURN NEW;
END;
$function$
