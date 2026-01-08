CREATE DATABASE Uber_Dataset;

EXEC sp_help 'ncr_ride_bookings';

SELECT *
FROM ncr_ride_bookings

-- Total Rows

SELECT COUNT(*) AS total_rows
FROM ncr_ride_bookings;

SELECT TOP 10 *
FROM ncr_ride_bookings;

--Checking any duplicate found in Booking_id

SELECT Booking_ID,COUNT(*) AS Cnt 
FROM ncr_ride_bookings
GROUP BY Booking_ID
HAVING COUNT(*) > 2

---finding if there still duplicates by taking booking id , date and time as pk

SELECT *
FROM ncr_ride_bookings
WHERE Booking_ID IN (
  SELECT Booking_ID
  FROM ncr_ride_bookings
  GROUP BY Booking_ID
  HAVING COUNT(*) > 2
)
ORDER BY Booking_ID, Date, Time;



SELECT Booking_ID, Date, Time, COUNT(*) AS cnt
FROM ncr_ride_bookings
GROUP BY Booking_ID, Date, Time
HAVING COUNT(*) > 1;



SELECT *
FROM ncr_ride_bookings
WHERE Booking_ID IN (
  SELECT TOP 20 Booking_ID
  FROM ncr_ride_bookings
  GROUP BY Booking_ID
  HAVING COUNT(DISTINCT Pickup_Location) > 1
     OR COUNT(DISTINCT Drop_Location) > 1
     OR COUNT(DISTINCT Vehicle_Type) > 1
     OR COUNT(DISTINCT Booking_Value) > 1
)
ORDER BY Booking_ID, Date, Time;


SELECT
    CONCAT(Booking_ID, '_', Date, '_', Time) AS Ride_Key,
    *
FROM 
    ncr_ride_bookings
ORDER BY 
    Ride_Key;


SELECT *
FROM ncr_ride_bookings
WHERE Avg_VTAT IS NULL
  AND Avg_CTAT IS NULL


SELECT *
FROM ncr_ride_bookings
WHERE Booking_Status = 'Completed'
  AND (Avg_VTAT IS NULL OR Avg_CTAT IS NULL);


---Check for invalid ratings

SELECT *
FROM ncr_ride_bookings
WHERE Driver_Ratings < 1 
   OR Driver_Ratings > 5
   OR Customer_Rating < 1
   OR Customer_Rating > 5;


--Check for invalid distances

SELECT *
FROM ncr_ride_bookings
WHERE Ride_Distance < 0
   OR Ride_Distance > 100;


--Check booking_value inconsistencies

SELECT *
FROM ncr_ride_bookings
WHERE Booking_Status = 'Completed'
  AND Booking_Value = 0;

SELECT *
FROM ncr_ride_bookings
WHERE Booking_Value < 0;

SELECT DISTINCT Booking_Status
FROM ncr_ride_bookings;


select *
from ncr_ride_bookings
where Booking_Status = 'Completed'


--Create booking_datetime and cleaned table

ALTER TABLE ncr_ride_bookings
ADD booking_datetime DATETIME;

UPDATE ncr_ride_bookings
SET booking_datetime = CAST(Date AS DATETIME) + CAST(Time AS DATETIME);

SELECT *
INTO ncr_ride_bookings_clean
FROM ncr_ride_bookings;

--- cleaned ncr_ride_booking table

SELECT * FROM ncr_ride_bookings_clean

ALTER TABLE ncr_ride_bookings_clean
ADD 
    booking_year INT,
    booking_month INT,
    booking_day INT,
    booking_hour INT,
    daypart VARCHAR(20);

---Populate year/month/day/hour

UPDATE ncr_ride_bookings_clean
SET 
    booking_year = YEAR(booking_datetime),
    booking_month = MONTH(booking_datetime),
    booking_day = DAY(booking_datetime),
    booking_hour = DATEPART(HOUR, booking_datetime);

---Populate daypart (Morning/Noon/Evening/Night)


UPDATE ncr_ride_bookings_clean
SET daypart =
    CASE
        WHEN booking_hour BETWEEN 5 AND 11  THEN 'Morning'
        WHEN booking_hour BETWEEN 12 AND 15 THEN 'Noon'
        WHEN booking_hour BETWEEN 16 AND 20 THEN 'Evening'
        ELSE 'Night'
    END;

SELECT DISTINCT booking_year FROM ncr_ride_bookings_clean

ALTER TABLE ncr_ride_bookings_clean
DROP COLUMN booking_year;

--===================================== E D A ==========================================


-- Total Rides

SELECT COUNT(*) AS total_rides
FROM ncr_ride_bookings_clean;

--  Completed Rides

SELECT COUNT(*) AS completed_rides
FROM ncr_ride_bookings_clean
WHERE booking_status = 'Completed';

--Cancellation Count ?((Driver + Customer))

