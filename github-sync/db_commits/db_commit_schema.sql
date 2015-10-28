DROP TABLE IF EXISTS commits;

CREATE TABLE commits (
    sha VARCHAR,
    message VARCHAR,
    tree VARCHAR,
    org VARCHAR,
    repo VARCHAR,
    author VARCHAR,
    authored_at TIMESTAMP,
    committer VARCHAR,
    committed_at TIMESTAMP,
    comment_count INTEGER
);
