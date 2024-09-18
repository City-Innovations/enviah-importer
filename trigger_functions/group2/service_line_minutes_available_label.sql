CREATE OR REPLACE FUNCTION public.service_line_minutes_available_label()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
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
$function$
