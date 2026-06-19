# Film Awards Relational Database

A normalized SQL database tracking nominations and wins across seven major film award shows, spanning nearly a century of award history: the **Oscars**, **Golden Globes**, **BAFTA**, **DGA**, **PGA**, **SAG**, and **Critics Choice** awards.

This started as a personal project to satisfy my own curiosity about award patterns across shows, and turned into an exercise in proper relational schema design once I ran into a real modeling problem: how do you represent a single nomination shared by multiple people?

## The Problem

A nomination like Best Director for *Everything Everywhere All at Once* belongs to **both** Daniel Kwan and Daniel Scheinert. A naive schema either duplicates the nomination row per person (breaking any "count nominations" query) or arbitrarily picks one person and loses the other.

## The Solution

A junction table. `Nomination_People` links a single `nomination_id` to as many `person_id`s as actually share that nomination, with `nomination_id` kept **globally unique across all seven award-show tables**, not just unique within each one. That means one join against `Nomination_People` resolves a person's complete nomination history across every show they've ever been nominated in, without needing seven separate person-level joins.

## Schema

```
Movies                People
├─ movie_id (PK)      ├─ person_id (PK)
└─ movie_title         └─ person_name

Oscars / Golden_Globes / BAFTA / DGA / PGA / SAG / Critics_Choice
├─ nomination_id (PK, globally unique across all seven tables)
├─ movie_id (FK → Movies)
├─ category
├─ ceremony_year
├─ film_year
└─ won

Nomination_People
├─ id (PK)
├─ nomination_id  (points into any of the seven show tables above)
└─ person_id (FK → People)
```

Each award show gets its own table rather than one giant `Nominations` table with a `show` column. Category names mean genuinely different things across shows (BAFTA's "Best Film" isn't the Oscars' "Best Picture" in scope or voting body), so keeping them separate avoids a sprawling categorical mess while the shared `movie_id` and `person_id` keys still make cross-show analysis a simple join, not a headache.

## What's in the data

- 894 movies, 740 people
- 1,277 Oscar nominations going back to the first ceremony in 1928
- 1,160 additional nominations across the other six shows
- 1,481 person-to-nomination links in the junction table

## Example queries

The full set lives in [`sql/analysis_queries.sql`](sql/analysis_queries.sql). A few highlights:

**Movies that swept the most award shows in one season** — built with a `UNION ALL` across all seven show tables, made possible by the shared `movie_id` key:

```
The Lord of the Rings: The Return of the King | 7 shows | Oscars, Golden Globes, BAFTA, DGA, PGA, SAG, Critics Choice
Oppenheimer                                    | 7 shows | Oscars, Golden Globes, BAFTA, DGA, PGA, SAG, Critics Choice
```

**Co-nominated people on a single nomination** — the exact problem the junction table was built to solve:

```
Best Director | Everything Everywhere All at Once | 2022 | Daniel Kwan, Daniel Scheinert
Best Original Screenplay | Parasite | 2020 | Bong Joon-ho, Han Jin-won
```

**People nominated across the most distinct award shows:**

```
Daniel Day-Lewis  | 5 distinct shows | 16 total nominations
Cate Blanchett    | 5 distinct shows | 15 total nominations
```

## Project structure

```
awards-database/
├── sql/
│   ├── schema.sql              # Table definitions, keys, indexes
│   └── analysis_queries.sql    # Annotated example queries + sample output
├── data/                       # Source CSVs (seed data)
└── awards.db                   # Built SQLite database
```

## Running it

```bash
sqlite3 awards.db < sql/schema.sql
# then load data/*.csv into their matching tables, or use the prebuilt awards.db directly
sqlite3 awards.db < sql/analysis_queries.sql
```# filmAwardAnalysis
