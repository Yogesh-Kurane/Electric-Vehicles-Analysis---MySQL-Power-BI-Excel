SELECT * FROM electric_vehicles_db.dim_date;

-- Establishing data modelling relationship between all 3 tables after inserting the data in the tables:- 

-- Adding foreign key in ___by_makers table:-
ALTER TABLE electric_vehicle_sales_by_makers 
ADD CONSTRAINT fk_makers_date 
FOREIGN KEY (date) REFERENCES dim_date(date);

-- Adding foreign key in ___by_state table:-
ALTER TABLE electric_vehicle_sales_by_state 
ADD CONSTRAINT fk_state_date 
FOREIGN KEY (date) REFERENCES dim_date(date);

-- Checking duplicates:-
SELECT DISTINCT vehicle_category 
FROM electric_vehicle_sales_by_state 
WHERE vehicle_category NOT IN (SELECT DISTINCT vehicle_category FROM electric_vehicle_sales_by_makers);

-- Then checking for inconsistent data types or if datatypes are not same:- 
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH 
FROM information_schema.columns 
WHERE table_name IN ('electric_vehicle_sales_by_makers', 'electric_vehicle_sales_by_state') 
AND COLUMN_NAME = 'vehicle_category';

-- Checking index:-
SHOW INDEX FROM electric_vehicle_sales_by_makers WHERE Column_name = 'vehicle_category';

-- Referencing both date, vehicle_category as foreign_key:-
ALTER TABLE electric_vehicle_sales_by_state 
ADD CONSTRAINT fk_state_category 
FOREIGN KEY (date, vehicle_category) 
REFERENCES electric_vehicle_sales_by_makers(date, vehicle_category);

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Answering the primary and secondary questions for meeting the company's requirements:-
-- Preliminary Research Questions:-

-- --> 1.List the top 3 and bottom 3 makers for the fiscal years 2023 and 2024 in terms of the number of 2-wheelers sold.
-- Top 3:-
SELECT vehicle_category, maker, SUM(electric_vehicles_sold) AS electric_vehicles_sale
FROM electric_vehicle_sales_by_makers m
JOIN dim_date d
USING (date)
WHERE fiscal_year IN  ("2023","2024") AND vehicle_category = "2-wheelers"
GROUP BY vehicle_category, maker
ORDER BY electric_vehicles_sale DESC
LIMIT 3;
-- Bottom 3:-
SELECT * FROM 
(SELECT vehicle_category, maker, SUM(electric_vehicles_sold) AS electric_vehicles_sale
FROM electric_vehicle_sales_by_makers m
JOIN dim_date d
USING (date)
WHERE fiscal_year IN  ("2023","2024") AND vehicle_category = "2-wheelers"
GROUP BY vehicle_category, maker
ORDER BY electric_vehicles_sale ASC
LIMIT 3) AS bottom_tab
ORDER BY electric_vehicles_sale DESC; -- --> To get the values in "DESC" we used SELECT query.

SELECT SUM(electric_vehicles_sold) 
FROM electric_vehicle_sales_by_makers
WHERE maker = "JITENDRA";


-- When to use HAVING clause:-
SELECT vehicle_category, maker, SUM(electric_vehicles_sold) AS electric_vehicles_sale
FROM electric_vehicle_sales_by_makers m
JOIN dim_date d
USING (date)
WHERE fiscal_year IN ("2023","2024")
GROUP BY vehicle_category, maker
HAVING vehicle_category = "2-wheelers"
ORDER BY electric_vehicles_sale DESC
LIMIT 3;
-- Use HAVING when you need to filter data on the aggregations used in the SELECT clause like SUM, COUNT, MAX etc to used again to filer.

-- --> 2.Identify the top 5 states with the highest penetration rate in 2-wheeler and 4-wheeler EV sales in FY 2024.
-- (Penetration Rate: This metric represents the percentage of total vehicles that are electric within a specific region or category. It is calculated as:
-- Penetration Rate =  (Electric Vehicles Sold / Total Vehicles Sold) * 100  
-- This indicates the adoption level of electric vehicles.)

