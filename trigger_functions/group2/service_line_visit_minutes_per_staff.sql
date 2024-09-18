CREATE OR REPLACE FUNCTION public.service_line_visit_minutes_per_staff()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
	IF NEW.type_of_service IN ('Outpatient', 'Treatment') THEN 
		IF NEW.cd_length_of_time_a_visit_takes IS NOT NULL AND NEW.cd_turnover_between_patients IS NOT NULL AND NEW.cd_visits_annually IS NOT NULL AND NEW.cd_number_of_providers_or_patient_facing_staff IS NOT NULL AND NEW.cd_number_of_pt_a_provider_sees_at_once IS NOT NULL THEN 
			BEGIN 
				NEW.visit_minutes_per_staff := ((NEW.cd_length_of_time_a_visit_takes + NEW.cd_turnover_between_patients) * NEW.cd_visits_annually) / NEW.cd_number_of_providers_or_patient_facing_staff / NEW.cd_number_of_pt_a_provider_sees_at_once; 
			EXCEPTION 
				WHEN OTHERS THEN 
					NEW.visit_minutes_per_staff := NULL; 
			END; 
		ELSE 
			NEW.visit_minutes_per_staff := 0; 
		END IF; 
	ELSIF NEW.type_of_data = 'Rehab' AND NEW.type_of_service = 'Outpatient' THEN 
		IF NEW.cd_visits_annually IS NOT NULL AND 
			NEW.cd_number_of_providers_or_patient_facing_staff IS NOT NULL THEN 
			NEW.visit_minutes_per_staff := NEW.cd_visits_annually / NEW.cd_number_of_providers_or_patient_facing_staff; 
		ELSE 
			NEW.visit_minutes_per_staff := 0; 
		END IF; 
	ELSE 
		IF NEW.type_of_service IN ('Outpatient', 'Treatment') THEN 
			IF NEW.cd_length_of_time_a_visit_takes IS NOT NULL AND 
				NEW.cd_turnover_between_patients IS NOT NULL AND 
				NEW.cd_visits_annually IS NOT NULL AND 
				NEW.cd_number_of_providers_or_patient_facing_staff IS NOT NULL AND 
				NEW.cd_number_of_pt_a_provider_sees_at_once IS NOT NULL THEN 
				BEGIN 
					NEW.visit_minutes_per_staff := 
						((NEW.cd_length_of_time_a_visit_takes + NEW.cd_turnover_between_patients) * NEW.cd_visits_annually) / NEW.cd_number_of_providers_or_patient_facing_staff / NEW.cd_number_of_pt_a_provider_sees_at_once; 
				EXCEPTION 
					WHEN OTHERS THEN 
						NEW.visit_minutes_per_staff := NULL; 
				END; 
			ELSE 
				NEW.visit_minutes_per_staff := 0; 
			END IF; 
		ELSE 
			NEW.visit_minutes_per_staff := 0; 
		END IF; 
	END IF;
	RETURN NEW; 
END;
$function$
