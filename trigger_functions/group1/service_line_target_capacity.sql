CREATE OR REPLACE FUNCTION public.service_line_target_capacity()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN 
	IF NEW.type_of_service = 'Inpatient' THEN 
		NEW.target_capacity := NEW.maximum_visits_per_room * NEW.ip_target_occupancy; 
	ELSE 
		NEW.target_capacity := NEW.maximum_visits_per_room * 0.75;
	END IF; 

	RETURN NEW; 
END; 
$function$
