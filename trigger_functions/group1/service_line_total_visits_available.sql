CREATE OR REPLACE FUNCTION public.service_line_total_visits_available()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
	IF NEW.percent_capacity IS NULL OR NEW.percent_capacity = NULL THEN 
		NEW.total_visits_available := NULL; 
	ELSE 
		IF NEW.type_of_service = 'Inpatient' THEN 
			NEW.total_visits_available := NEW.ip_available_pt_days_at_occupancy_rate; 
		ELSE 
			NEW.total_visits_available := NEW.total_visit_capacity_given_rooms - NEW.cd_visits_annually;
		END IF;
END IF;

	RETURN NEW; 
END;
$function$
