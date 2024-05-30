SELECT * 
FROM CovidProject..CovidDeaths
ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidProject..CovidDeaths
ORDER BY 1, 2


-- Total Cases vs Deaths. Chance of Dying in your country

SELECT location, continent, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage
FROM CovidProject..CovidDeaths
ORDER BY 1, 2

-- Total Cases vs Pop
SELECT location, date, population, total_cases,(total_cases/population)*100 AS Percent_With_Covid
FROM CovidProject..CovidDeaths
ORDER BY 1, 2

-- Infection Rate by Country
SELECT continent, location, population, MAX(total_cases) AS Highest_Infection_Count, MAX((total_cases/population))*100 AS Percent_Pop_With_Covid
FROM CovidProject..CovidDeaths
GROUP BY continent, location, population
ORDER BY Percent_Pop_With_Covid DESC

-- Showing countries with highest death count per pop
SELECT continent, location, Max(cast(total_deaths AS int)) AS Total_Death_Count
FROM CovidProject..CovidDeaths
WHERE continent is not null
GROUP BY continent, location
ORDER BY Total_Death_Count DESC

-- Death Count By Continent (Changing continent to location fixes things) Also make it is null

SELECT continent, Max(cast(total_deaths AS int)) AS Total_Death_Count
FROM CovidProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY Total_Death_Count DESC

-- Global Numbers

SELECT date, SUM(new_cases) AS Total_Cases, Sum(CAST(new_deaths AS INT)) AS Total_Deaths, SUM(CAST(New_deaths AS INT))/SUM(New_Cases)*100 AS Death_Percentage
FROM CovidProject..CovidDeaths
WHERE continent is not null
GROUP BY DATE
ORDER BY 1, 2

SELECT SUM(new_cases) AS Total_Cases, Sum(CAST(new_deaths AS INT)) AS Total_Deaths, SUM(CAST(New_deaths AS INT))/SUM(New_Cases)*100 AS Death_Percentage
FROM CovidProject..CovidDeaths
WHERE continent is not null
ORDER BY 1, 2

 -- Total Pop vs Vac per day
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS int)) OVER (Partition by dea.Location ORDER BY dea.location, dea.date) AS Rolling_Count_Vaccinated
FROM CovidProject..CovidDeaths Dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location= vac.location
	AND dea.date = vac.date
	WHERE dea.continent is not null
ORDER BY 2,3

-- Using CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, Rolling_Count_Vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS int)) OVER (Partition by dea.Location ORDER BY dea.location, dea.date) AS Rolling_Count_Vaccinated
FROM CovidProject..CovidDeaths Dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location= vac.location
	AND dea.date = vac.date
	WHERE dea.continent is not null
)
SELECT *, (Rolling_Count_Vaccinated/population) * 100 AS Percent_Vac 
FROM PopvsVac

-- Max Percent Vaccinated

WITH PopvsVac (continent, location, population, new_vaccinations, Rolling_Count_Vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS int)) OVER (Partition by dea.Location ORDER BY dea.location, dea.date) AS Rolling_Count_Vaccinated
FROM CovidProject..CovidDeaths Dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location= vac.location
	AND dea.date = vac.date
	WHERE dea.continent is not null
)
SELECT *, (Rolling_Count_Vaccinated/population) * 100 AS Percent_Vac 
FROM PopvsVac

-- Temp Table

DROP TABLE if Exists #PercentPopVaccinated
CREATE TABLE #PercentPopVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
Rolling_Count_Vaccinated numeric
)

INSERT INTO #PercentPopVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS int)) OVER (Partition by dea.Location ORDER BY dea.location, dea.date) AS Rolling_Count_Vaccinated
FROM CovidProject..CovidDeaths Dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location= vac.location
	AND dea.date = vac.date
	WHERE dea.continent is not null

SELECT *, (Rolling_Count_Vaccinated/population) * 100 AS Percent_Vac 
FROM #PercentPopVaccinated


-- Create View to Store Data Visualizations
Create View PercentPopVac AS 
SELECT dea.continent, dea.location, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS int)) OVER (Partition by dea.Location ORDER BY dea.location, dea.date) AS Rolling_Count_Vaccinated
FROM CovidProject..CovidDeaths Dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location= vac.location
	AND dea.date = vac.date
	WHERE dea.continent is not null

SELECT * 
FROM PercentPopVac
