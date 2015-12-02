DROP TABLE IF EXISTS items;

CREATE TABLE items (
    id VARCHAR,
    item_number VARCHAR,
    assignee_login VARCHAR,
    user_login VARCHAR,
    state VARCHAR,
    title VARCHAR,
    body VARCHAR,
    org VARCHAR,
    repo VARCHAR,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    comment_count VARCHAR,
    pull_request_url VARCHAR,   -- PR only
    merged_at TIMESTAMP,   -- PR only
    closed_at TIMESTAMP
);

-- TODO: Create index on pull_request

DROP VIEW IF EXISTS issues;

CREATE VIEW issues AS
SELECT id, item_number AS issue_number, assignee_login, user_login, state, 
       title, body, org, repo, created_at, updated_at, comment_count, closed_at
FROM items
WHERE pull_request_url IS NULL;

DROP VIEW IF EXISTS pull_requests;

CREATE VIEW pull_requests AS
SELECT id, item_number AS pr_number, assignee_login, user_login, state, 
       title, body, org, repo, created_at, updated_at, comment_count, closed_at,
       pull_request_url, merged_at
FROM items
WHERE pull_request_url IS NOT NULL;


DROP TABLE IF EXISTS pull_request_files;

CREATE TABLE pull_request_files (
    pull_request_id VARCHAR,
    filename VARCHAR,
    additions INTEGER,
    deletions INTEGER,
    changes INTEGER,
    status VARCHAR
);

DROP TABLE IF EXISTS labels;

CREATE TABLE labels (
  orgrepo VARCHAR,
  url VARCHAR,
  name VARCHAR,
  color VARCHAR
);

DROP TABLE IF EXISTS item_to_label;

CREATE TABLE item_to_label (
  item_id INTEGER,
  url VARCHAR
);

DROP TABLE IF EXISTS milestones;

CREATE TABLE milestones (
  orgrepo VARCHAR,
  id INTEGER,
  html_url VARCHAR,
  title VARCHAR,
  state VARCHAR,
  number INTEGER,
  description VARCHAR,
  creator INTEGER,
  open_issues INTEGER,
  closed_issues INTEGER,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  closed_at TIMESTAMP,
  due_on TIMESTAMP
);

DROP TABLE IF EXISTS item_to_milestone;

CREATE TABLE item_to_milestone (
  item_id INTEGER,
  milestone_id INTEGER
);

DROP TABLE IF EXISTS item_comments;

CREATE TABLE item_comments (
  id INTEGER,
  org VARCHAR,
  repo VARCHAR,
  item_number INTEGER,
  body VARCHAR,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
