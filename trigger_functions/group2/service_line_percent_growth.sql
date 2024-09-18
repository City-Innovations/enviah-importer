CREATE OR REPLACE FUNCTION public.service_line_percent_growth()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
IF NEW.standard_minutes_for_each_staff = 0 THEN 
NEW.percent_growth := NULL; 
ELSE 
BEGIN 
NEW.percent_growth := NEW.visit_minutes_per_staff / NEW.standard_minutes_for_each_staff; 
EXCEPTION 
WHEN OTHERS THEN 
NEW.percent_growth := NULL; 
END; 
END IF;
RETURN NEW; 
END;
$function$
