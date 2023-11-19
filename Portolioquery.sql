-- Finding Driver ID 1, Hamilton, 20 Vettel, 30 Schumacher, 102 Senna, 117 Prost, 830 Verstappen

select *
from f1..drivers
where surname = 'Hamilton' or surname like 'Verst%' or surname like'Schu%' or surname = 'Senna' or surname ='Vettel' or surname = 'Prost'


-- Creating a Temp Table


create table #temp_top6 (
driverID int,
driverRef varchar(50),
constructorID int,
raceID int,
grid int,
position int,
positionText varchar(50),
positionOrder int,
points int,
laps int,
statusId int,
year int, 
round int,
circuitID int,
date date)

insert into #temp_top6
select results.driverId, drivers.driverRef, results.constructorId, results.raceID, results.grid, results.position, results.positionText, results.positionOrder, results.points,
results.laps, results.statusId, races.year, races.round, races.circuitId, races.date
from f1..races
JOIN f1..results
	ON races.raceId = results.raceId
JOIN f1..drivers
	on drivers.driverID=results.driverID
WHERE results.driverId = 1 or results.driverId =830 or results.driverId =102 or results.driverId =30 or results.driverId =20 or results.driverId =117

select *
from #temp_top6


-- Show wins,win% and other stats from just GP


WITH CTE_perc as(
select driverRef, 
CONVERT(float,COUNT(raceID)) as races, 
CONVERT(float,COUNT(CASE WHEN position = 1 THEN 1 END)) as wins, 
CONVERT(float,COUNT(CASE WHEN position <=3 then 1 END)) as podiums, 
CONVERT(float,COUNT(CASE WHEN position is null then 1 END)) as retirements,
CONVERT(float,COUNT(CASE WHEN position > 3 then 1 END)) as ousidepodium,
CONVERT(float,COUNT(CASE WHEN position <> 1 then 1 WHEN position is null then 1 END)) as notwins,
CONVERT(float,COUNT(CASE WHEN points = 0 then 1 END)) as outsidepoints,
CONVERT(float,COUNT(CASE WHEN points > 0 then 1 END)) as scoredpoints
from #temp_top6
group by driverRef
)
select races, wins, ROUND(wins/races*100,2) as winpercentage, podiums , ROUND(podiums/races*100,2) as podiumperc, retirements, ROUND(retirements/races*100,2) as retirepercentage, ousidepodium, notwins, scoredpoints, outsidepoints
from CTE_perc


-- count points from gp

select sum(results.points) as points, results.driverID, year, drivers.driverRef
from f1..drivers
FULL JOIN f1..results ON drivers.driverId =results.driverId
FULL JOIN f1..races ON races.raceId=results.raceID
group by results.driverID, races.year, driverRef
order by year desc, sum(results.points) desc



select year, SUM(CASE WHEN results.position = 1 THEN results.points END) as maxpoints
from f1..races
FULL JOIN f1..results ON races.raceId=results.raceID
group by races.year
order by races.year desc

select *
from f1..sprint_results

-- Show stats from GPs+Sprint

WITH CTE_perc as(
select  drivers.driverRef,
drivers.forename,
drivers.surname,
SUM(results.points) as points,
CONVERT(float,COUNT(results.raceID)) as races, 
CONVERT(float,COUNT(CASE WHEN results.position = 1 THEN 1 END)) as wins, 
CONVERT(float,COUNT(CASE WHEN results.position <=3 then 1 END)) as podiums, 
CONVERT(float,COUNT(CASE WHEN results.position is null then 1 END)) as retirements,
CONVERT(float,COUNT(CASE WHEN results.position > 3 then 1 END)) as ousidepodium,
CONVERT(float,COUNT(CASE WHEN results.position <> 1 then 1 WHEN results.position is null then 1 END)) as notwins,
CONVERT(float,COUNT(CASE WHEN results.points = 0 then 1 END)) as outsidepoints,
CONVERT(float,COUNT(CASE WHEN results.points > 0 then 1 END)) as scoredpoints
from f1..results
JOIN f1..drivers on results.driverId = drivers.driverID
where drivers.driverId = 1 or drivers.driverId = 20 or drivers.driverId = 30 or drivers.driverId = 102 or drivers.driverId = 117 or drivers.driverId = 830
GROUP by drivers.driverRef, drivers.forename, drivers.surname
)
select forename,surname,races,points, wins, ROUND(wins/races,4) as winpercentage, podiums , ROUND(podiums/races,4) as podiumperc, retirements, ROUND(retirements/races,4) as retirepercentage, ousidepodium, notwins, scoredpoints, outsidepoints
from CTE_perc
order by winpercentage desc
	
WITH CTE_SPperc as(
select drivers.driverRef,
SUM(sprint_results.points) as SPpoints,
CONVERT(float,COUNT(sprint_results.raceID)) as SPraces,
CONVERT(float,COUNT(CASE WHEN sprint_results.position = 1 THEN 1 END)) as SPwins,
CONVERT(float,COUNT(CASE WHEN sprint_results.position <=3 then 1 END)) as SPpodiums, 
CONVERT(float,COUNT(CASE WHEN sprint_results.position is null then 1 END)) as SPretirements,
CONVERT(float,COUNT(CASE WHEN sprint_results.position > 3 then 1 END)) as SPousidepodium,
CONVERT(float,COUNT(CASE WHEN sprint_results.position <> 1 then 1 WHEN sprint_results.position is null then 1 END)) as SPnotwins,
CONVERT(float,COUNT(CASE WHEN sprint_results.points = 0 then 1 END)) as SPoutsidepoints,
CONVERT(float,COUNT(CASE WHEN sprint_results.points > 0 then 1 END)) as SPscoredpoints
from f1..sprint_results
JOIN f1..drivers on sprint_results.driverId = drivers.driverID
where drivers.driverId = 1 or drivers.driverId = 20 or drivers.driverId = 30 or drivers.driverId = 102 or drivers.driverId = 117 or drivers.driverId = 830
GROUP by drivers.driverRef
)
select driverRef, SPraces, SPpoints,SPwins, ROUND(SPwins/SPraces,2) as SPwinpercentage, SPpodiums , ROUND(SPpodiums/SPraces,2) as SPpodiumperc, SPretirements, ROUND(SPretirements/SPraces,2) as SPretirepercentage, SPousidepodium, SPnotwins, SPscoredpoints, SPoutsidepoints
from CTE_SPperc


-- create a view for each race


CREATE VIEW Racesby6 AS 
select drivers.forename as FirstName, drivers.surname as LastName, drivers.number as DriverNumber, constructors.name as Constructor, races.year as Year, races.round as Round, races.name as TrackName, races.date as Date, results.positionText as Position, results.points as Points, results.grid as StartingGrid, results.laps as Laps, status.status as Status
from f1..results
JOIN f1..drivers
	ON results.driverId = drivers.driverId
JOIN f1..constructors
	ON results.constructorId = constructors.constructorId
JOIN f1..races
	ON results.raceId = races.raceId
JOIN f1..status
	on results.statusId = status.statusId
where results.driverId = 1 or results.driverId =830 or results.driverId =102 or results.driverId =30 or results.driverId =20 or results.driverId =117

select *
from f1..Racesby6
where Position='1'
