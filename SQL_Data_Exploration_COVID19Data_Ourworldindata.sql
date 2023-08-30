-- Project: Exploring and Analysing OurWorldinData Covid19 dataset

SELECT *
FROM portfolioProject..CovidDeaths
ORDER BY  1,2


SELECT *
FROM portfolioProject..CovidVaccinations
ORDER BY  1,2



-----------------------------------------------------------------------------------------------------
-- Looking at the total cases, total deaths and population

SELECT location, date, total_cases, total_deaths, population
FROM portfolioProject..CovidDeaths
ORDER BY  1,2

-- Creating a view for the above(for later visualization in Tableau)
-- View 1
CREATE VIEW TotalCasesAndDeaths as
SELECT location, date, total_cases, total_deaths, population
FROM portfolioProject..CovidDeaths




----------------------------------------------------------------------------------------------------
-- checking total rows/records in CovidDeaths or CovidVaccinations table(both has same rows/records)
SELECT COUNT(*)
FROM portfolioProject..CovidDeaths



-----------------------------------------------------------------------------------------------------
-- Calculating Death Percentage Global
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM portfolioProject..CovidDeaths
-- the above code section returned DeathPercentages all as 0 bcz both the columns are int. So we have to cast DeathPercentage as decimal or floating number.as shown below


-- saving the view
CREATE VIEW DeathPercentages as
SELECT location, date, total_cases, total_deaths, CAST((total_deaths * 1.0 / total_cases) * 100 AS DECIMAL(10, 2)) AS DeathPercentage
FROM portfolioProject..CovidDeaths
-- Shows likelihood of dying if you contract Covid



-----------------------------------------------------------------------------------------------------
-- Looking at the total cases vs the population
-- shows what percentage of population got Covid
SELECT location, date, population, total_cases, CAST((total_cases * 1.0 / population) * 100 AS DECIMAL(10, 2)) AS ContractedPercentage
FROM portfolioProject..CovidDeaths
ORDER BY  location, date


-- which country has the highest CovidContraction rate

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX(CAST((total_cases * 1.0 / population) * 100 AS DECIMAL(10, 2))) AS ContractedPercentage
FROM portfolioProject..CovidDeaths
GROUP By location, population
ORDER BY ContractedPercentage desc



-- showing countries with highest death count per population

SELECT location, population, MAX(total_deaths) as HighestDeathCount, MAX(CAST((total_deaths * 1.0 / population) * 100 AS DECIMAL(10, 2))) AS DeathsPerPopulation
FROM portfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP By location, population
ORDER BY DeathsPerPopulation desc

-- we have things like "world", "North America" etc in the Location section
-- utilize continent column
-- we can add a where clause, WHERE Continent is NOT NULL


-- LET'S LOOK AT CONTINENTS
-- the following will mess up in the drill down. North America only showed United states in it
SELECT continent, location, MAX(total_deaths) as HighestDeathCount
FROM portfolioProject..CovidDeaths
WHERE continent IS NOT NULL --AND location = 'Canada'
GROUP By continent, location
ORDER BY HighestDeathCount desc


-- looking at the continents only now North America shows accurate values
SELECT location, MAX(total_deaths) as HighestDeathCount
FROM portfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP By location
ORDER BY HighestDeathCount desc 


-- Global Numbers and save the view
CREATE VIEW GlobalNumbers as
SELECT SUM(new_cases) as totalcases, SUM(cast(new_deaths as int)) as totaldeaths, SUM(CAST(new_deaths as bigint))/(sum(new_cases)+0.00001)*100 as DeathPercentage
From portfolioProject..CovidDeaths
where continent is not null



------------------------------------


-- Looking at total population vs Vaccination

SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY death.location order by death.location, death.date) as RollingPeopleVaccinated
FROM portfolioProject..CovidDeaths death
Join portfolioProject..CovidVaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
where death.continent is not null AND death.location = 'Pakistan'
order by 1,2,3



------------------------------------------

-- we want to use RollingPeopleVaccinated and divide it by population. Can't do bcz we just created that column so we
-- USE CTEs or Temp Tables


With PopVsVac (Continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY death.location order by death.location, death.date) as RollingPeopleVaccinated
FROM portfolioProject..CovidDeaths death
Join portfolioProject..CovidVaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
where death.continent is not null AND death.location = 'Pakistan'
-- order by 2,3 This cannot be in here to work
)
SELECT *,  (RollingPeopleVaccinated/population)*100
FROM PopVsVac


-----------------------------------------------------------------------
-- TEMP TABLES
DROP TABLE IF EXISTS #PercentPopulationVaccinated -- VERY USEFUL IF YOU HAVE ALREADY CREATED AND WANT TO MAKE CHANGES
CREATE	Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY death.location order by death.location, death.date) as RollingPeopleVaccinated
FROM portfolioProject..CovidDeaths death
Join portfolioProject..CovidVaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
where death.continent is not null
-- order by 2,3 This cannot be in here to work

SELECT *,  (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated


------------------------------------------------------------------
--CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS

CREATE VIEW PercentPopulationVaccinated AS
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY death.location order by death.location, death.date) as RollingPeopleVaccinated
FROM portfolioProject..CovidDeaths death
Join portfolioProject..CovidVaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
where death.continent is not null

SELECT *
FROM PercentPopulationVaccinated
