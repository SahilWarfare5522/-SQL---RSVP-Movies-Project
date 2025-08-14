-- Step 2 — Verify Schema
-- See all tables in imdb
SHOW TABLES;

-- Check structure of each table
DESCRIBE movie;
DESCRIBE genre;
DESCRIBE director_mapping;
DESCRIBE role_mapping;
DESCRIBE names;
DESCRIBE ratings;

-- Quick row counts for each table
SELECT 'movie' AS table_name, COUNT(*) AS total_rows FROM movie
UNION ALL
SELECT 'genre', COUNT(*) FROM genre
UNION ALL
SELECT 'director_mapping', COUNT(*) FROM director_mapping
UNION ALL
SELECT 'role_mapping', COUNT(*) FROM role_mapping
UNION ALL
SELECT 'names', COUNT(*) FROM names
UNION ALL
SELECT 'ratings', COUNT(*) FROM ratings;

SHOW COLUMNS FROM movie;

ALTER TABLE movie ADD COLUMN worldwide_gross_num DECIMAL(15,2);

UPDATE movie
SET worldwide_gross_num = CAST(
    REPLACE(
        REPLACE(
            REPLACE(worlwide_gross_income, '$', ''), 
        'INR', ''), 
    ',', '') AS DECIMAL(15,2)
)
WHERE worlwide_gross_income IS NOT NULL 
  AND worlwide_gross_income <> '';
  
-- Step 3 — Data Cleaning & Preparation
-- 3.1 Convert worlwide_gross_income to numeric

-- 1) Check if column exists, and add only if it doesn't
SET @col_exists := (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'imdb' 
      AND TABLE_NAME = 'movie' 
      AND COLUMN_NAME = 'worldwide_gross_num'
);

SET @sql := IF(@col_exists = 0, 
               'ALTER TABLE movie ADD COLUMN worldwide_gross_num DECIMAL(15,2);', 
               'SELECT "Column already exists" AS message;');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2) Populate the numeric column (convert from worlwide_gross_income)
UPDATE movie
SET worldwide_gross_num = CAST(
    REPLACE(
        REPLACE(
            REPLACE(worlwide_gross_income, '$', ''), 
        'INR', ''), 
    ',', '') AS DECIMAL(15,2)
)
WHERE worlwide_gross_income IS NOT NULL 
  AND worlwide_gross_income <> '';
  
SELECT worlwide_gross_income, worldwide_gross_num
FROM movie
WHERE worlwide_gross_income IS NOT NULL
LIMIT 10;

-- Step 3.2 — Normalize country & languages into mapping tables

/* ======================================
   COUNTRY mapping (no recursive CTE)
   ====================================== */
CREATE TABLE IF NOT EXISTS movie_country (
    movie_id VARCHAR(10),
    country VARCHAR(100)
);

-- Clear old data
TRUNCATE TABLE movie_country;

-- Insert 1st country from list
INSERT INTO movie_country (movie_id, country)
SELECT id, TRIM(SUBSTRING_INDEX(country, ',', 1))
FROM movie
WHERE country IS NOT NULL AND country <> '';

-- Insert 2nd country if exists
INSERT INTO movie_country (movie_id, country)
SELECT id, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(country, ',', 2), ',', -1))
FROM movie
WHERE country LIKE '%,%';

-- Insert 3rd country if exists
INSERT INTO movie_country (movie_id, country)
SELECT id, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(country, ',', 3), ',', -1))
FROM movie
WHERE country LIKE '%,%,%';



/* ======================================
   LANGUAGE mapping (no recursive CTE)
   ====================================== */
CREATE TABLE IF NOT EXISTS movie_language (
    movie_id VARCHAR(10),
    language VARCHAR(100)
);

-- Clear old data
TRUNCATE TABLE movie_language;

-- Insert 1st language from list
INSERT INTO movie_language (movie_id, language)
SELECT id, TRIM(SUBSTRING_INDEX(languages, ',', 1))
FROM movie
WHERE languages IS NOT NULL AND languages <> '';

