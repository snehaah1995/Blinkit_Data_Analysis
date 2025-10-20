-- Select all data from the 'blinkit_data' table for inspection
SELECT * 
FROM blinkit_data;

-- Cross-check the total row count in the 'blinkit_data' table
SELECT COUNT(*) AS no_of_rows 
FROM blinkit_data;

-- Select all data from the 'blinkit_staging_data' table to inspect
SELECT * 
FROM blinkit_staging_data;

-- Create a staging table 'blinkit_staging_data' with the same structure as 'blinkit_data', but no data yet
SELECT * INTO blinkit_staging_data
FROM blinkit_data
WHERE 1=0;  -- This ensures no data is copied over, just the structure

-- Insert data from 'blinkit_data' into 'blinkit_staging_data'
INSERT INTO blinkit_staging_data
SELECT * FROM blinkit_data;

-- Data Cleaning Section

-- Check the initial 'Item_Fat_Content' values
SELECT *
FROM blinkit_data;

-- Clean up 'Item_Fat_Content' values: replace 'LF', 'low fat' with 'Low Fat' and 'reg' with 'Regular'
UPDATE blinkit_staging_data
SET Item_Fat_Content =
    CASE
        WHEN Item_Fat_Content IN ('LF','low fat') THEN 'Low Fat'
        WHEN Item_Fat_Content = 'reg' THEN 'Regular'
        ELSE Item_Fat_Content
    END;

-- Verify the distinct 'Item_Fat_Content' values after cleaning
SELECT DISTINCT Item_Fat_Content
FROM blinkit_staging_data;

-- Business Requirements Section

-- KPI Calculations

-- Calculate the total sales from the 'blinkit_staging_data' table
SELECT CAST(SUM(Total_Sales) AS DECIMAL(10,2)) AS Total_sales
FROM blinkit_staging_data;

-- Calculate the average revenue per sale (average of 'Total_Sales')
SELECT CAST(AVG(Total_Sales) AS DECIMAL(10,2)) AS Avg_sales
FROM blinkit_staging_data;

-- Get the number of items (rows) in the 'blinkit_staging_data' table
SELECT COUNT(*) AS No_of_items
FROM blinkit_staging_data;

-- Calculate the average ratings for the products
SELECT CAST(AVG(Rating) AS DECIMAL(10,2)) AS avg_ratings
FROM blinkit_staging_data;

-- Create a view 'Item_Fat_Content_KPI' that contains total sales, number of items, and average ratings by 'Item_Fat_Content'
CREATE VIEW Item_Fat_Content_KPI AS
SELECT Item_Fat_Content,
       CAST(SUM(Total_Sales) AS DECIMAL(10,2)) AS Total_Sales,
       COUNT(*) AS Number_of_items,
       CAST(AVG(Rating) AS DECIMAL(10,2)) AS Avg_ratings
FROM blinkit_staging_data
GROUP BY Item_Fat_Content
ORDER BY Total_Sales DESC;

-- Top 5 Item Types based on total sales, number of items, and average ratings
SELECT TOP 5 Item_Type,
       CAST(SUM(Total_Sales) AS DECIMAL(10,2)) AS Total_Sales,
       COUNT(*) AS Number_of_items,
       CAST(AVG(Rating) AS DECIMAL(10,2)) AS Avg_ratings
FROM blinkit_staging_data
GROUP BY Item_Type
ORDER BY Total_Sales DESC;

-- Total sales, number of items, and average ratings by Outlet Location and Item Fat Content
SELECT Outlet_Location_Type, Item_Fat_Content,
       CAST(AVG(Total_Sales) AS DECIMAL(10,2)) AS Avg_Sales,
       COUNT(*) AS Number_of_items,
       CAST(AVG(Rating) AS DECIMAL(10,2)) AS Avg_ratings
FROM blinkit_staging_data
GROUP BY Outlet_Location_Type, Item_Fat_Content
ORDER BY Avg_Sales DESC;

-- Pivoting data for 'Item_Fat_Content' by Outlet Location
SELECT Outlet_Location_Type,
       ISNULL([Low Fat], 0) AS Low_Fat, 
       ISNULL([Regular], 0) AS Regular
