CREATE OR REPLACE FUNCTION public.service_line_standard_sf_per_room()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN 
    IF NEW.type_of_service = 'Outpatient' AND NEW.type_of_data = 'Rehab' THEN
        NEW.standard_sf_per_room := NEW.rehab_standard_sf_per_room;
    ELSIF NEW.type_of_service = 'Outpatient' OR NEW.type_of_service = 'Treatment' THEN
        NEW.standard_sf_per_room := NEW.outpatient_treatment_standard_sf_per_room;
    ELSIF NEW.type_of_service = 'Inpatient' AND (NEW.type_of_data = 'Lab' OR NEW.type_of_data = 'Pharmacy') THEN 
        NEW.standard_sf_per_room := NEW.lab_pharmacy_standard_sf_per_room;
    ELSIF NEW.type_of_service = 'Inpatient' THEN 
        NEW.standard_sf_per_room := NEW.ip_standard_sf_per_room;
    ELSE 
        NEW.standard_sf_per_room := 0;
    END IF;

    RETURN NEW; 
END;
$function$
