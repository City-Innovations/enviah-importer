CREATE OR REPLACE FUNCTION public.service_line_minutes_available()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	minutes_available INTEGER;
BEGIN
    minutes_available := NEW.target_minutes - NEW.visit_minutes_per_staff;
    IF minutes_available < 0 THEN
        minutes_available := 0;
    END IF;

    NEW.minutes_available := minutes_available;

RETURN NEW; 
END;
$function$
