CREATE OR REPLACE FUNCTION public.service_line_outpatient_treatment_standard_minutes_per_provider()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
	IF NEW.type_of_service IN ('Outpatient', 'Treatment') THEN
		NEW.outpatient_treatment_standard_minutes_per_provider := NEW.cd_hours_for_each_shift * 60 * NEW.cd_days_open_per_week * 50; 
	ELSE 
		NEW.outpatient_treatment_standard_minutes_per_provider := 0; 
	END IF;
	RETURN NEW; 
END;
$function$
