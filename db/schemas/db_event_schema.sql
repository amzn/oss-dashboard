DROP TABLE IF EXISTS events;

CREATE TABLE events (
    id VARCHAR,
    type VARCHAR,
    actor VARCHAR,
    org VARCHAR,
    repo VARCHAR,
    public VARCHAR,
    created_at TIMESTAMP,
    payload VARCHAR
);
