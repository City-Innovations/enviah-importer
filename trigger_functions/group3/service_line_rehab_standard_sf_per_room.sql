CREATE OR REPLACE FUNCTION public.service_line_rehab_standard_sf_per_room()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE 
	standard_sf NUMERIC; 
BEGIN 
	IF NEW.type_of_data <> 'Rehab' THEN 
		NEW.rehab_standard_sf_per_room := 0; 
	ELSE 
		SELECT s.rehab_standard_sf_per_room 
		INTO standard_sf 
		FROM standards s 
		WHERE s.system_name = NEW.system_name 
			AND s.type_of_data = NEW.type_of_data 
			AND s.type_of_service = NEW.type_of_service 
		LIMIT 1; 

		NEW.rehab_standard_sf_per_room := COALESCE(standard_sf, 0); 
	END IF;
	RETURN NEW; 
END;
$function$
