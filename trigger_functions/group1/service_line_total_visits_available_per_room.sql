CREATE OR REPLACE FUNCTION public.service_line_total_visits_available_per_room()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.total_visits_available_per_room = NEW.target_capacity - NEW.visits_per_room;
    RETURN NEW; 
END;
$function$