-- For 2-Wheelers:-
SELECT vehicle_category, state, 
       ROUND(SUM(electric_vehicles_sold) / SUM(total_vehicles_sold) * 100,2) AS penetration_rate 
FROM electric_vehicle_sales_by_state
JOIN dim_date
USING (date)
WHERE fiscal_year = (2024) AND vehicle_category IN ("2-Wheelers")
GROUP BY vehicle_category, state
ORDER BY penetration_rate DESC
LIMIT 5;
-- For 4-Wheelers:-
SELECT vehicle_category, state, 
       ROUND(SUM(electric_vehicles_sold) / SUM(total_vehicles_sold) * 100,2) AS penetration_rate 
FROM electric_vehicle_sales_by_state
JOIN dim_date
USING (date)
WHERE fiscal_year = "2024" AND vehicle_category = "4-Wheelers"
GROUP BY vehicle_category, state
ORDER BY penetration_rate DESC
LIMIT 5;

-- --> 3.List the states with negative penetration (decline) in EV sales from 2022 to 2024

WITH CTE1 AS
(SELECT state, ROUND(SUM(electric_vehicles_sold) / SUM(total_vehicles_sold) * 100,2) 
               AS penetn_rate_2022 
FROM electric_vehicle_sales_by_state
JOIN dim_date 
USING (date)
WHERE fiscal_year IN (2022) AND vehicle_category = ("4-Wheelers") -- For 2-wheelers use ("2-Wheelers") 
GROUP BY state),
CTE2 AS
(SELECT state, ROUND(SUM(electric_vehicles_sold) / SUM(total_vehicles_sold) * 100,2) 
			   AS penetn_rate_2024 
FROM electric_vehicle_sales_by_state
JOIN dim_date 
USING (date)
WHERE fiscal_year IN (2024) AND vehicle_category = ("4-Wheelers") -- Then 2-wheelers use ("2-Wheelers") 
GROUP BY state) -- Final query -- >
SELECT state AS State, (penetn_rate_2024 - penetn_rate_2022) AS Decline_in_Rate 
FROM CTE1
JOIN CTE2
USING (state)
GROUP BY state
HAVING Decline_in_rate < 0;

-- --> 4.What are the quarterly trends based on sales volume for the top 5 EV makers (4-wheelers) from 2022 to 2024?
WITH rank_makers AS
(SELECT fiscal_year, quarter, maker, SUM(electric_vehicles_sold) AS total_EV_sales, 
		DENSE_RANK() OVER (PARTITION BY fiscal_year, quarter ORDER BY SUM(electric_vehicles_sold) DESC) AS ranking
FROM electric_vehicle_sales_by_makers
JOIN dim_date 
USING (date)
WHERE fiscal_year IN (2022,2023,2024) AND vehicle_category = "4-Wheelers"
GROUP BY fiscal_year, quarter, maker)   -- Final Query next line
SELECT quarter, maker, SUM(total_EV_sales) AS EV_Sales
FROM rank_makers
WHERE ranking <= 5
GROUP BY quarter, maker
ORDER BY quarter, ranking, EV_sales DESC;

-- --> 5.How do the EV sales and penetration rates in Delhi compare to Karnataka for 2024?
-- Karnataka & Delhi (EV Sales)
SELECT state, SUM(electric_vehicles_sold) AS EV_sales
FROM electric_vehicle_sales_by_state
JOIN dim_date
USING (date)
WHERE fiscal_year IN (2024) AND vehicle_category IN ("2-Wheelers", "4-Wheelers") 
AND state IN ("Karnataka","Delhi")
GROUP BY state 
ORDER BY EV_sales DESC; 

-- Karnataka & Delhi (Penetration Rate)
SELECT state, SUM(electric_vehicles_sold) / NULLIF(SUM(total_vehicles_sold),0) * 100 AS penetration_rate
FROM electric_vehicle_sales_by_state
JOIN dim_date
USING (date)
WHERE fiscal_year = "2024" AND vehicle_category IN ("2-wheelers","4-Wheelers") 
AND state IN ("Karnataka","Delhi")
GROUP BY state 
ORDER BY penetration_rate DESC; 

