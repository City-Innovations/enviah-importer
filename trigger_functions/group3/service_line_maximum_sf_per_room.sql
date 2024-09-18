CREATE OR REPLACE FUNCTION public.service_line_maximum_sf_per_room()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
	NEW.maximum_sf_per_room:= NEW.standard_sf_per_room * 1.25;
	RETURN NEW;
END;
$function$
