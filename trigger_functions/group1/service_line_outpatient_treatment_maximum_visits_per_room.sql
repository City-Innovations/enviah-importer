CREATE OR REPLACE FUNCTION public.service_line_outpatient_treatment_maximum_visits_per_room()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
	IF NEW.type_of_service = 'Outpatient' OR NEW.type_of_service = 'Treatment' THEN 
		BEGIN 
			IF (NEW.cd_length_of_time_a_visit_takes + NEW.cd_turnover_between_patients) = 0 THEN 
				NEW.outpatient_treatment_maximum_visits_per_room := NULL; 
			ELSE 
				NEW.outpatient_treatment_maximum_visits_per_room := NEW.standard_minutes_available_for_clinic / (NEW.cd_length_of_time_a_visit_takes + NEW.cd_turnover_between_patients);
			END IF; 
		EXCEPTION WHEN division_by_zero THEN 
			NEW.outpatient_treatment_maximum_visits_per_room := NULL;
		END; 
	ELSE 
		NEW.outpatient_treatment_maximum_visits_per_room := 0; 
	END IF;
	RETURN NEW; 
END;
$function$
