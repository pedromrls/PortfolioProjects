/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
In Postgresql*/

--Checking all the info in this coviddeaths table

SELECT *
FROM coviddeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;

--Checking all the info in this covidvaccinations table
SELECT *
FROM covidvaccinations
WHERE continent IS NOT NULL
ORDER BY 3,4;

-- Select Data that we are going to be starting with
--Using join clause to pull population from second table
--Limited to 10k

SELECT cd.location, cd.date, total_cases, new_cases, total_deaths, population
FROM coviddeaths AS cd
LEFT OUTER JOIN covidvaccinations AS cv
ON cd.iso_code = cv.iso_code
WHERE cd.continent IS NOT NULL
ORDER BY 1,2
LIMIT 10000;

--Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your country
--I'm from DR but live in USA, gonna do boths

SELECT location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM coviddeaths
WHERE location LIKE '%Dominican%'
AND continent IS NOT NULL
ORDER BY 1,2;

--Total Cases vs Population
--Shows percentage of population got covid
SELECT cd.location, cd.date, total_cases, population, 
	(total_cases/population)*100 AS percent_pop_infected
FROM coviddeaths AS cd
LEFT OUTER JOIN covidvaccinations AS cv
ON cd.iso_code = cv.iso_code
WHERE cd.location LIKE '%Dominican%'
AND cd.continent IS NOT NULL
ORDER BY 1,2;

-- Counntries with the Highest Death Count Per Population
--10K ENTRIES

SELECT cd.location, population, MAX(total_cases) AS highest_inf_count,
MAX((total_cases/population))*100 AS percent_pop_infected
FROM coviddeaths AS cd
LEFT OUTER JOIN covidvaccinations AS cv
ON cd.iso_code = cv.iso_code
WHERE cd.continent IS NOT NULL
GROUP BY cd.location, population
ORDER BY percent_pop_infected DESC NULLS LAST
LIMIT 10000;

-- Countries with Highest Death Count per Population

SELECT location, MAX(cast(total_deaths AS INT)) AS total_death_count
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC NULLS LAST;


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

SELECT location, MAX(cast(total_deaths AS int)) AS total_death_count
FROM coviddeaths
WHERE continent IS NULL AND NOT location= 'World'
GROUP BY location
ORDER BY total_death_count DESC;


-- Global Numbers
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS INT)) AS total_deaths,
	SUM(cast(new_deaths AS INT))/SUM(new_Cases)*100 AS deathpercentage
FROM coviddeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2;

/*
SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS INT)) AS total_deaths,
	SUM(cast(new_deaths AS INT))/SUM(new_Cases)*100 AS deathpercentage
FROM coviddeaths
WHERE continent IS NOT NULL 
GROUP BY date
ORDER BY 1,2;
*/

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved 
-- at least one Covid Vaccine

SELECT dea.continent, dea.location, dea.date, population, 
		vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS INT)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM coviddeaths AS dea
JOIN covidvaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;
	
-- Using CTE to perform Calculation on Partition By in previous query

WITH popvsvax(continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, population, 
		vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS INT)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM coviddeaths AS dea
JOIN covidvaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM popvsvax;

-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM coviddeaths AS dea
JOIN covidvaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

