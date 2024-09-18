CREATE OR REPLACE FUNCTION public.financial_capital_investment()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$ 
BEGIN 
	IF NEW.imported_cost > 0 THEN 
		NEW.capital_investment := NEW.imported_cost; 
	ELSE 
		NEW.capital_investment := NEW.calculated_cost; 
	END IF; 
	RETURN NEW; 
END; 
$function$
