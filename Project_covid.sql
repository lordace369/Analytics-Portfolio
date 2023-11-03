-- simple querying
select * 
from newcovid
-- where continent <> ''
order by 4;


select location, date, total_cases, new_cases, total_deaths, population 
from newcovid
order by 1 , 2;


-- -- 1-total cases vs total death 

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from newcovid
where location like '%india'
order by 1 , 2;

-- -- 2- total cases vs population in India

select location, date, total_cases, total_deaths, population, (total_cases/population)*100 as percent_pop_infected
from newcovid
where location like '%india'
order by 1 , 2;

-- -- 3- viewing the maximum infection rate of the countries compared to population

select location, population, MAX(total_cases) as highest_infection_count, MAX(total_cases/population)*100 as percent_pop_infected
from newcovid
group by location,population
order by percent_pop_infected desc;

-- -- 4-Showing countries with highest death count per population
-- (changes)-Casting the total_deaths column to int with the keyword SIGNED because it is currently of the text type
select location, population,max(cast(total_deaths as signed)) as total_death_count, 
max(total_deaths/population) as percent_pop_dead
from newcovid
where continent is not null
group by location, population
order by total_death_count desc;

-- Removing the continents from the list and including only the countries
select * 
from newcovid
where continent is not null;

-- (changes)the empty values are saved as '' instead of null so 
	-- let's replace those values with null in the continent field
update  newcovid 
set continent = null
where continent='';

-- 5-  Showing continents with highest death count per population
select continent,
max(cast(total_deaths as signed)) as total_death_count
from newcovid
where continent  is not null
group by continent
order by total_death_count desc;

-- (different way) Showing continents with highest death count per population
	-- because where the continents is null , the location is the continent itself
select location,
max(cast(total_deaths as signed)) as total_death_count
from newcovid
where continent  is null
group by location	
order by total_death_count desc;

-- 6- Looking at the global numbers datewise
select date ,sum(new_cases),
sum(cast(new_deaths as signed)) as death_sum,
(sum(cast(new_deaths as signed))/sum(new_cases))*100 as death_percent
from newcovid
where continent is not null
group by date
order by 1,2;

-- 7- Looking at the global numbers without date
select sum(new_cases),
sum(cast(new_deaths as signed)) as death_sum,
(sum(cast(new_deaths as signed))/sum(new_cases))*100 as death_percent
from newcovid
where continent is not null;
-- order by 1,2

-- 8- looking at the vaccination dataframe now
select * 
from new_schema.newcovid as d
join new_schema.newvac as v 
	on d.location=v.location and d.date=v.date ;
    
    
-- DESCRIBE newvac;

-- (changes) Changing the datatype of the date column in the covid_deaths(newcovid) table
	-- keyword= MODIFY COLUMN
ALTER TABLE newcovid
MODIFY COLUMN date DATE;
-- this wont work on the vaccination(newvac) table because the date is in a different format 'dd/mm/yy'


-- (changes) Changing the datatype of the date column in the vaccinations(newvac) table
	-- keyword - set date= str_to_date(column,present_format)
UPDATE newvac
SET date= STR_TO_DATE(date, '%d/%m/%y');

-- 9-Looking at the vaccination dataframe now and joining with the deaths tablle
select d.continent,d.location,d.date,d.population,v.new_vaccinations
from new_schema.newcovid as d
join new_schema.newvac as v 
	on d.location=v.location and d.date=v.date 
where d.continent is not null
order by 2,3;

-- 10- Taking the rolling count of the new_vaccinations to find the total number of vaccinations as of that Date
select d.continent,d.location,d.date,d.population,v.new_vaccinations,
sum(cast(v.new_vaccinations as signed)) over(partition by d.location order by d.location,d.date) as rolling_vacc
from new_schema.newcovid as d
join new_schema.newvac as v 
	on d.location=v.location and d.date=v.date 
where d.continent is not null
order by 2,3;



-- 12- Finding the percentage of vaccinated population using the above table as CTE
-- 12- a CTE
with CTE (continent,location,date,population,new_vaccinations,rolling_vacc)
as
(select d.continent,d.location,d.date,d.population,v.new_vaccinations,
sum(cast(v.new_vaccinations as signed)) over(partition by d.location order by d.location,d.date) as rolling_vacc
from new_schema.newcovid as d
join new_schema.newvac as v 
	on d.location=v.location and d.date=v.date 
where d.continent is not null
order by 2,3
)

select *,
rolling_vacc/population*100 as pctVaccinated
from CTE;

-- 12- b doing the same thing without CTE
select d.continent,d.location,d.date,d.population,v.new_vaccinations,
sum(cast(v.new_vaccinations as signed)) over(partition by d.location order by d.location,d.date)
	as rolling_vacc,
(sum(cast(v.new_vaccinations as signed)) over(partition by d.location order by d.location,d.date) )/d.population*100
	as pctPopVacc
from new_schema.newcovid as d
join new_schema.newvac as v 
	on d.location=v.location and d.date=v.date 
where d.continent is not null 
order by 2,3;



-- 12 - c Temp Table
drop table if exists tempCovid;
create temporary table tempCovid (
continent nvarchar(225),
location nvarchar(225),
date date,
population numeric,
newVacc float,
rolling_vacc float


);
insert into tempCovid 
select 
d.continent,
d.location,
d.date,
d.population,
v.new_vaccinations,
sum(cast(v.new_vaccinations as float)) over(partition by d.location order by d.location,d.date)
	as rolling_vacc
from new_schema.newcovid as d
join new_schema.newvac as v 
	on d.location=v.location and d.date=v.date 
where d.continent is not null 
order by 2,3;

	-- now this temp table is created till the session ends and can be used without the create table query
	-- whereas a CTE only persists within the scope of the query. it will not be available to use for another query 
select *,
rolling_vacc/population*100 as percent_vacc
 from tempCovid;
 

 -- 13 - View
	--  A view retrieves and displays data from the underlying tables based on a query.
    -- useful for security purposes to hide the query or column from the client or any other user.
	-- It does not store data but it has to be manually deleted.
	-- DROP VIEW My_View

-- (Query to be used for view) Total death count by continents
select continent,
max(cast(total_deaths as signed)) as total_death_count
from newcovid
where continent  is not null
group by continent
order by total_death_count desc;

-- Creating a view of the above query
DROP VIEW IF EXISTS view_Continent_total ; -- optional
create view view_Continent_total as
select location,
max(cast(total_deaths as signed)) as total_death_count
from newcovid
where continent  is null
group by location
order by total_death_count desc;

-- All the three CTE, Temp Table and View can be selected and used normally with their name
select * from view_continent_total
where location like '%americ%'


-- This is the end of my EDA of Covid Project with SQL.