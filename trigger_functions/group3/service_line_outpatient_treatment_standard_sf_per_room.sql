CREATE OR REPLACE FUNCTION public.service_line_outpatient_treatment_standard_sf_per_room()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE 
	standard_sf NUMERIC; 
BEGIN 
	IF NEW.type_of_service = 'Outpatient' OR NEW.type_of_service = 'Treatment' THEN 
		BEGIN 
			SELECT s.standard_sf_per_revenue_generating_room 
			INTO standard_sf 
			FROM standards s 
			WHERE s.type_of_data = NEW.type_of_data 
				AND s.type_of_service = NEW.type_of_service 
			LIMIT 1; 

			NEW.outpatient_treatment_standard_sf_per_room := COALESCE(standard_sf, 0); 
		EXCEPTION 
			WHEN OTHERS THEN 
				NEW.outpatient_treatment_standard_sf_per_room := 0; 
		END; 
	ELSE 
		NEW.outpatient_treatment_standard_sf_per_room := 0; 
END IF;
RETURN NEW; 
END;
$function$
