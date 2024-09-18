CREATE OR REPLACE FUNCTION public.service_line_available_number_of_rooms()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE 
    available_number_of_rooms numeric;
    sf_value numeric;
    standard_sf_per_room_value numeric;
BEGIN 
    -- Get the values, defaulting to NULL if not provided
    sf_value := NEW.sf;
    standard_sf_per_room_value := NEW.standard_sf_per_room;

    -- Check if both values are not NULL before performing the division
    IF sf_value IS NOT NULL AND standard_sf_per_room_value IS NOT NULL AND standard_sf_per_room_value != 0 THEN
        available_number_of_rooms := sf_value / standard_sf_per_room_value;
    ELSE
        available_number_of_rooms := NULL;
    END IF;

    -- Set the calculated value in the NEW row
    NEW.available_number_of_rooms := available_number_of_rooms;

    -- Always return NEW to allow the insert/update to proceed
    RETURN NEW;
END;$function$
