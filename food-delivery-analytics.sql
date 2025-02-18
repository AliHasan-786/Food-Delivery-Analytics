-- Table Creation
CREATE DATABASE IF NOT EXISTS FoodDeliveryDB;
USE FoodDeliveryDB;
DROP TABLE IF EXISTS Deliveries;
DROP TABLE IF EXISTS Delivery_persons;

CREATE TABLE IF NOT EXISTS Deliveries (
    ID VARCHAR(255) PRIMARY KEY,
    Delivery_person_ID VARCHAR(255),
    Delivery_person_Age INT,
    Delivery_person_Ratings DECIMAL(3,2),
    Restaurant_latitude DECIMAL(10,6),
    Restaurant_longitude DECIMAL(10,6),
    Delivery_location_latitude DECIMAL(10,6),
    Delivery_location_longitude DECIMAL(10,6),
    Order_Date DATE,
    Time_Orderd TIME,
    Time_Order_picked TIME,
    Weatherconditions VARCHAR(50),
    Road_traffic_density VARCHAR(50),
    Vehicle_condition INT,
    Type_of_order VARCHAR(50),
    Type_of_vehicle VARCHAR(50),
    multiple_deliveries INT,
    Festival VARCHAR(10),
    City VARCHAR(50),
    Time_taken_min INT
);

-- Indexing for Faster Queries
CREATE INDEX idx_order_date ON Deliveries (Order_Date);
CREATE INDEX idx_city ON Deliveries (City);
CREATE INDEX idx_traffic ON Deliveries (Road_traffic_density);

-- Delivery Performance by City Type (using CTE for cleaner structure)
WITH CityDeliveryStats AS (
    SELECT City, COUNT(*) AS Total_Deliveries, AVG(Time_taken_min) AS Avg_Delivery_Time
    FROM Deliveries
    GROUP BY City
)
SELECT * FROM CityDeliveryStats ORDER BY Avg_Delivery_Time DESC;

-- Recursive Query: Identifying Peak Delivery Hours
WITH RECURSIVE PeakHours AS (
    SELECT HOUR(Time_Orderd) AS Hour, COUNT(*) AS Order_Count
    FROM Deliveries
    GROUP BY Hour
    UNION ALL
    SELECT Hour + 1, Order_Count
    FROM PeakHours WHERE Hour < 23
)
SELECT * FROM PeakHours ORDER BY Order_Count DESC LIMIT 10;

-- Window Function: Ranking Delivery Personnel by Efficiency
SELECT 
    Delivery_person_ID,
    COUNT(*) AS Total_Deliveries,
    AVG(Delivery_person_Ratings) AS Avg_Rating,
    AVG(Time_taken_min) AS Avg_Delivery_Time,
    RANK() OVER (ORDER BY AVG(Time_taken_min) ASC) AS Efficiency_Rank
FROM Deliveries
GROUP BY Delivery_person_ID
HAVING COUNT(*) > 50;

-- Traffic Impact Analysis Using CASE Statements
SELECT 
    Road_traffic_density,
    AVG(Time_taken_min) AS Avg_Time_Taken,
    COUNT(*) AS Total_Orders,
    CASE 
        WHEN AVG(Time_taken_min) > 30 THEN 'Severe Delay'
        WHEN AVG(Time_taken_min) BETWEEN 20 AND 30 THEN 'Moderate Delay'
        ELSE 'Minor Delay'
    END AS Traffic_Impact_Category
FROM Deliveries
GROUP BY Road_traffic_density
ORDER BY Avg_Time_Taken DESC;

-- Recursive CTE for Cumulative Festival Impact on Delivery Times
WITH RECURSIVE FestivalImpact AS (
    SELECT Festival, AVG(Time_taken_min) AS Avg_Time_Taken, COUNT(*) AS Total_Orders
    FROM Deliveries
    GROUP BY Festival
    UNION ALL
    SELECT Festival, Avg_Time_Taken + 5, Total_Orders
    FROM FestivalImpact WHERE Avg_Time_Taken < 50
)
SELECT * FROM FestivalImpact;

-- Weather Impact on Delivery Times using GROUPING SETS
SELECT Weatherconditions, AVG(Time_taken_min) AS Avg_Delivery_Time, COUNT(*) AS Total_Orders
FROM Deliveries
GROUP BY Weatherconditions WITH ROLLUP;

-- Correlation Between Vehicle Condition and Delivery Speed Using Window Functions
SELECT Vehicle_condition, 
       AVG(Time_taken_min) AS Avg_Delivery_Time,
       COUNT(*) AS Total_Orders,
       PERCENT_RANK() OVER (ORDER BY AVG(Time_taken_min) ASC) AS Speed_Percentile
FROM Deliveries
GROUP BY Vehicle_condition
ORDER BY Vehicle_condition ASC;

-- Identifying the Most Efficient Order Types Using NTILE
SELECT Type_of_order, 
       AVG(Time_taken_min) AS Avg_Delivery_Time,
       COUNT(*) AS Total_Orders,
       NTILE(4) OVER (ORDER BY AVG(Time_taken_min) ASC) AS Efficiency_Quartile
FROM Deliveries
GROUP BY Type_of_order;

-- Optimize Query Performance
ANALYZE TABLE Deliveries;
OPTIMIZE TABLE Deliveries;