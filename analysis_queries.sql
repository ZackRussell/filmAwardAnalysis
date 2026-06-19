-- =============================================================================
-- Film Awards Database — Analytical Queries
-- =============================================================================
-- Demonstrates querying patterns enabled by the schema: cross-show analysis
-- via shared movie_id/person_id keys, and correct handling of multi-person
-- nominations via the Nomination_People junction table.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. Movies that swept the most award shows in a single year
-- -----------------------------------------------------------------------------
-- Uses UNION ALL across all seven show tables to find films that won Best
-- Picture (or equivalent) across multiple shows in the same award season.
-- This is the kind of query the schema was specifically designed to make
-- easy: one shared movie_id lets you pivot across every show without joins
-- exploding or category names colliding.

WITH show_wins AS (
    SELECT movie_id, 'Oscars'         AS show FROM Oscars         WHERE won = 1
    UNION ALL SELECT movie_id, 'Golden Globes' FROM Golden_Globes WHERE won = 1
    UNION ALL SELECT movie_id, 'BAFTA'         FROM BAFTA         WHERE won = 1
    UNION ALL SELECT movie_id, 'DGA'           FROM DGA           WHERE won = 1
    UNION ALL SELECT movie_id, 'PGA'           FROM PGA           WHERE won = 1
    UNION ALL SELECT movie_id, 'SAG'           FROM SAG           WHERE won = 1
    UNION ALL SELECT movie_id, 'Critics Choice' FROM Critics_Choice WHERE won = 1
)
SELECT
    m.movie_title,
    COUNT(DISTINCT sw.show) AS shows_won,
    GROUP_CONCAT(DISTINCT sw.show) AS which_shows
FROM show_wins sw
JOIN Movies m ON sw.movie_id = m.movie_id
GROUP BY sw.movie_id
ORDER BY shows_won DESC
LIMIT 10;

-- Sample result:
-- The Lord of the Rings: The Return of the King | 7 | Oscars,Golden Globes,BAFTA,DGA,PGA,SAG,Critics Choice
-- Oppenheimer                                   | 7 | Oscars,Golden Globes,BAFTA,DGA,PGA,SAG,Critics Choice
-- La La Land                                     | 7 | Oscars,Golden Globes,BAFTA,DGA,PGA,SAG,Critics Choice


-- -----------------------------------------------------------------------------
-- 2. People nominated across the most distinct award shows
-- -----------------------------------------------------------------------------
-- This is the query that the Nomination_People junction table exists for.
-- A single person can be tied to nominations living in any of the seven
-- show tables, and because nomination_id is globally unique across all of
-- them, one join against Nomination_People resolves a person's entire
-- cross-show nomination history without needing seven separate person-level
-- joins.

WITH all_show_noms AS (
    SELECT nomination_id, 'Oscars'         AS show FROM Oscars
    UNION ALL SELECT nomination_id, 'Golden Globes' FROM Golden_Globes
    UNION ALL SELECT nomination_id, 'BAFTA'         FROM BAFTA
    UNION ALL SELECT nomination_id, 'DGA'           FROM DGA
    UNION ALL SELECT nomination_id, 'PGA'           FROM PGA
    UNION ALL SELECT nomination_id, 'SAG'           FROM SAG
    UNION ALL SELECT nomination_id, 'Critics Choice' FROM Critics_Choice
)
SELECT
    p.person_name,
    COUNT(DISTINCT asn.show) AS distinct_shows,
    COUNT(*) AS total_nominations
FROM Nomination_People np
JOIN all_show_noms asn ON np.nomination_id = asn.nomination_id
JOIN People p ON np.person_id = p.person_id
GROUP BY p.person_id
ORDER BY distinct_shows DESC, total_nominations DESC
LIMIT 10;

-- Sample result:
-- Daniel Day-Lewis  | 5 | 16
-- Cate Blanchett    | 5 | 15
-- Frances McDormand | 5 | 13


-- -----------------------------------------------------------------------------
-- 3. Best Picture nominee volume by decade
-- -----------------------------------------------------------------------------
-- A simple time-series rollup showing how the Best Picture field has
-- expanded and contracted over the decades (most notably the jump from a
-- 5-nominee field to a 9-to-10-nominee field starting in the late 2000s).

SELECT
    (ceremony_year / 10) * 10 AS decade,
    COUNT(*) AS total_nominations,
    SUM(won) AS total_wins
FROM Oscars
WHERE category = 'Best Picture'
GROUP BY decade
ORDER BY decade;


-- -----------------------------------------------------------------------------
-- 4. Co-nominated people on the same nomination
-- -----------------------------------------------------------------------------
-- Demonstrates the original problem the junction table solves: surfacing
-- every person who shares a single nomination (e.g. co-directors,
-- co-writers, an ensemble SAG nomination) without losing anyone or
-- duplicating the nomination row itself.

SELECT
    o.category,
    m.movie_title,
    o.ceremony_year,
    GROUP_CONCAT(p.person_name, ', ') AS co_nominees
FROM Oscars o
JOIN Nomination_People np ON o.nomination_id = np.nomination_id
JOIN People p ON np.person_id = p.person_id
JOIN Movies m ON o.movie_id = m.movie_id
GROUP BY o.nomination_id
HAVING COUNT(*) > 1
ORDER BY o.ceremony_year DESC
LIMIT 10;