-- Insert 2nd language if exists
INSERT INTO movie_language (movie_id, language)
SELECT id, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(languages, ',', 2), ',', -1))
FROM movie
WHERE languages LIKE '%,%';

-- Insert 3rd language if exists
INSERT INTO movie_language (movie_id, language)
SELECT id, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(languages, ',', 3), ',', -1))
FROM movie
WHERE languages LIKE '%,%,%';

SELECT * FROM movie_country LIMIT 10;
SELECT * FROM movie_language LIMIT 10;

-- Step 3.3 — Handle NULLs & Standardize Values

/* ========================
   Replace NULL or empty strings in key columns
   ======================== */

-- Country
UPDATE movie 
SET country = 'Unknown' 
WHERE country IS NULL OR TRIM(country) = '';

-- Languages
UPDATE movie 
SET languages = 'Unknown' 
WHERE languages IS NULL OR TRIM(languages) = '';

-- Production Company
UPDATE movie 
SET production_company = 'Unknown' 
WHERE production_company IS NULL OR TRIM(production_company) = '';

-- Gross Income (text column)
UPDATE movie 
SET worlwide_gross_income = 'Unknown' 
WHERE worlwide_gross_income IS NULL OR TRIM(worlwide_gross_income) = '';

/* ========================
   For numeric columns, set NULL to 0
   ======================== */
UPDATE movie
SET worldwide_gross_num = 0
WHERE worldwide_gross_num IS NULL;

UPDATE ratings
SET avg_rating = 0
WHERE avg_rating IS NULL;

UPDATE ratings
SET total_votes = 0
WHERE total_votes IS NULL;

UPDATE ratings
SET median_rating = 0
WHERE median_rating IS NULL;

# =========================================== #
-- Segment 1 — Queries Q1 to Q9 for analysis.
# =========================================== #

-- Q1 — List all the movies released in a specific year (e.g., 2019)
SELECT id, title, year, date_published
FROM movie
WHERE year = 2019
ORDER BY date_published;

-- Q2 — Find the number of movies released each year
SELECT year, COUNT(*) AS total_movies
FROM movie
GROUP BY year
ORDER BY year;

-- Q3 — Find the top 5 movies with the highest average rating
SELECT m.title, r.avg_rating
FROM movie m
JOIN ratings r ON m.id = r.movie_id
ORDER BY r.avg_rating DESC
LIMIT 5;

-- Q4 — List all distinct genres available in the dataset
SELECT DISTINCT genre
FROM genre
ORDER BY genre;

-- Q5 — Find movies with more than one genre
SELECT m.title, COUNT(g.genre) AS genre_count
FROM movie m
JOIN genre g ON m.id = g.movie_id
GROUP BY m.id, m.title
HAVING COUNT(g.genre) > 1
ORDER BY genre_count DESC;

-- Q6 — Find all movies in which a specific actor (e.g., “Tom Hanks”) acted
SELECT m.title, m.year
FROM movie m
JOIN role_mapping rm ON m.id = rm.movie_id
JOIN names n ON rm.name_id = n.id
WHERE n.name = 'Tom Hanks'
ORDER BY m.year;

-- Q7 — Find the number of movies directed by each director
SELECT n.name AS director_name, COUNT(dm.movie_id) AS movies_directed
FROM director_mapping dm
JOIN names n ON dm.name_id = n.id
GROUP BY n.name
ORDER BY movies_directed DESC;

-- Q8 — Find movies that have both English and another language
SELECT m.title, m.languages
FROM movie m
WHERE languages LIKE '%English%'
  AND languages LIKE '%,%';

-- Q9 — Find movies produced by a specific production company (e.g., “Marvel Studios”)
SELECT id, title, year
FROM movie
WHERE production_company = 'Marvel Studios'
ORDER BY year;

# =========================================== #
-- Segment 2 — Queries Q10 to Q17 for analysis.
# =========================================== #

-- Q10 — Find the top 5 directors with the highest average movie rating
SELECT n.name AS director_name, 
       ROUND(AVG(r.avg_rating), 2) AS avg_director_rating
