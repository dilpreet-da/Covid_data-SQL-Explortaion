SELECT*
FROM PortfolioProject..Coviddeaths
ORDER BY 3,4

SELECT*
FROM PortfolioProject..CovidVaccinations
ORDER BY 3,4
SELECT location,date,total_cases,new_cases,total_deaths,population
FROM PortfolioProject..Coviddeaths
ORDER BY 1,2

--LOOKING AT TOTAL CASES VS TOTAL DEATHS
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS float) / CAST(total_cases AS float)) as DeathPercentage
FROM PortfolioProject..Coviddeaths
--WHERE LOCATION LIKE '%STATES%'
WHERE continent IS NOT NULL
ORDER BY 1, 2;

-- LOOKING AT TOTAL CASES VS POPULATION
--SHOWS WHAT % GOT COVID

SELECT location, date, total_cases, population, (CAST(total_cases AS float) / (population)*100) as CovidPercentage
FROM PortfolioProject..Coviddeaths
WHERE LOCATION LIKE '%INDIA%'
ORDER BY 1, 2;

--LOOKING AT COUNTRIES WITH HIGHEST INFECTION RATE COMPARED TO POPULATION
SELECT location,population,MAX(total_cases)as HIGHEST_INFECTION_COUNT,MAX(CAST(total_cases AS INT) / (population)) as Covid_Infected_Percentage
FROM PortfolioProject..Coviddeaths
GROUP BY LOCATION, POPULATION
ORDER BY Covid_Infected_Percentage DESC;

--SHOWING COUNTRIES WITH HIGHEST DEATH COUNT PER POPULATION
SELECT location,MAX(CAST(total_deaths as float))as Total_Death_Count
FROM PortfolioProject..Coviddeaths
WHERE continent IS NOT NULL
GROUP BY LOCATION
ORDER BY Total_Death_Count DESC;

--LETS BREAK THINGS DOWN BY CONTINENT

--SHOWING CONTINENTS WITH THE HIGHEST DEATH COUNT PER POPULATION 
SELECT continent,MAX(CAST(total_deaths as float))as Total_Death_Count
FROM PortfolioProject..Coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Total_Death_Count DESC;

--GLOBAL NUMBERS
--To handle the divide-by-zero error and avoid the warning, 
--you can use the NULLIF function to handle the situation when the denominator (SUM(new_cases)) is zero. 
--NULLIF returns NULL if the two specified expressions are equal; otherwise, it returns the first expression. By using NULLIF, you can replace the division by zero with NULL.In this updated query, I've added a CASE statement to check if the sum of new cases is zero. If it is zero, the DeathPercentage column will be set to NULL. Otherwise, the division operation will proceed as before.

SELECT date, SUM(new_cases)as total_cases, SUM(CAST(new_deaths AS int))as total_deaths, 
CASE WHEN SUM(new_cases) = 0 THEN NULL
ELSE SUM(CAST(new_deaths AS int)) / SUM(new_cases)
END AS DeathPercentage
FROM PortfolioProject..Coviddeaths
-- WHERE LOCATION LIKE '%STATES%'
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2;

-- when date is removed from Select and Group by
SELECT SUM(new_cases)as total_cases, SUM(CAST(new_deaths AS int))as total_deaths, 
CASE WHEN SUM(new_cases) = 0 THEN NULL
ELSE SUM(CAST(new_deaths AS int)) / SUM(new_cases)
END AS DeathPercentage
FROM PortfolioProject..Coviddeaths
-- WHERE LOCATION LIKE '%STATES%'
WHERE continent IS NOT NULL
ORDER BY 1, 2;

--LOOKING AT TOTAL POPULATION VS VACCINATION
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as bigint)) Over(Partition by dea.location ORDER BY dea.location, dea.date)as RollingPeopleVaccinated
--(RollingPeopleVaccinated/Population)*100
FROM PortfolioProject..Coviddeaths  dea
  Join PortfolioProject..Covidvaccinations vac
  ON dea.location = vac.Location
  and dea.date = vac.date
  WHERE dea.continent is not null
  ORDER BY 2,3

  --USE a subquery or a common table expression (CTE) to calculate the rolling sum of new vaccinations and then reference that result to calculate the percentage.
  WITH POPvsVAC (continent,location,date,population,new_vaccinations,RollingPeopleVaccinated)
  as
  (
  SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as bigint)) Over(Partition by dea.location ORDER BY dea.location, dea.date)as RollingPeopleVaccinated
--(RollingPeopleVaccinated/Population)*100
  FROM PortfolioProject..Coviddeaths  dea
  Join PortfolioProject..Covidvaccinations vac
  ON dea.location = vac.Location
  and dea.date = vac.date
  WHERE dea.continent is not null
  --ORDER BY 2,3
)
 SELECT*,(RollingPeopleVaccinated/Population)*100
  FROM PopvsVac

--TEMP TABLE
DROP TABLE IF EXISTS PercentPopoluationVaccinated
CREATE TABLE #PercentPopoluationVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric(18, 2),
	New_vaccinations numeric,
    RollingPeopleVaccinated numeric(18, 2)
)

INSERT INTO #PercentPopoluationVaccinated 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..Coviddeaths dea
JOIN PortfolioProject..Covidvaccinations vac
    ON dea.location = vac.Location
    AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated / Population) * 100
FROM #PercentPopoluationVaccinated

--CREATING VIEW TO STORE DATA FOR LATER VISUALIZATION

-- First, drop the view if it already exists
DROP VIEW IF EXISTS PercentPopoluationVaccinated;

-- Then, create the view
CREATE VIEW PercentPopoluationVaccinated AS

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..Coviddeaths dea
JOIN PortfolioProject..Covidvaccinations vac
    ON dea.location = vac.Location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;


