CREATE OR REPLACE FUNCTION public.service_line_target_minutes()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
	BEGIN
		-- if the system is mary free bed and space_name is "op therapy"
		-- then it's just the standard_minutes
		NEW.target_minutes := NEW.standard_minutes * 0.75;
	RETURN NEW; 
END;
$function$
