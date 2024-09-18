CREATE OR REPLACE FUNCTION public.combined_financial_trigger()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- 1. financial_calculated_cost
    NEW.calculated_cost := (NEW.level_of_construction * NEW.sf) + NEW.FF_E;

    -- 2. financial_capital_investment
    IF NEW.imported_cost > 0 THEN 
        NEW.capital_investment := NEW.imported_cost; 
    ELSE 
        NEW.capital_investment := NEW.calculated_cost; 
    END IF;

    RETURN NEW;
END;
$$;