FROM director_mapping dm
JOIN names n ON dm.name_id = n.id
JOIN ratings r ON dm.movie_id = r.movie_id
GROUP BY n.name
ORDER BY avg_director_rating DESC
LIMIT 5;

-- Q11 — Find the top 10 actors who have appeared in the most movies
SELECT n.name AS actor_name, 
       COUNT(rm.movie_id) AS total_movies
FROM role_mapping rm
JOIN names n ON rm.name_id = n.id
GROUP BY n.name
ORDER BY total_movies DESC
LIMIT 10;

-- Q12 — Find the highest-grossing movie for each year
SELECT m.year, m.title, m.worldwide_gross_num
FROM movie m
WHERE worldwide_gross_num = (
    SELECT MAX(worldwide_gross_num)
    FROM movie
    WHERE year = m.year
)
ORDER BY m.year;

-- Q13 — Find the genre with the highest average rating
SELECT g.genre, 
       ROUND(AVG(r.avg_rating), 2) AS avg_genre_rating
FROM genre g
JOIN ratings r ON g.movie_id = r.movie_id
GROUP BY g.genre
ORDER BY avg_genre_rating DESC
LIMIT 1;

-- Q14 — Find the most common language among movies
SELECT language, COUNT(*) AS movie_count
FROM movie_language
GROUP BY language
ORDER BY movie_count DESC
LIMIT 1;

-- Q15 — Find the number of movies released each month in a specific year (e.g., 2019)
SELECT MONTH(date_published) AS release_month, 
       COUNT(*) AS total_movies
FROM movie
WHERE year = 2019
GROUP BY release_month
ORDER BY release_month;

-- Q16 — Find movies with a median rating of 10 and more than 1000 votes
SELECT m.title, r.median_rating, r.total_votes
FROM movie m
JOIN ratings r ON m.id = r.movie_id
WHERE r.median_rating = 10
  AND r.total_votes > 1000
ORDER BY r.total_votes DESC;

-- Q17 — Find the percentage of movies for each genre
SELECT g.genre, 
       ROUND( (COUNT(*) / (SELECT COUNT(*) FROM movie)) * 100, 2) AS percentage
FROM genre g
GROUP BY g.genre
ORDER BY percentage DESC;

# =========================================== #
-- Segment 3 — Queries Q18 to Q24 for analysis.
# =========================================== #

-- Q18 — Find the top 5 production companies by total worldwide gross income
SELECT production_company, 
       ROUND(SUM(worldwide_gross_num), 2) AS total_gross
FROM movie
WHERE production_company <> 'Unknown'
GROUP BY production_company
ORDER BY total_gross DESC
LIMIT 5;

-- Q19 — Find the average rating for movies in each language
SELECT ml.language, 
       ROUND(AVG(r.avg_rating), 2) AS avg_rating
FROM movie_language ml
JOIN ratings r ON ml.movie_id = r.movie_id
GROUP BY ml.language
ORDER BY avg_rating DESC;

-- Q20 — Find the top 5 countries with the most movies produced
SELECT mc.country, COUNT(*) AS total_movies
FROM movie_country mc
GROUP BY mc.country
ORDER BY total_movies DESC
LIMIT 5;

-- Q21 — Find all movies released between two specific dates
SELECT title, date_published
FROM movie
WHERE date_published BETWEEN '2018-01-01' AND '2018-12-31'
ORDER BY date_published;

-- Q22 — Find the director who has directed the most movies in a single year
SELECT n.name AS director_name, m.year, COUNT(*) AS total_movies
FROM director_mapping dm
JOIN names n ON dm.name_id = n.id
JOIN movie m ON dm.movie_id = m.id
GROUP BY n.name, m.year
ORDER BY total_movies DESC
LIMIT 1;

-- Q23 — Find the most common actor-director pair
SELECT n_actor.name AS actor_name, 
       n_director.name AS director_name, 
       COUNT(*) AS movies_together
