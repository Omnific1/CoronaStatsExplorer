/*
Covid-19 Data Exploration

Skills used: Joins, CTEs, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

--Fetch all records while filtering out NULL continents
SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 3,4;

-- Initial dataset selection
SELECT Location, Date, Total_Cases, New_Cases, Total_Deaths, Population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2;

//Total Cases vs Total Deaths (Likelihood of dying if infected)
SELECT Location, Date, Total_Cases, Total_Deaths, (Total_Deaths / NULLIF(Total_Cases, 0)) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE Location LIKE '%states%'
AND continent IS NOT NULL 
ORDER BY 1,2;

-- Total Cases vs Population (Percentage of population infected)
SELECT Location, Date, Population, Total_Cases, (Total_Cases / NULLIF(Population, 0)) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2;

-- Countries with Highest Infection Rate compared to Population
SELECT Location, Population, MAX(Total_Cases) AS HighestInfectionCount,  MAX((Total_Cases / NULLIF(Population, 0))) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

-- Countries with Highest Death Count per Population
SELECT Location, MAX(CAST(Total_Deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- Continents with the Highest Death Count
SELECT Continent, MAX(CAST(Total_Deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY Continent
ORDER BY TotalDeathCount DESC;

-- Global Numbers: Total Cases, Deaths, and Death Percentage
SELECT SUM(New_Cases) AS Total_Cases, SUM(CAST(New_Deaths AS INT)) AS Total_Deaths, 
       SUM(CAST(New_Deaths AS INT)) / NULLIF(SUM(New_Cases), 0) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2;

-- Total Population vs Vaccinations
WITH PopVsVac AS (
    SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations,
           SUM(CONVERT(INT, vac.New_Vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.Location, dea.Date) AS RollingPeopleVaccinated
    FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac
        ON dea.Location = vac.Location AND dea.Date = vac.Date
    WHERE dea.Continent IS NOT NULL 
)
SELECT *, (RollingPeopleVaccinated / NULLIF(Population, 0)) * 100 AS PercentPopulationVaccinated
FROM PopVsVac;

-- Using Temp Table for Vaccination Calculations
DROP TABLE IF EXISTS #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_Vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations,
       SUM(CONVERT(INT, vac.New_Vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.Location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.Location = vac.Location AND dea.Date = vac.Date;

SELECT *, (RollingPeopleVaccinated / NULLIF(Population, 0)) * 100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated;

-- Creating View for Future Visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations,
       SUM(CONVERT(INT, vac.New_Vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.Location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.Location = vac.Location AND dea.Date = vac.Date
WHERE dea.Continent IS NOT NULL;

