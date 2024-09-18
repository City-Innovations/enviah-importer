CREATE OR REPLACE FUNCTION public.service_line_percent_capacity()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
	IF NEW.type_of_service = 'Inpatient' THEN 
		NEW.percent_capacity := NEW.ip_percent_occupancy;
	ELSE
		IF NEW.maximum_visits_per_room = 0 THEN 
			NEW.percent_capacity := NULL;
		ELSE
			NEW.percent_capacity := NEW.visits_per_room / NEW.maximum_visits_per_room;
		END IF;
	END IF; 
	RETURN NEW;
END;
$function$
