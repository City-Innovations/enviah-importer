CREATE OR REPLACE FUNCTION public.service_line_total_visit_capacity_given_rooms()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN 
	IF NEW.type_of_service = 'Outpatient' OR NEW.type_of_service = 'Treatment' THEN 
		BEGIN 
			NEW.total_visit_capacity_given_rooms := NEW.target_capacity * NEW.cd_number_of_patient_rooms; 
		EXCEPTION WHEN division_by_zero THEN 
			NEW.total_visit_capacity_given_rooms := NULL; 
		END; 
	ELSIF NEW.type_of_service = 'Inpatient' THEN 
		BEGIN 
			NEW.total_visit_capacity_given_rooms := NEW.target_capacity * NEW.ip_number_of_licensed_beds; 
		EXCEPTION WHEN division_by_zero THEN 
			NEW.total_visit_capacity_given_rooms := NULL; 
		END;
	ELSE
		NEW.total_visit_capacity_given_rooms := NULL;

	END IF; 

	RETURN NEW; 
END;
$function$