SELECT COUNT(*) AS cancelled_rides
FROM ncr_ride_bookings_clean
WHERE booking_status LIKE '%Cancel%';

--- No Driver Found Count

SELECT COUNT(*) AS no_driver_found
FROM ncr_ride_bookings_clean
WHERE booking_status = 'No Driver Found';

--- incomplete rides 

SELECT COUNT(*) AS incomplete
FROM ncr_ride_bookings_clean               
WHERE Booking_Status = 'incomplete'

---Completion Rate

SELECT (CAST(SUM(CASE WHEN booking_status = 'Completed' THEN 1 END )AS FLOAT)/COUNT(*)) * 100 AS Completion_rate
FROM ncr_ride_bookings_clean

---Average Fare (Booking Value)

SELECT AVG(booking_value) AS avg_fare
FROM ncr_ride_bookings_clean
WHERE booking_value IS NOT NULL;

---Average Driver Rating

SELECT AVG(Driver_Ratings) AS avg_driver_rating
FROM ncr_ride_bookings_clean
WHERE Driver_Ratings IS NOT NULL;

---Average Customer Rating

SELECT AVG(customer_rating) AS avg_customer_rating
FROM ncr_ride_bookings_clean
WHERE customer_rating IS NOT NULL;

--Peak Ride Hour

SELECT booking_hour, COUNT(*) AS ride_count
FROM ncr_ride_bookings_clean
GROUP BY booking_hour
ORDER BY ride_count DESC;


--Ride Status Breakdown (Distribution)

SELECT 
    booking_status,
    COUNT(*) AS ride_count,
    ROUND( COUNT(*) * 100.0 / (SELECT COUNT(*) FROM ncr_ride_bookings_clean), 2 ) AS percentage
FROM ncr_ride_bookings_clean
GROUP BY booking_status
ORDER BY ride_count DESC;

--Dive Deeper Into Driver Cancellations

SELECT 
    Driver_Cancellation_Reason,
    COUNT(*) AS count
FROM ncr_ride_bookings_clean
WHERE booking_status = 'Cancelled by Driver'
GROUP BY Driver_Cancellation_Reason
ORDER BY count DESC;


SELECT 
    booking_hour,
    COUNT(*) AS cancellations
FROM ncr_ride_bookings_clean
WHERE booking_status = 'Cancelled by Driver'
GROUP BY booking_hour
ORDER BY cancellations DESC;


---Customer cancellation reason

SELECT 
    Reason_for_cancelling_by_Customer,
    COUNT(*) AS count
FROM ncr_ride_bookings_clean
WHERE booking_status = 'Cancelled by Customer'
GROUP BY Reason_for_cancelling_by_Customer
ORDER BY count DESC;

---Cancellation Patterns by Time (Customer side)

SELECT 
    booking_hour,
    COUNT(*) AS customer_cancellations
FROM ncr_ride_bookings_clean
WHERE booking_status = 'Cancelled by Customer'
GROUP BY booking_hour
ORDER BY customer_cancellations DESC;

--No Driver Found Analysis

SELECT 
    booking_hour,
    COUNT(*) AS no_driver_found
FROM ncr_ride_bookings_clean
WHERE booking_status = 'No Driver Found'
GROUP BY booking_hour
ORDER BY no_driver_found DESC;

--Location Insights

SELECT 
    Pickup_Location,
    COUNT(*) AS ride_count
FROM ncr_ride_bookings_clean
GROUP BY Pickup_Location
ORDER BY ride_count DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

--Top 10 Drop Locations

SELECT 
    Drop_Location,
    COUNT(*) AS ride_count
FROM ncr_ride_bookings_clean
GROUP BY Drop_Location
ORDER BY ride_count DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

--Vehicle Type Analysis

SELECT 
    Vehicle_Type,
    COUNT(*) AS total_rides
FROM ncr_ride_bookings_clean
GROUP BY Vehicle_Type
ORDER BY total_rides DESC;

-- Which vehicle types have the highest cancellation rates?

SELECT 
    Vehicle_Type,
    COUNT(*) AS cancellations
FROM ncr_ride_bookings_clean
WHERE booking_status LIKE '%Cancel%'
GROUP BY Vehicle_Type
ORDER BY cancellations DESC;

--cancellation rate per vehicle type.

SELECT 
    Vehicle_Type,
    COUNT(*) AS total_rides,
    SUM(CASE WHEN booking_status LIKE '%Cancel%' THEN 1 ELSE 0 END) AS cancellations,
    ROUND(
        SUM(CASE WHEN booking_status LIKE '%Cancel%' THEN 1 ELSE 0 END) * 100.0 
        / COUNT(*), 
    2) AS cancellation_rate_pct
FROM ncr_ride_bookings_clean
GROUP BY Vehicle_Type
ORDER BY cancellation_rate_pct DESC;

--- Ride distance analysis

