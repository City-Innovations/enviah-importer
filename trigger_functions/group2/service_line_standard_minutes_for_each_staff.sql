CREATE OR REPLACE FUNCTION public.service_line_standard_minutes_for_each_staff()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
	IF NEW.type_of_service = 'Inpatient' THEN
		NEW.standard_minutes_for_each_staff := 0; 
	ELSE 
		IF NEW.type_of_data = 'Rehab' THEN 
			NEW.standard_minutes_for_each_staff := NEW.rehab_standard_minutes_per_provider; 
		ELSE 
			IF NEW.type_of_service IN ('Outpatient', 'Treatment') THEN 
				NEW.standard_minutes_for_each_staff := NEW.outpatient_treatment_standard_minutes_per_provider; 
			ELSE 
				NEW.standard_minutes_for_each_staff := 0; 
			END IF; 
		END IF; 
	END IF;
	RETURN NEW; 
END;
$function$