FROM role_mapping rm
JOIN names n_actor ON rm.name_id = n_actor.id
JOIN director_mapping dm ON rm.movie_id = dm.movie_id
JOIN names n_director ON dm.name_id = n_director.id
GROUP BY n_actor.name, n_director.name
ORDER BY movies_together DESC
LIMIT 1;

-- Q24 — Find movies with above-average ratings for their genre
USE imdb;

SELECT m.title, g.genre, r.avg_rating
FROM movie m
JOIN ratings r       ON m.id = r.movie_id
JOIN genre g         ON m.id = g.movie_id
JOIN (
  SELECT g.genre, AVG(r.avg_rating) AS avg_genre_rating
  FROM genre g
  JOIN ratings r ON g.movie_id = r.movie_id
  GROUP BY g.genre
) ga ON g.genre = ga.genre
WHERE r.avg_rating > ga.avg_genre_rating
ORDER BY g.genre, r.avg_rating DESC
LIMIT 1000;

# =========================================== #
-- Segment 4 — Queries Q25 to Q31 for analysis.
# =========================================== #

-- Q25 — Find the top 5 genres with the highest total worldwide gross
SELECT g.genre, 
       ROUND(SUM(m.worldwide_gross_num), 2) AS total_gross
FROM genre g
JOIN movie m ON g.movie_id = m.id
WHERE m.worldwide_gross_num > 0
GROUP BY g.genre
ORDER BY total_gross DESC
LIMIT 5;

-- Q26 — Find the average duration of movies per genre
SELECT g.genre, 
       ROUND(AVG(m.duration), 2) AS avg_duration
FROM genre g
JOIN movie m ON g.movie_id = m.id
GROUP BY g.genre
ORDER BY avg_duration DESC;

-- Q27 — Find the actors who have worked with the most different directors
SELECT n_actor.name AS actor_name, 
       COUNT(DISTINCT n_director.name) AS unique_directors
FROM role_mapping rm
JOIN names n_actor ON rm.name_id = n_actor.id
JOIN director_mapping dm ON rm.movie_id = dm.movie_id
JOIN names n_director ON dm.name_id = n_director.id
GROUP BY n_actor.name
ORDER BY unique_directors DESC
LIMIT 10;

-- Q28 — Find the top 3 most common director–genre combinations
SELECT n.name AS director_name, g.genre, COUNT(*) AS total_movies
FROM director_mapping dm
JOIN names n ON dm.name_id = n.id
JOIN genre g ON dm.movie_id = g.movie_id
GROUP BY n.name, g.genre
ORDER BY total_movies DESC
LIMIT 3;

-- Q29 — Find the top-rated movie for each genre
SELECT g.genre, m.title, r.avg_rating
FROM genre g
JOIN movie m ON g.movie_id = m.id
JOIN ratings r ON m.id = r.movie_id
WHERE (g.genre, r.avg_rating) IN (
    SELECT g2.genre, MAX(r2.avg_rating)
    FROM genre g2
    JOIN ratings r2 ON g2.movie_id = r2.movie_id
    GROUP BY g2.genre
)
ORDER BY g.genre;

-- Q30 — Find the percentage contribution of each country to total worldwide gross
SELECT mc.country, 
       ROUND( (SUM(m.worldwide_gross_num) / (SELECT SUM(worldwide_gross_num) FROM movie)) * 100, 2) AS percentage_gross
FROM movie_country mc
JOIN movie m ON mc.movie_id = m.id
WHERE m.worldwide_gross_num > 0
GROUP BY mc.country
ORDER BY percentage_gross DESC;

-- Q31 — Find the month with the highest number of movie releases across all years
SELECT MONTH(date_published) AS release_month, COUNT(*) AS total_movies
FROM movie
GROUP BY release_month
ORDER BY total_movies DESC
LIMIT 1;

# =========================================== #
-- Segment 5 — Queries Q32 to Q38 for analysis.
# =========================================== #

-- Q32 — Find the top 5 actors with the highest average movie rating (minimum 5 movies)
SELECT n.name AS actor_name, 
       ROUND(AVG(r.avg_rating), 2) AS avg_rating, 
       COUNT(*) AS total_movies