-- --> 6.List down the compounded annual growth rate (CAGR) in 4-wheeler units for the top 5 makers from 2022 to 2024.
-- Compound Annual Growth Rate (CAGR): CAGR measures the mean annual growth rate over a specified period longer than one year. It is calculated as:
-- CAGR = [(Ending Value / Beginning Value) ** 1/n] -1      =====> CAGR = POWER((Ending Value / Beginning Value) TOTHEPOWER(,) 1.0/n) - 1)

SELECT maker, ROUND((POWER(
						   SUM(CASE WHEN fiscal_year = 2024 THEN electric_vehicles_sold ELSE NULL END) /
						   SUM(CASE WHEN fiscal_year = 2022 THEN electric_vehicles_sold ELSE NULL END),
								1.0 / 2) - 1)
							,2) * 100 AS CAGR_percent
FROM electric_vehicle_sales_by_makers
JOIN dim_date
USING (date)
WHERE fiscal_year IN ("2022","2023","2024") AND vehicle_category = "4-Wheelers"
GROUP BY maker
ORDER BY CAGR_percent DESC
LIMIT 5;

SELECT state, ROUND((POWER(
                                  SUM(CASE WHEN fiscal_year = 2024 THEN electric_vehicles_sold ELSE NULL END) /
								  SUM(CASE WHEN fiscal_year = 2022 THEN electric_vehicles_sold ELSE NULL END),
                                     1.0 / 2) - 1 )
                                     ,2) AS CAGR_percent
FROM electric_vehicle_sales_by_state
JOIN dim_date
USING (date)
WHERE fiscal_year IN ("2022","2023","2024") 
GROUP BY state
ORDER BY CAGR_percent DESC
LIMIT 5;

-- --> 7.List down the top 10 states that had the highest compounded annual growth rate (CAGR) from 2022 to 2024 in total vehicles sold.
SELECT state, ROUND((POWER(
			         SUM(CASE WHEN fiscal_year = 2024 THEN total_vehicles_sold ELSE NULL END) /
					 SUM(CASE WHEN fiscal_year = 2022 THEN total_vehicles_sold ELSE NULL END),
						1.0 / 2) - 1) 
					 ,2) * 100 AS CAGR_percent
FROM electric_vehicle_sales_by_state
JOIN dim_date
USING (date)
WHERE fiscal_year IN ("2022","2023","2024") 
GROUP BY state
ORDER BY CAGR_percent DESC;

-- --> 8.What are the peak and low season months for EV sales based on the data from 2022 to 2024?
-- Peak Season Month:-
(SELECT MONTHNAME(date) AS months, SUM(electric_vehicles_sold) AS total_EV_sales
FROM electric_vehicle_sales_by_makers
JOIN dim_date
USING (date)
WHERE fiscal_year IN (2022,2023,2024)
GROUP BY months
ORDER BY total_EV_sales DESC
LIMIT 3)  
UNION ALL  -- > To join and show peak and low season month                                        
-- Low Season Month:-
(SELECT MONTHNAME(date) AS months, SUM(electric_vehicles_sold) AS total_EV_sales
FROM electric_vehicle_sales_by_makers
JOIN dim_date
USING (date)
WHERE fiscal_year IN (2022,2023,2024)
GROUP BY months
ORDER BY total_EV_sales ASC
LIMIT 3); 

