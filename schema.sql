-- =============================================================================
-- Film Awards Relational Database — Schema
-- =============================================================================
-- A normalized schema tracking nominations and wins across seven major film
-- award shows (Oscars, Golden Globes, BAFTA, DGA, PGA, SAG, Critics Choice),
-- spanning nearly a century of award history.
--
-- Design notes:
--   - Each award show has its own table rather than one shared "Nominations"
--     table with a show column. This keeps category names (which differ
--     meaningfully between shows) clean and makes per-show querying simple,
--     while a shared Movies/People schema still allows cross-show analysis.
--   - nomination_id is globally unique ACROSS all show tables, not just
--     within each one. This lets Nomination_People reference any show's
--     nomination by a single foreign key without collisions.
--   - Nomination_People is a junction table that solves the multi-person
--     nomination problem: when a nomination is shared by multiple people
--     (e.g. co-directors, co-writers, an ensemble cast), each person gets
--     their own row pointing at the same nomination_id, rather than the
--     nomination being duplicated or one person being arbitrarily dropped.
-- =============================================================================

PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------------
-- Reference tables
-- ---------------------------------------------------------------------------

CREATE TABLE Movies (
    movie_id    INTEGER PRIMARY KEY,
    movie_title TEXT NOT NULL
);

CREATE TABLE People (
    person_id   INTEGER PRIMARY KEY,
    person_name TEXT NOT NULL
);

-- ---------------------------------------------------------------------------
-- Award show tables
-- ---------------------------------------------------------------------------
-- Each table shares the same shape: a nomination, the movie it belongs to,
-- the category, the ceremony year, the film's release year, and whether it
-- won. nomination_id is globally unique across all of these tables.

CREATE TABLE Oscars (
    nomination_id  INTEGER PRIMARY KEY,
    movie_id       INTEGER NOT NULL REFERENCES Movies(movie_id),
    category       TEXT NOT NULL,
    ceremony_year  INTEGER NOT NULL,
    film_year      INTEGER NOT NULL,
    won            INTEGER NOT NULL CHECK (won IN (0, 1))
);

CREATE TABLE Golden_Globes (
    nomination_id  INTEGER PRIMARY KEY,
    movie_id       INTEGER NOT NULL REFERENCES Movies(movie_id),
    category       TEXT NOT NULL,
    ceremony_year  INTEGER NOT NULL,
    film_year      INTEGER NOT NULL,
    won            INTEGER NOT NULL CHECK (won IN (0, 1))
);

CREATE TABLE BAFTA (
    nomination_id  INTEGER PRIMARY KEY,
    movie_id       INTEGER NOT NULL REFERENCES Movies(movie_id),
    category       TEXT NOT NULL,
    ceremony_year  INTEGER NOT NULL,
    film_year      INTEGER NOT NULL,
    won            INTEGER NOT NULL CHECK (won IN (0, 1))
);

CREATE TABLE DGA (
    nomination_id  INTEGER PRIMARY KEY,
    movie_id       INTEGER NOT NULL REFERENCES Movies(movie_id),
    category       TEXT NOT NULL,
    ceremony_year  INTEGER NOT NULL,
    film_year      INTEGER NOT NULL,
    won            INTEGER NOT NULL CHECK (won IN (0, 1))
);

CREATE TABLE PGA (
    nomination_id  INTEGER PRIMARY KEY,
    movie_id       INTEGER NOT NULL REFERENCES Movies(movie_id),
    category       TEXT NOT NULL,
    ceremony_year  INTEGER NOT NULL,
    film_year      INTEGER NOT NULL,
    won            INTEGER NOT NULL CHECK (won IN (0, 1))
);

CREATE TABLE SAG (
    nomination_id  INTEGER PRIMARY KEY,
    movie_id       INTEGER NOT NULL REFERENCES Movies(movie_id),
    category       TEXT NOT NULL,
    ceremony_year  INTEGER NOT NULL,
    film_year      INTEGER NOT NULL,
    won            INTEGER NOT NULL CHECK (won IN (0, 1))
);

CREATE TABLE Critics_Choice (
    nomination_id  INTEGER PRIMARY KEY,
    movie_id       INTEGER NOT NULL REFERENCES Movies(movie_id),
    category       TEXT NOT NULL,
    ceremony_year  INTEGER NOT NULL,
    film_year      INTEGER NOT NULL,
    won            INTEGER NOT NULL CHECK (won IN (0, 1))
);

-- ---------------------------------------------------------------------------
-- Junction table: handles multi-person nominations across ALL shows
-- ---------------------------------------------------------------------------
-- nomination_id is not a foreign key to any single show table here, since it
-- can point into any of the seven tables above (they share a single
-- nomination_id namespace). Applications/queries join against the relevant
-- show table directly when person-level detail is needed.

CREATE TABLE Nomination_People (
    id             INTEGER PRIMARY KEY,
    nomination_id  INTEGER NOT NULL,
    person_id      INTEGER NOT NULL REFERENCES People(person_id)
);

CREATE INDEX idx_nomination_people_nomination_id ON Nomination_People(nomination_id);
CREATE INDEX idx_nomination_people_person_id ON Nomination_People(person_id);

CREATE INDEX idx_oscars_movie_id ON Oscars(movie_id);
CREATE INDEX idx_golden_globes_movie_id ON Golden_Globes(movie_id);
CREATE INDEX idx_bafta_movie_id ON BAFTA(movie_id);
CREATE INDEX idx_dga_movie_id ON DGA(movie_id);
CREATE INDEX idx_pga_movie_id ON PGA(movie_id);
CREATE INDEX idx_sag_movie_id ON SAG(movie_id);
CREATE INDEX idx_critics_choice_movie_id ON Critics_Choice(movie_id);