FROM role_mapping rm
JOIN names n ON rm.name_id = n.id
JOIN ratings r ON rm.movie_id = r.movie_id
GROUP BY n.name
HAVING COUNT(*) >= 5
ORDER BY avg_rating DESC
LIMIT 5;

-- Q33 — Find the longest movie in each genre
SELECT g.genre, m.title, m.duration
FROM genre g
JOIN movie m ON g.movie_id = m.id
WHERE (g.genre, m.duration) IN (
    SELECT g2.genre, MAX(m2.duration)
    FROM genre g2
    JOIN movie m2 ON g2.movie_id = m2.id
    GROUP BY g2.genre
)
ORDER BY g.genre;

-- Q34 — Find the average gross income per production company
SELECT production_company, 
       ROUND(AVG(worldwide_gross_num), 2) AS avg_gross
FROM movie
WHERE production_company <> 'Unknown'
  AND worldwide_gross_num > 0
GROUP BY production_company
ORDER BY avg_gross DESC;

-- Q35 — Find movies where the average rating is higher than the director’s average rating
SELECT m.title, n.name AS director_name, r.avg_rating, dir_avg.avg_director_rating
FROM movie m
JOIN ratings r ON m.id = r.movie_id
JOIN director_mapping dm ON m.id = dm.movie_id
JOIN names n ON dm.name_id = n.id
JOIN (
    SELECT dm.name_id, AVG(r.avg_rating) AS avg_director_rating
    FROM director_mapping dm
    JOIN ratings r ON dm.movie_id = r.movie_id
    GROUP BY dm.name_id
) dir_avg ON dm.name_id = dir_avg.name_id
WHERE r.avg_rating > dir_avg.avg_director_rating
ORDER BY r.avg_rating DESC;

-- Q36 — Find the actor who has acted in the most different genres
SELECT n.name AS actor_name, COUNT(DISTINCT g.genre) AS genre_count
FROM role_mapping rm
JOIN names n ON rm.name_id = n.id
JOIN genre g ON rm.movie_id = g.movie_id
GROUP BY n.name
ORDER BY genre_count DESC
LIMIT 1;

-- Q37 — Find the most common genre per country
SELECT mc.country, g.genre, COUNT(*) AS genre_count
FROM movie_country mc
JOIN genre g ON mc.movie_id = g.movie_id
GROUP BY mc.country, g.genre
HAVING genre_count = (
    SELECT MAX(sub.genre_count)
    FROM (
        SELECT mc2.country, g2.genre, COUNT(*) AS genre_count
        FROM movie_country mc2
        JOIN genre g2 ON mc2.movie_id = g2.movie_id
        GROUP BY mc2.country, g2.genre
    ) sub
    WHERE sub.country = mc.country
)
ORDER BY mc.country;

-- Q38 — Find the top 10 movies with the highest votes-to-rating ratio
SELECT m.title, r.total_votes, r.avg_rating, 
       ROUND(r.total_votes / r.avg_rating, 2) AS votes_per_rating
FROM movie m
JOIN ratings r ON m.id = r.movie_id
WHERE r.avg_rating > 0
ORDER BY votes_per_rating DESC
LIMIT 10;

# =========================================== #
-- Segment 6 — Queries Q39 to Q45 for analysis.
# =========================================== #

-- Q39 — Find the director who has worked with the most unique actors
SELECT n_director.name AS director_name, 
       COUNT(DISTINCT n_actor.name) AS unique_actors
FROM director_mapping dm
JOIN names n_director ON dm.name_id = n_director.id
JOIN role_mapping rm ON dm.movie_id = rm.movie_id
JOIN names n_actor ON rm.name_id = n_actor.id
GROUP BY n_director.name
ORDER BY unique_actors DESC
LIMIT 1;

-- Q40 — Find the average duration of movies for each production company
SELECT production_company, 
       ROUND(AVG(duration), 2) AS avg_duration
