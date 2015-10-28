-- https://developer.github.com/v3/repos/releases/

DROP TABLE IF EXISTS releases;

CREATE TABLE releases (
    org VARCHAR,
    repo VARCHAR,
    id VARCHAR,
    html_url VARCHAR,
    tarball_url VARCHAR,
    zipball_url VARCHAR,
    tag_name VARCHAR,
    name VARCHAR,
    body VARCHAR,
    created_at TIMESTAMP,
    published_at TIMESTAMP,
    author VARCHAR
);

-- TODO: Include each file and its download count?
