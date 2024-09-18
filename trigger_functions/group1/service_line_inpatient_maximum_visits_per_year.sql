CREATE OR REPLACE FUNCTION public.service_line_inpatient_maximum_visits_per_year()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN 
IF NEW.type_of_service = 'Inpatient' THEN 
BEGIN 
NEW.inpatient_maximum_visits_per_year:= NEW.ip_maximum_patient_days / NEW.ip_number_of_licensed_beds; 
EXCEPTION WHEN division_by_zero THEN 
NEW.inpatient_maximum_visits_per_year:= NULL; 
END; 
ELSE 
NEW.inpatient_maximum_visits_per_year:= 0; 
END IF;

	RETURN NEW; 
END;
$function$
