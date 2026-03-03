-- Books & Authors Database Schema

CREATE TABLE IF NOT EXISTS authors (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(150) NOT NULL,
    bio         TEXT,
    nationality VARCHAR(100),
    born_year   INT,
    created_at  TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS books (
    id            SERIAL PRIMARY KEY,
    title         VARCHAR(255) NOT NULL,
    author_id     INT NOT NULL REFERENCES authors(id) ON DELETE CASCADE,
    genre         VARCHAR(100),
    published_year INT,
    isbn          VARCHAR(20) UNIQUE,
    description   TEXT,
    created_at    TIMESTAMP DEFAULT NOW()
);
