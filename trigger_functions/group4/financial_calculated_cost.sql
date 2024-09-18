CREATE OR REPLACE FUNCTION public.financial_calculated_cost()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$ --match to financial.level_of_construction to project_costs.level_of_construction; pull (project_costs.cost * financial.st)+ff_e
BEGIN 
	NEW.calculated_cost := (NEW.level_of_construction * NEW.sf) + NEW.FF_E; 
	RETURN NEW; 
END; 
$function$
