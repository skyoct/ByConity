CREATE DATABASE IF NOT EXISTS test;

USE test;

DROP TABLE IF EXISTS t40090;

CREATE TABLE t40090
(
    `a` Int32,
    `b` Int32 DEFAULT 2,
    `c` Int32 MATERIALIZED 3,
    `d` Int32 ALIAS 4
) ENGINE = CnchMergeTree() ORDER BY tuple();

INSERT INTO t40090(*) SELECT 1, 2;

SELECT a, b, c, d FROM t40090;

DROP TABLE IF EXISTS t40090;