SELECT 
    Vehicle_Type,
    ROUND(AVG(Ride_Distance), 2) AS avg_distance,
    ROUND(MIN(Ride_Distance), 2) AS min_distance,
    ROUND(MAX(Ride_Distance), 2) AS max_distance
FROM ncr_ride_bookings_clean
WHERE Ride_Distance IS NOT NULL
GROUP BY Vehicle_Type
ORDER BY avg_distance DESC;

--Fare Summary by Vehicle Type

SELECT 
    Vehicle_Type,
    ROUND(AVG(Booking_Value), 2) AS avg_fare,
    ROUND(MIN(Booking_Value), 2) AS min_fare,
    ROUND(MAX(Booking_Value), 2) AS max_fare
FROM ncr_ride_bookings_clean
WHERE Booking_Value > 0
GROUP BY Vehicle_Type
ORDER BY avg_fare DESC;

--fare per km

SELECT 
    Vehicle_Type,
    ROUND(AVG(Booking_Value / NULLIF(Ride_Distance, 0)), 2) AS avg_fare_per_km
FROM ncr_ride_bookings_clean
WHERE Booking_Value > 0 AND Ride_Distance > 0
GROUP BY Vehicle_Type
ORDER BY avg_fare_per_km DESC;

--Revenue Contribution by Vehicle Type

SELECT 
    Vehicle_Type,
    ROUND(SUM(Booking_Value), 2) AS total_revenue,
    ROUND(AVG(Booking_Value), 2) AS avg_revenue_per_ride,
    COUNT(*) AS total_rides
FROM ncr_ride_bookings_clean
WHERE Booking_Value > 0
GROUP BY Vehicle_Type
ORDER BY total_revenue DESC;

--Revenue by Hour of Day

SELECT 
    booking_hour,
    ROUND(SUM(Booking_Value), 2) AS total_revenue,
    COUNT(*) AS total_rides
FROM ncr_ride_bookings_clean
WHERE Booking_Value > 0
GROUP BY booking_hour
ORDER BY total_revenue DESC;

--Payment Method Ride Count

SELECT 
    Payment_Method,
    COUNT(*) AS total_rides
FROM ncr_ride_bookings_clean
WHERE booking_status IN ('Completed', 'Incomplete')
GROUP BY Payment_Method
ORDER BY total_rides DESC;

--- total revenue by payment method

SELECT 
    Payment_Method,
    ROUND(SUM(Booking_Value), 2) AS total_revenue
FROM ncr_ride_bookings_clean
WHERE booking_status IN ('Completed', 'Incomplete')
GROUP BY Payment_Method
ORDER BY total_revenue DESC;


-- Overall VTAT & CTAT Summary

SELECT 
    ROUND(AVG(Avg_VTAT), 2) AS avg_vtat,
    ROUND(AVG(Avg_CTAT), 2) AS avg_ctat,
    ROUND(MIN(Avg_VTAT), 2) AS min_vtat,
    ROUND(MAX(Avg_VTAT), 2) AS max_vtat,
    ROUND(MIN(Avg_CTAT), 2) AS min_ctat,
    ROUND(MAX(Avg_CTAT), 2) AS max_ctat
FROM ncr_ride_bookings_clean
WHERE Avg_VTAT IS NOT NULL AND Avg_CTAT IS NOT NULL;

--VTAT influence on cancellations

SELECT 
    booking_status,
    ROUND(AVG(Avg_VTAT), 2) AS avg_vtat
FROM ncr_ride_bookings_clean
WHERE Avg_VTAT IS NOT NULL
GROUP BY booking_status
ORDER BY avg_vtat DESC;

--Hour-wise VTAT

SELECT 
    booking_hour,
    ROUND(AVG(Avg_VTAT), 2) AS avg_vtat
FROM ncr_ride_bookings_clean
WHERE Avg_VTAT IS NOT NULL
GROUP BY booking_hour
ORDER BY avg_vtat DESC;

-- CTAT by Vehicle Type

SELECT 
    Vehicle_Type,
    ROUND(AVG(Avg_CTAT), 2) AS avg_ctat
FROM ncr_ride_bookings_clean
WHERE Avg_CTAT IS NOT NULL
GROUP BY Vehicle_Type
ORDER BY avg_ctat DESC;

--Driver Ratings by Vehicle Type

SELECT 
    Vehicle_Type,
    ROUND(AVG(Driver_Ratings), 2) AS avg_driver_rating
FROM ncr_ride_bookings_clean
WHERE Driver_Ratings IS NOT NULL
GROUP BY Vehicle_Type
ORDER BY avg_driver_rating DESC;

-- customer rating by vehicle type

SELECT 
    Vehicle_Type,
    ROUND(AVG(Customer_Rating), 2) AS avg_customer_rating
FROM ncr_ride_bookings_clean
WHERE Customer_Rating IS NOT NULL
GROUP BY Vehicle_Type
ORDER BY avg_customer_rating DESC;