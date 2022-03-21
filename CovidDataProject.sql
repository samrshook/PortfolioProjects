SELECT *
FROM CovidDataProject..CovidDeaths$
order by 3,4


--SELECT * 
--FROM CovidDataProject..CovidVaccinations$
--order by 3,4


-- Select data we are going to use

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDataProject..CovidDeaths$
order by 1, 2


--Looking at Total Cases vs Total Deaths
-- Shows how likely one is to die if they contract Covid in each Country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage 
FROM CovidDataProject..CovidDeaths$
order by 1, 2


--Looking at Total Cases vs Population
-- Shows percentage of population that has gotten Covid

SELECT location, date, total_cases, population, (total_cases/population)*100 AS CasePercentage 
FROM CovidDataProject..CovidDeaths$
order by 1, 2 DESC


-- Show countries with the highest infection rate compared to population

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 AS CasePercentage 
FROM CovidDataProject..CovidDeaths$
group by location, population
order by 4 DESC


-- Show countries with the highest death count and that count compared to population in 'big countries' (more than ten million people)

SELECT location, population, MAX(cast(total_deaths as int)) as DeathCount, MAX((total_deaths/population))*100 AS DeathPercentage 
FROM CovidDataProject..CovidDeaths$
WHERE continent is not null AND population > 10000000
group by location, population
order by 3 DESC

-- Show the highest death count and rate by Continent

SELECT continent, MAX(cast(total_deaths as int)) as DeathCount, Round(MAX((total_deaths/population))*100, 2) AS DeathPercentage 
FROM CovidDataProject..CovidDeaths$
WHERE continent is not null
group by continent
order by DeathCount DESC


-- GLOBAL NUMBERS


-- New cases across the world each day

SELECT date, SUM(new_cases) AS NewCasesWorld
FROM CovidDataProject..CovidDeaths$
WHERE continent is not null
group by date
order by 1 DESC, 2

-- New deaths across the world each day

SELECT date, SUM(cast(new_deaths as int)) AS NewDeathsWorld
FROM CovidDataProject..CovidDeaths$
WHERE continent is not null
group by date
order by 1 DESC, 2

-- Global chance of death if Covid positive

SELECT SUM(total_cases) AS TotalCases, SUM(cast(total_deaths as bigint)) as TotalDeaths, SUM(cast(total_deaths as bigint))/SUM(total_cases)*100 AS DeathPercentage 
FROM CovidDataProject..CovidDeaths$
order by 1, 2


-- Joining our two tables

SELECT * 
From CovidDataProject..CovidDeaths$ dea
JOIN CovidDataProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date


-- Looking at total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From CovidDataProject..CovidDeaths$ dea
JOIN CovidDataProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
order by 2, 3


-- First day of vaccinations for each country

SELECT dea.location, min(dea.date) as FirstVacDate
From CovidDataProject..CovidDeaths$ dea
JOIN CovidDataProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null AND vac.new_vaccinations is not null
group by dea.location
order by 2 ASC


-- Rolling count of Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as CumSumVaccination
From CovidDataProject..CovidDeaths$ dea
JOIN CovidDataProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
order by 2, 3


-- Looking at the number of ICU and Hospital patients as it compars to deaths and vaccinations

SELECT dea.location, dea.date, dea.icu_patients, dea.hosp_patients, dea.total_deaths, 
	SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as CumSumVaccination
FROM CovidDataProject..CovidDeaths$ dea
JOIN CovidDataProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null AND dea.icu_patients is not null AND dea.hosp_patients is not null AND dea.new_deaths is not null AND vac.new_vaccinations is not null
order by dea.location




-- USING CTE
-- Looking at the percentage of the total population vaccinated each day

WITH PopVsVac (continent, location, data, population, new_vaccinations, CumSumVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as CumSumVaccination
From CovidDataProject..CovidDeaths$ dea
JOIN CovidDataProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--order by 2, 3
)
SELECT *, CumSumVaccinated/population *100
FROM PopVsVac


-- USING TEMP TABLE
-- Looking at the percentage of the total population vaccinated each day

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
CumSumVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as CumSumVaccination
From CovidDataProject..CovidDeaths$ dea
JOIN CovidDataProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT *, CumSumVaccinated/population *100 AS PercentPopVac
FROM #PercentPopulationVaccinated
ORDER BY 1, 2, 3 DESC


-- CREATING VIEWS to store data for later viz

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as CumSumVaccination
From CovidDataProject..CovidDeaths$ dea
JOIN CovidDataProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null



CREATE VIEW FirstVaccine as
SELECT dea.location, min(dea.date) as FirstVacDate
From CovidDataProject..CovidDeaths$ dea
JOIN CovidDataProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null AND vac.new_vaccinations is not null
group by dea.location
--order by 2 ASC


CREATE VIEW HospitalPatientsVsDeaths as
SELECT dea.location, dea.date, dea.icu_patients, dea.hosp_patients, dea.total_deaths, 
	SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as CumSumVaccination
FROM CovidDataProject..CovidDeaths$ dea
JOIN CovidDataProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null AND dea.icu_patients is not null AND dea.hosp_patients is not null AND dea.new_deaths is not null AND vac.new_vaccinations is not null
--order by 1