CREATE OR REPLACE FUNCTION public.service_line_actual_sf_per_room()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE 
actual_sf NUMERIC; 
BEGIN 
	BEGIN 
		IF (NEW.type_of_data = 'Lab' OR NEW.type_of_data = 'Pharmacy') AND NEW.type_of_service = 'Inpatient' THEN 
			actual_sf := NEW.support_services_sf / NEW.ip_number_of_licensed_beds; 
		ELSIF NEW.type_of_service = 'Inpatient' THEN 
			actual_sf := NEW.inpatient_sf / NEW.ip_number_of_licensed_beds; 
		ELSIF NEW.type_of_data = 'Rehab' THEN 
			actual_sf := NEW.cd_number_of_providers_or_patient_facing_staff / (NEW.total_sf / 100); 
		ELSIF NEW.type_of_service = 'Outpatient' THEN 
			actual_sf := NEW.outpatient_sf / NEW.cd_number_of_patient_rooms; 
		ELSIF NEW.type_of_service = 'Treatment' THEN 
			actual_sf := NEW.outpatient_sf / NEW.cd_number_of_patient_rooms; 
		ELSE 
			actual_sf := 0; 
	END IF; 
	EXCEPTION 
		WHEN OTHERS THEN 
			actual_sf := NULL; 
	END; 
	NEW.actual_sf_per_room := actual_sf;
	RETURN NEW; 
END;
$function$
