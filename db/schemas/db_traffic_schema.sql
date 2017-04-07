DROP TABLE IF EXISTS traffic_referrers;

-- Get the top 10 referrers over the last 14 days.
CREATE TABLE traffic_referrers (
  org VARCHAR,
  repo VARCHAR,
  referrer VARCHAR,
  count INTEGER,
  uniques INTEGER,
  recorded_at TIMESTAMP
);

DROP TABLE IF EXISTS traffic_popular_paths;

-- Get the top 10 popular contents over the last 14 days.
CREATE TABLE traffic_popular_paths (
  org VARCHAR,
  repo VARCHAR,
  path VARCHAR,
  title VARCHAR,
  count INTEGER,
  uniques INTEGER,
  recorded_at TIMESTAMP
);

DROP TABLE IF EXISTS traffic_views_total;

CREATE TABLE traffic_views_total (
  org VARCHAR,
  repo VARCHAR,
  count INTEGER,
  uniques INTEGER,
  recorded_at TIMESTAMP
);

DROP TABLE IF EXISTS traffic_views_daily;

CREATE TABLE traffic_views_daily (
  org VARCHAR,
  repo VARCHAR,
  count INTEGER,
  uniques INTEGER,
  timestamp TIMESTAMP
);

DROP TABLE IF EXISTS traffic_clones_total;

CREATE TABLE traffic_clones_total (
  org VARCHAR,
  repo VARCHAR,
  count INTEGER,
  uniques INTEGER,
  recorded_at TIMESTAMP
);

DROP TABLE IF EXISTS traffic_clones_daily;

CREATE TABLE traffic_clones_daily (
  org VARCHAR,
  repo VARCHAR,
  count INTEGER,
  uniques INTEGER,
  timestamp TIMESTAMP
);

