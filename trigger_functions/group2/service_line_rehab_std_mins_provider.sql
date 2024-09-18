CREATE OR REPLACE FUNCTION public.service_line_rehab_std_mins_provider()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$ 
DECLARE 
	rehab_std_mins_provider integer; 
BEGIN -- Check if Type_of_Data is not 'Rehab' 
	IF NEW.Type_of_Data <> 'Rehab' THEN 
		NEW.rehab_std_mins_provider := 0;
	ELSE -- If System_Name is 'Mary Free Bed' 
		IF NEW.System_Name = 'Mary Free Bed' THEN 
			SELECT INTO rehab_std_mins_provider s.rehab_std_mins_provider 
			FROM Standards s 
			WHERE s.System_Name = NEW.System_Name 
			AND s.Type_of_Data = NEW.Type_of_Data 
			AND s.Type_of_Service = NEW.Type_of_Service; 
		ELSE 
			SELECT INTO rehab_std_mins_provider 
			s.rehab_std_mins_provider 
			FROM Standards s 
			WHERE s.Type_of_Data = NEW.Type_of_Data 
			AND s.Type_of_Service = NEW.Type_of_Service; 
		END IF; -- Assign the value to the NEW row

		NEW.rehab_std_mins_provider := rehab_std_mins_provider; 
	END IF; 
	RETURN NEW; 
END; 
$function$
