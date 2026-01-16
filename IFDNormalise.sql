/* Indian Flight Data */
USE IndianFlightData
GO

/*Freeze raw data by renaming table as Raw_Flights*/


SELECT * FROM Raw_Flights
SELECT COUNT(*) FROM Raw_Flights


sp_help Raw_Flights /*Get schema*/

/* Airlines, locations, stops -> separate tables. Route, duration-> do not store directly */
/* Design the normalised schema; create dimension tables */

CREATE TABLE Airlines (
AirlineID INT IDENTITY PRIMARY KEY,				/* Identity keyword auto-assigns primary key and increments for each record */
AirlineName NVARCHAR(100) UNIQUE NOT NULL);

CREATE TABLE Locations (
LocationID INT IDENTITY PRIMARY KEY,
CityName NVARCHAR(100) UNIQUE NOT NULL);

CREATE TABLE Stops (
StopsID INT IDENTITY PRIMARY KEY,
NumberOfStops INT NOT NULL CHECK(NumberOfStops>=0));



--Load airlines

INSERT INTO Airlines(AirlineName)
SELECT DISTINCT Airline
FROM Raw_Flights;

--Load locations

INSERT INTO Locations(CityName)
SELECT DISTINCT Source FROM Raw_Flights
UNION
SELECT DISTINCT Destination FROM Raw_Flights;

--Normalise stops

INSERT INTO Stops(NumberOfStops)
SELECT DISTINCT
CASE
	WHEN Total_Stops = 'non-stop'
	THEN 0
	WHEN Total_Stops IS NULL THEN 0
	ELSE CAST(LEFT(Total_Stops,1) AS INT)
END
FROM Raw_Flights;

-- Create the fact table

CREATE TABLE Flights (
FlightID INT IDENTITY PRIMARY KEY,
AirlineID INT NOT NULL,
SourceID INT NOT NULL,
DestinationID INT NOT NULL,
JourneyDate DATE NOT NULL,
DepartureTime TIME NOT NULL,
ArrivalTime TIME NOT NULL,
StopsID INT NOT NULL,
DurationMinutes INT NOT NULL,
Price INT NOT NULL,

FOREIGN KEY (AirlineID) REFERENCES Airlines(AirlineID),
FOREIGN KEY (SourceID) REFERENCES Locations(LocationID),
FOREIGN KEY (DestinationID) REFERENCES Locations(LocationID),
FOREIGN KEY (StopsID) REFERENCES Stops(StopsID)
);

--Identify records in which departure time and arrival time are not valid

SELECT COUNT(*) FROM Raw_Flights
WHERE TRY_CAST(Dep_Time AS TIME) IS NULL OR TRY_CAST(Arrival_Time AS TIME) IS NULL

SELECT * FROM Raw_Flights
WHERE TRY_CAST(Dep_Time AS TIME) IS NULL OR TRY_CAST(Arrival_Time AS TIME) IS NULL


-- Create view Clean_Flights (Modified code to handle anomaly of both New Delhi and Delhi being present)

GO

CREATE OR ALTER VIEW vw_CleanFlights AS
SELECT
rf.*,

--Standardised Source

CASE
	WHEN rf.Source IN ('Delhi', 'New Delhi') THEN 'Delhi'
	ELSE rf.Source
END AS CleanSource,

--Standardised Destination

CASE
	WHEN rf.Destination IN ('Delhi', 'New Delhi') THEN 'Delhi'
	ELSE rf.Destination
END AS CleanDestination,

--Clean departure time
TRY_CAST(LEFT(rf.Dep_Time, 5) AS TIME) AS CleanDepTime,

--Clean arrival time
TRY_CAST(LEFT(rf.Arrival_Time, 5) AS TIME) AS CleanArrivalTime,

--Clean duration

