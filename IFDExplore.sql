USE IndianFlightData
GO

/*EDA using vw_ValidFlights*/

SELECT * FROM vw_ValidFlights

--Average price by airline

SELECT
	AVG(Price) Average_Price,
	Airline
FROM vw_CleanFlights
GROUP BY Airline
ORDER BY Average_Price DESC

--Average duration by number of stops

SELECT
	AVG(CleanDurationMinutes) Average_Duration_Minutes,
	CleanStops
FROM vw_ValidFlights
GROUP BY CleanStops
ORDER BY Average_Duration_Minutes

--Average price by number of stops

SELECT
	CleanStops,
	AVG(Price) Average_Price,
	AVG(CleanDurationMinutes) Average_Duration_Minutes
FROM vw_ValidFlights
GROUP BY CleanStops
ORDER BY Average_Price

/* As expected, more stops means higher price */

--Priciest sectors

SELECT
	Airline,
	CleanSource,
	CleanDestination,
	Date_of_Journey,
	Price
FROM vw_ValidFlights
WHERE CleanStops = 0
ORDER BY Price DESC

/* Air India's Kolkata-Bangalore flight on 2019-03-24 is the priciest at 31945 */

--Price by date of journey for Air India Kolkata-Bangalore

SELECT
	Airline,
	CleanSource,
	CleanDestination,
	Date_of_Journey,
	Price
FROM vw_ValidFlights
WHERE CleanSource = 'Kolkata' AND
	  CleanDestination = 'Banglore'
ORDER BY Price DESC

--EDA Question 1: How do stops affect price and duration?

SELECT
	CleanStops,
	AVG(Price) Average_Price,
	AVG(CleanDurationMinutes) Average_Duration_Minutes
FROM vw_ValidFlights
GROUP BY CleanStops
ORDER BY Average_Price

/* More stops means higher price and duration */

--EDA Question 2: Which airlines offer the best value for time?

SELECT * FROM vw_ValidFlights

SELECT
	Airline,
	AVG(CleanDurationMinutes) Avg_Duration,
	AVG(Price) Avg_Price,
	ROUND((CAST(AVG(CleanDurationMinutes)AS FLOAT)/AVG(Price)),2) Duration_Price_Ratio
FROM vw_ValidFlights
GROUP BY Airline
ORDER BY Duration_Price_Ratio DESC

/* “This metric measures cost efficiency per minute of travel, not passenger convenience. Airlines with longer average durations and competitive pricing score higher, while premium and business-class airlines score lower due to higher prices.” */
/* "The result isn’t wrong, but the metric favors longer, cheaper flights. It’s best interpreted as cost efficiency per minute, not overall airline quality. I’d refine it further by controlling for stops or fare class." */

--EDA Question 3: What are the busiest routes, and are they cheaper?

SELECT
CleanSource,
CleanDestination,
COUNT(*) Total_Flights,
AVG(Price) Avg_Price
FROM vw_ValidFlights
GROUP BY CleanSource, CleanDestination
ORDER BY Total_Flights DESC

/* The busiest route is Delhi-Cochin, Avg_Price is 10540 */

SELECT
Airline,
CleanSource,
CleanDestination,
COUNT(*) Total_Flights,
AVG(Price) Avg_Price
FROM vw_ValidFlights
WHERE CleanSource = 'Delhi' AND CleanDestination = 'Cochin'
GROUP BY Airline, CleanSource, CleanDestination

/* Jet Airways Business on Delhi-Cochin route is an outlier, need to exclude it from the output */

SELECT
CleanSource,
CleanDestination,
COUNT(*) Total_Flights,
AVG(Price) Avg_Price
FROM vw_ValidFlights
WHERE Airline != 'Jet Airways Business' AND Airline != 'Multiple carriers Premium economy'
GROUP BY CleanSource, CleanDestination
ORDER BY Total_Flights DESC, Avg_Price DESC

/* Delhi-Cochin is still the busiest and priciest sector in this dataset even after excluding outliers. However, this contradicts real-world data and shows a limitation of the database, in that, flights have not been sampled proportionately */ */

--EDA Question 4: Does departure time influence price?

SELECT * FROM vw_ValidFlights

SELECT
CASE
WHEN
	CleanDepTime > '3:00:00' AND CleanDepTime <= '8:00:00'
THEN 'Early Morning'
WHEN	
	CleanDepTime > '8:00:00' AND CleanDepTime <= '12:00:00'
THEN 'Morning'
WHEN
	CleanDepTime > '12:00:00' AND CleanDepTime <= '16:00:00'
THEN 'Afternoon'
WHEN 
	CleanDepTime > '16:00:00' AND CleanDepTime <= '21:00:00'
THEN 'Evening'
ELSE 'Night'
END Time_of_Day,
AVG(Price) Avg_Price
FROM vw_ValidFlights
GROUP BY 
CASE
WHEN
	CleanDepTime > '3:00:00' AND CleanDepTime <= '8:00:00'
THEN 'Early Morning'
WHEN	
	CleanDepTime > '8:00:00' AND CleanDepTime <= '12:00:00'
THEN 'Morning'
WHEN
	CleanDepTime > '12:00:00' AND CleanDepTime <= '16:00:00'
THEN 'Afternoon'
WHEN 
	CleanDepTime > '16:00:00' AND CleanDepTime <= '21:00:00'
THEN 'Evening'
ELSE 'Night'
END
ORDER BY Avg_Price DESC

/* Flights between 9 pm and 3 am are the cheapest, followed by flights between 3 am and 8 am */


--EDA Question 5: Are there airlines that dominate specific routes?

SELECT * FROM vw_CleanFlights

SELECT
CleanSource AS Origin,
CleanDestination AS Destination,
COUNT(*) AS Total_Flights,
Airline
FROM vw_CleanFlights
GROUP BY Airline, CleanSource, CleanDestination
ORDER BY Origin

/* The data seems incomplete as there are more flights on Delhi-Cochin than any other sector. Hence unable to accurately assess airlines dominating specific routes */




