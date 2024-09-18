CREATE OR REPLACE FUNCTION public.service_line_capacity_of_visits_available()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
	NEW.capacity_of_visits_available := NEW.maximum_visits_per_room - NEW.visits_per_room ;
	RETURN NEW;
END; 
$function$