CASE
	WHEN rf.Duration LIKE '%h %m%' THEN
		CAST(LEFT(rf.Duration, CHARINDEX('h',rf.Duration)-1) AS INT)*60+
		CAST(
				SUBSTRING(
					rf.Duration,
					CHARINDEX(' ', rf.Duration) + 1,
					CHARINDEX('m', rf.Duration) - CHARINDEX(' ',rf.Duration)-1
				) AS INT
			)
	WHEN rf.Duration LIKE '%h' THEN
		CAST(LEFT(rf.Duration, CHARINDEX('h',rf.Duration)-1) AS INT) * 60
	WHEN rf.Duration LIKE '%m' THEN
		CAST(LEFT(rf.Duration, CHARINDEX('m',rf.Duration)-1) AS INT)
	END AS CleanDurationMinutes,

--Clean stops

CASE
	WHEN Total_Stops = 'non-stop' THEN 0
	WHEN Total_Stops LIKE '% stop%' THEN LEFT(Total_Stops, 1)
	ELSE NULL
END AS CleanStops

FROM Raw_Flights rf;

GO

SELECT * FROM vw_CleanFlights

--Validation queries

SELECT
	COUNT(*) AS TotalRows,
	SUM(CASE WHEN CleanDepTime IS NULL THEN 1 ELSE 0 END) AS BadDepTime,
	SUM(CASE WHEN CleanArrivalTime IS NULL THEN 1 ELSE 0 END) AS BadArrivalTime,
	SUM(CASE WHEN CleanDurationMinutes IS NULL THEN 1 ELSE 0 END) AS BadDuration
FROM vw_CleanFlights;

--Inspect edge cases

SELECT 
	Duration,
	CleanDurationMinutes
FROM vw_CleanFlights
WHERE CleanDurationMinutes IS NULL;

SELECT
	*
FROM vw_CleanFlights
WHERE CleanStops IS NULL;

--Create valid flights view as we have at least one invalid entry (Route=NULL,Total_Stops=NULL,CleanStops=NULL)

GO
CREATE OR ALTER VIEW vw_ValidFlights AS
SELECT * 
FROM vw_CleanFlights
WHERE 
Route IS NOT NULL AND
CleanDepTime IS NOT NULL AND
CleanArrivalTime IS NOT NULL AND
CleanDurationMinutes IS NOT NULL AND
CleanSource IS NOT NULL AND
CleanDestination IS NOT NULL AND
CleanStops IS NOT NULL;
GO

--Validation queries for vw_ValidFlights

SELECT
	COUNT(*) AS TotalRows,
	SUM(CASE WHEN CleanDepTime IS NULL THEN 1 ELSE 0 END) AS BadDepTime,
	SUM(CASE WHEN CleanArrivalTime IS NULL THEN 1 ELSE 0 END) AS BadArrivalTime,
	SUM(CASE WHEN CleanDurationMinutes IS NULL THEN 1 ELSE 0 END) AS BadDuration,
	SUM(CASE WHEN Route IS NULL THEN 1 ELSE 0 END) AS BadRoute,
	SUM(CASE WHEN CleanStops IS NULL THEN 1 ELSE 0 END) AS BadStops
FROM vw_ValidFlights;


--Load data into fact table Flights 
--(note that our fact table contains AirlineID, SourceID, DestinationID, and StopsID in place of airline names and location names) 
--Only clean DepartureTime, ArrivalTime, and DurationMinutes are used.

sp_help Flights

INSERT INTO Flights (AirlineID, SourceID, DestinationID, JourneyDate, DepartureTime, ArrivalTime, StopsID, DurationMinutes, Price)
SELECT
	a.AirlineID,
	s.LocationID,
	d.LocationID,
	vf.Date_of_Journey,
	vf.CleanDepTime,
	vf.CleanArrivalTime,
	st.StopsID,
	vf.CleanDurationMinutes,
	vf.Price
FROM vw_ValidFlights vf
INNER JOIN Airlines a ON vf.Airline = a.AirlineName
INNER JOIN Locations s ON vf.CleanSource = s.CityName
INNER JOIN Locations d ON vf.CleanDestination = d.CityName
INNER JOIN Stops st ON vf.CleanStops = st.NumberOfStops

SELECT * FROM Flights

















