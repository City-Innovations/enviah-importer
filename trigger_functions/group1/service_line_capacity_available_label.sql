CREATE OR REPLACE FUNCTION public.service_line_capacity_available_label()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
	IF NEW.total_visits_available IS NULL OR NEW.total_visits_available = NULL THEN 
		NEW.total_visits_available := NULL; 
	ELSE 
		IF NEW.type_of_service = 'Inpatient' THEN 
			NEW.total_visits_available := 'Patient Days'; 
		ELSIF NEW.type_of_service = 'Outpatient' THEN 
			NEW.total_visits_available := 'Visits';
		ELSIF NEW.type_of_service = 'Treatment' THEN 
			NEW.total_visits_available := 'Visits'; 
		ELSE 
			NEW.total_visits_available := NULL; 
		END IF; 
	END IF;	
	RETURN NEW; 
END;
$function$
