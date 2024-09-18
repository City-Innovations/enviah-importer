CREATE OR REPLACE FUNCTION public.service_line_lab_pharmacy_standard_sf_per_room()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE 
	standard_sf NUMERIC; 
BEGIN 
	IF NEW.type_of_service = 'Inpatient' AND (NEW.type_of_data = 'Lab' OR NEW.type_of_data = 'Pharmacy') THEN 
		BEGIN 
			SELECT s.standard_sf_per_revenue_generating_room 
			INTO standard_sf 
			FROM standards s 
			WHERE s.type_of_data = NEW.type_of_data 
				AND s.type_of_service = NEW.type_of_service 
				AND s.number_of_beds = NEW.ip_rounded_number_of_beds 
			LIMIT 1; 

			NEW.lab_pharmacy_standard_sf_per_room := COALESCE(standard_sf, 0); 
		EXCEPTION 
			WHEN OTHERS THEN 
				NEW.lab_pharmacy_standard_sf_per_room := 0; 
		END; 
	ELSE 
		NEW.lab_pharmacy_standard_sf_per_room := 0; 
	END IF; 
	RETURN NEW; 
END;
$function$
