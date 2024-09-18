CREATE OR REPLACE FUNCTION public.service_line_growth()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
	IF COALESCE(NEW.standard_minutes_for_each_staff, 0) = 0 OR COALESCE(NEW.visit_minutes_per_staff, 0) = 0 THEN 
		NEW.growth := NULL; 
	ELSE NEW.growth := NEW.standard_minutes_for_each_staff - NEW.visit_minutes_per_staff; 
	END IF;
	RETURN NEW; 
END;
$function$
