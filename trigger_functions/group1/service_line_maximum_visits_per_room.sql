CREATE OR REPLACE FUNCTION public.service_line_maximum_visits_per_room()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN 
	IF NEW.type_of_service = 'Outpatient' AND NEW.type_of_data = 'Rehab' THEN
		NEW.maximum_visits_per_room := NEW.rehab_maximum_visits_per_room; 
	ELSIF NEW.type_of_service = 'Inpatient' THEN 
		NEW.maximum_visits_per_room := NEW.inpatient_maximum_visits_per_year; 
	ELSIF NEW.type_of_service = 'Treatment' OR NEW.type_of_service = 'Outpatient' THEN
		NEW.maximum_visits_per_room := NEW.outpatient_treatment_maximum_visits_per_room; 
	ELSE 
		NEW.maximum_visits_per_room := 0; 
	END IF;

	RETURN NEW; 
END;
$function$