-- --> 9.What is the projected number of EV sales for the top 10 states by penetration rate in 2030, based on (CAGR) from previous years?
WITH top_10_states AS    -- STEP - 1 >> Calculate penetration rate for Top 10 states:-
(SELECT state, (SUM(electric_vehicles_sold) / SUM(total_vehicles_sold) * 100) AS penetration_rate 
FROM electric_vehicle_sales_by_state
JOIN dim_date 
USING (date)
WHERE fiscal_year IN (2022,2023,2024) AND vehicle_category IN ("2-Wheelers","4-Wheelers")
GROUP BY state
ORDER BY penetration_rate DESC 
LIMIT 10),
   cagr_table AS      -- STEP - 2 >> Calculate CAGR from 2022 to 2024:-
  (SELECT state, SUM(CASE WHEN fiscal_year = 2024 THEN electric_vehicles_sold ELSE NULL END) AS sales_2024,
				 SUM(CASE WHEN fiscal_year = 2022 THEN electric_vehicles_sold ELSE NULL END) AS sales_2022,
				(POWER(    
					SUM(CASE WHEN fiscal_year = 2024 THEN electric_vehicles_sold ELSE NULL END) /
					SUM(CASE WHEN fiscal_year = 2022 THEN electric_vehicles_sold ELSE NULL END),
				1.0 / 2) - 1
				) AS CAGR									
FROM electric_vehicle_sales_by_state
JOIN dim_date USING (date)
WHERE fiscal_year IN ("2022","2023","2024") AND vehicle_category IN ("2-Wheelers","4-Wheelers")
GROUP BY state)      -- Final Query -- >
SELECT c.state,            
                 ROUND(penetration_rate,2) AS penetration_rate, 
				 ROUND(sales_2024 * POWER(1 + CAGR, 6)) AS projected_sales
FROM cagr_table c
JOIN top_10_states t 
ON c.state = t.state
ORDER BY projected_sales DESC;

-- 9th Query with changes:-
WITH top_10_states AS    -- STEP - 1 >> Calculate penetration rate for Top 10 states:-
(SELECT state, (SUM(electric_vehicles_sold) / SUM(total_vehicles_sold) * 100) AS penetration_rate 
FROM electric_vehicle_sales_by_state
JOIN dim_date 
USING (date)
WHERE fiscal_year IN (2022,2023,2024) AND vehicle_category IN ("2-Wheelers","4-Wheelers")
GROUP BY state
ORDER BY penetration_rate DESC 
LIMIT 10),
cagr_table AS            -- STEP - 2 >> Calculate CAGR from 2022 to 2024:- 
  (SELECT state, SUM(CASE WHEN fiscal_year = 2024 THEN electric_vehicles_sold ELSE NULL END) AS sales_2024,
				 SUM(CASE WHEN fiscal_year = 2022 THEN electric_vehicles_sold ELSE NULL END) AS sales_2022,
		  (POWER(SUM(CASE WHEN fiscal_year = 2024 THEN electric_vehicles_sold ELSE NULL END) /
				 SUM(CASE WHEN fiscal_year = 2022 THEN electric_vehicles_sold ELSE NULL END), 1.0 / 2) - 1) AS CAGR									
FROM electric_vehicle_sales_by_state
JOIN dim_date 
USING (date)
WHERE fiscal_year IN ("2022","2023","2024") AND vehicle_category IN ("2-Wheelers","4-Wheelers")
GROUP BY state)     -- Final query next line            
SELECT c.state,
			  ROUND(penetration_rate,2) AS penetration_rate, 
			  ROUND(sales_2024 * POWER(1 + CAGR,6)) AS projected_sales
FROM cagr_table c
JOIN top_10_states t 
ON c.state = t.state
ORDER BY projected_sales DESC;


-- To convert the values into Millions and Thousands:-
SELECT state, penetration_rate, cagr_percent, 
    CONCAT(ROUND(sales_for_2024 / 1000.0,1), ' K') AS current_sales_2024,
    projected_sales_2030,
    CONCAT(ROUND(projected_sales_2030 / 1000000.0, 1), ' M') AS projected_sales_for_2030   
FROM projected_sales;


-- --> 10.Estimate the revenue growth rate of 4-wheeler and 2-wheelers EVs in India for 2022 vs 2024 and 2023 vs 2024, assuming an average unit price. H
-- vehicle_category = two-wheeler, average price = 85,000
-- vehicle_category = four-wheeler, average price = 15,00,000