FROM movie
WHERE production_company <> 'Unknown'
GROUP BY production_company
ORDER BY avg_duration DESC;

-- Q41 — Find the highest-grossing movie for each language
SELECT ml.language, m.title, m.worldwide_gross_num
FROM movie_language ml
JOIN movie m ON ml.movie_id = m.id
WHERE (ml.language, m.worldwide_gross_num) IN (
    SELECT ml2.language, MAX(m2.worldwide_gross_num)
    FROM movie_language ml2
    JOIN movie m2 ON ml2.movie_id = m2.id
    GROUP BY ml2.language
)
ORDER BY ml.language;

-- Q42 — Find the actors who have appeared in movies from the most different countries
SELECT n.name AS actor_name, COUNT(DISTINCT mc.country) AS country_count
FROM role_mapping rm
JOIN names n ON rm.name_id = n.id
JOIN movie_country mc ON rm.movie_id = mc.movie_id
GROUP BY n.name
ORDER BY country_count DESC
LIMIT 5;

-- Q43 — Find the total worldwide gross per year
SELECT year, 
       ROUND(SUM(worldwide_gross_num), 2) AS total_gross
FROM movie
WHERE worldwide_gross_num > 0
GROUP BY year
ORDER BY year;

-- Q44 — Find the actor with the highest total worldwide gross from all their movies
SELECT n.name AS actor_name, 
       ROUND(SUM(m.worldwide_gross_num), 2) AS total_actor_gross
FROM role_mapping rm
JOIN names n ON rm.name_id = n.id
JOIN movie m ON rm.movie_id = m.id
WHERE m.worldwide_gross_num > 0
GROUP BY n.name
ORDER BY total_actor_gross DESC
LIMIT 1;

-- Q45 — Find the number of movies in each rating category (1–10)
SELECT avg_rating, COUNT(*) AS movie_count
FROM ratings
GROUP BY avg_rating
ORDER BY avg_rating DESC;

# =========================================== #
-- Segment 7 — Queries Q46 to Q50 for analysis.
# =========================================== #

-- Q46 — Find the top 5 directors whose movies have the highest average worldwide gross
SELECT n.name AS director_name, 
       ROUND(AVG(m.worldwide_gross_num), 2) AS avg_gross, 
       COUNT(*) AS total_movies
FROM director_mapping dm
JOIN names n ON dm.name_id = n.id
JOIN movie m ON dm.movie_id = m.id
WHERE m.worldwide_gross_num > 0
GROUP BY n.name
HAVING COUNT(*) >= 2
ORDER BY avg_gross DESC
LIMIT 5;

-- Q47 — Find the average rating per country
SELECT mc.country, 
       ROUND(AVG(r.avg_rating), 2) AS avg_rating
FROM movie_country mc
JOIN ratings r ON mc.movie_id = r.movie_id
GROUP BY mc.country
ORDER BY avg_rating DESC;

-- Q48 — Find the year with the highest average movie rating
SELECT m.year, 
       ROUND(AVG(r.avg_rating), 2) AS avg_rating
FROM movie m
JOIN ratings r ON m.id = r.movie_id
GROUP BY m.year
ORDER BY avg_rating DESC
LIMIT 1;

-- Q49 — Find the most frequent co-actor pair
SELECT n1.name AS actor_1, n2.name AS actor_2, COUNT(*) AS movies_together
FROM role_mapping rm1
JOIN role_mapping rm2 ON rm1.movie_id = rm2.movie_id AND rm1.name_id < rm2.name_id
JOIN names n1 ON rm1.name_id = n1.id
JOIN names n2 ON rm2.name_id = n2.id
GROUP BY n1.name, n2.name
ORDER BY movies_together DESC
LIMIT 1;

-- Q50 — Find movies with the highest rating-to-duration ratio
SELECT m.title, m.duration, r.avg_rating, 
       ROUND(r.avg_rating / m.duration, 4) AS rating_per_minute
FROM movie m
JOIN ratings r ON m.id = r.movie_id
WHERE m.duration > 0
ORDER BY rating_per_minute DESC
LIMIT 10;