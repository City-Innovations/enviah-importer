CREATE OR REPLACE FUNCTION public.service_line_percent_efficiency()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN 
	IF NEW.standard_sf_per_room = 0 THEN 
		NEW.percent_efficiency := 0; 
	ELSE 
		BEGIN 
			NEW.percent_efficiency := NEW.actual_sf_per_room / NEW.standard_sf_per_room; 
		EXCEPTION 
			WHEN OTHERS THEN 
				NEW.percent_efficiency := 0; 
		END; 
	END IF;	
	RETURN NEW;
END;
$function$