WITH sales_data AS   -- CTE-1
(SELECT 
        fiscal_year, 
        vehicle_category,  
        SUM(electric_vehicles_sold) AS total_sales
FROM electric_vehicle_sales_by_state
JOIN dim_date 
USING (date)
WHERE fiscal_year IN (2022, 2023, 2024) 
AND vehicle_category IN ("2-Wheelers","4-Wheelers")
GROUP BY fiscal_year, vehicle_category ),
revenue_data AS    -- CTE-2
(SELECT fiscal_year, vehicle_category, total_sales, 
       CASE   
       WHEN vehicle_category = "2-Wheelers" THEN total_sales * 85000
       WHEN vehicle_category = "4-Wheelers" THEN total_sales * 1500000
       END AS revenue 
FROM sales_data )      -- > Final query next line.
SELECT r1.vehicle_category,   
       r1.fiscal_year AS year_1,
       r2.fiscal_year AS year_2,
       r1.revenue AS revenue_year_1,
       r2.revenue AS revenue_year_2,
       ROUND((r2.revenue / r1.revenue - 1) * 100, 2) AS revenue_growth_rate
FROM revenue_data r1
JOIN revenue_data r2 
ON r1.vehicle_category = r2.vehicle_category 
AND r1.fiscal_year IN (2022, 2023)  -- Now includes both 2022 & 2023 as base years
AND r2.fiscal_year = 2024           -- Always comparing to 2024
ORDER BY r1.vehicle_category, r1.fiscal_year;

-- Without revenue_year_1 and 2:-
WITH sales_data AS   -- CTE-1
(SELECT 
        fiscal_year, 
        vehicle_category,  
        SUM(electric_vehicles_sold) AS total_sales
FROM electric_vehicle_sales_by_state
JOIN dim_date 
USING (date)
WHERE fiscal_year IN (2022, 2023, 2024) 
AND vehicle_category IN ("2-Wheelers","4-Wheelers")
GROUP BY fiscal_year, vehicle_category ),
revenue_data AS    -- CTE-2
(SELECT fiscal_year, vehicle_category, total_sales, 
       CASE   
       WHEN vehicle_category = "2-Wheelers" THEN total_sales * 85000
       WHEN vehicle_category = "4-Wheelers" THEN total_sales * 1500000
       END AS revenue 
FROM sales_data )      -- > Final query next line.
SELECT r1.vehicle_category,   
       r1.fiscal_year AS year_1,
       r2.fiscal_year AS year_2,
       ROUND((r2.revenue / r1.revenue - 1) * 100, 2) AS revenue_growth_rate
FROM revenue_data r1
JOIN revenue_data r2 
ON r1.vehicle_category = r2.vehicle_category 
AND r1.fiscal_year IN (2022, 2023)  -- Now includes both 2022 & 2023 as base years
AND r2.fiscal_year = 2024           -- Always comparing to 2024
ORDER BY r1.vehicle_category, r1.fiscal_year;




-- Note
-- Why fiscal_year + 1 in the AND clause?
-- The condition r1.fiscal_year + 1 = r2.fiscal_year is used to compare consecutive years (e.g., 2022 vs 2023, 2023 vs 2024) in a self-join.

-- How It Works
-- The query retrieves two rows for each vehicle category, one for the previous year (r1) and one for the current year (r2). The fiscal_year + 1 - 
-- condition ensures that:
-- 2022 (r1) is matched with 2023 (r2)
-- 2023 (r1) is matched with 2024 (r2)
-- This allows us to calculate the year-over-year revenue growth.

-- Extra Queries:-
-- Top 5 EV Makers By Sales - 4 -Wheelers
SELECT maker, SUM(electric_vehicles_sold) AS EV_Sales
FROM electric_vehicle_sales_by_makers
JOIN dim_date
ON (fiscal_year)
WHERE fiscal_year IN (2022,2023,2024) AND vehicle_category IN ("4-Wheelers")
GROUP BY maker
ORDER BY EV_Sales DESC
LIMIT 5;
-- Top 5 EV Makers By Sales - 2 -Wheelers
SELECT maker, SUM(electric_vehicles_sold) AS EV_Sales
FROM electric_vehicle_sales_by_makers
JOIN dim_date
ON (fiscal_year)
WHERE fiscal_year IN (2022,2023,2024) AND vehicle_category IN ("2-Wheelers")
GROUP BY maker
ORDER BY EV_Sales DESC
LIMIT 5;