FROM 
(
    SELECT Outlet_Location_Type, Item_Fat_Content, 
           CAST(SUM(Total_Sales) AS DECIMAL(10,2)) AS Total_Sales
    FROM blinkit_staging_data
    GROUP BY Outlet_Location_Type, Item_Fat_Content
) AS SourceTable
PIVOT 
(
    SUM(Total_Sales) 
    FOR Item_Fat_Content IN ([Low Fat], [Regular])
) AS PivotTable
ORDER BY Outlet_Location_Type;

-- Use a CTE (Common Table Expression) to handle the pivot
WITH trail_data AS (
    SELECT Outlet_Location_Type, Item_Fat_Content, 
           CAST(SUM(Total_Sales) AS DECIMAL(10,2)) AS Total_Sales
    FROM blinkit_staging_data
    GROUP BY Outlet_Location_Type, Item_Fat_Content
)
SELECT Outlet_Location_Type,
       ISNULL([Low Fat], 0) AS Low_Fat, 
       ISNULL([Regular], 0) AS Regular
FROM trail_data
PIVOT 
(
    SUM(Total_Sales)
    FOR Item_Fat_Content IN ([Low Fat], [Regular])
) AS PivotTable;

-- Group by 'Outlet_Establishment_Year' and calculate total sales
SELECT Outlet_Establishment_Year,
       CAST(SUM(Total_Sales) AS DECIMAL(10,2)) AS Total_sales
FROM blinkit_staging_data
GROUP BY Outlet_Establishment_Year;

-- Group by 'Outlet_Establishment_Year' to calculate total sales, number of items, and average sales
SELECT Outlet_Establishment_Year,
       CAST(SUM(Total_Sales) AS DECIMAL(10,2)) AS Total_sales,
       COUNT(*) AS Number_of_items,
       CAST(AVG(Total_Sales) AS DECIMAL(10,2)) AS Avg_sales
FROM blinkit_staging_data
GROUP BY Outlet_Establishment_Year
ORDER BY Outlet_Establishment_Year ASC;

-- Group by 'Outlet_Size' to calculate total sales and percentage of sales
SELECT Outlet_Size, 
       CAST(SUM(Total_Sales) AS DECIMAL(10,2)) AS Total_Sales,
       ROUND(100.0 * SUM(Total_Sales) / SUM(SUM(Total_Sales)) OVER(), 2) AS Sales_Percentage
FROM blinkit_staging_data
GROUP BY Outlet_Size
ORDER BY Total_Sales DESC;

-- Group by 'Outlet_Location_Type' to calculate total sales
SELECT Outlet_Location_Type, 
       CAST(SUM(Total_Sales) AS DECIMAL(10,2)) AS Total_Sales
FROM blinkit_staging_data
GROUP BY Outlet_Location_Type
ORDER BY Total_Sales DESC;

-- Group by 'Outlet_Type' to calculate total sales, average sales, number of items, and average ratings
SELECT Outlet_Type,
       CAST(SUM(Total_Sales) AS DECIMAL(10,2)) AS Total_sales,
       CAST(AVG(Total_Sales) AS DECIMAL(10,2)) AS Avg_sales,
       COUNT(*) AS No_of_Items,
       CAST(AVG(Rating) AS DECIMAL(10,2)) AS Avg_rating
FROM blinkit_staging_data
GROUP BY Outlet_Type;

-- Group by 'Outlet_Location_Type' to calculate total sales, average sales, number of items, and average ratings
SELECT Outlet_Location_Type,
       CAST(SUM(Total_Sales) AS DECIMAL(10,2)) AS Total_sales,
       CAST(AVG(Total_Sales) AS DECIMAL(10,2)) AS Avg_sales,
       COUNT(*) AS No_of_Items,
       CAST(AVG(Rating) AS DECIMAL(10,2)) AS Avg_rating
FROM blinkit_staging_data
GROUP BY Outlet_Location_Type
ORDER BY Total_sales DESC;
