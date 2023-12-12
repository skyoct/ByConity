create database if not exists ci_ssb;
drop table if exists ci_ssb.lineorder;
drop table if exists ci_ssb.customer;
drop table if exists ci_ssb.part;
drop table if exists ci_ssb.dates;
drop table if exists ci_ssb.lineorder_flat;
drop table if exists ci_ssb.supplier;

-- CREATE TABLE ci_ssb.lineorder (`LO_ORDERKEY` UInt32, `LO_LINENUMBER` UInt8, `LO_CUSTKEY` UInt32, `LO_PARTKEY` UInt32, `LO_SUPPKEY` UInt32, `LO_ORDERDATE` Date, `LO_ORDERPRIORITY` LowCardinality(String), `LO_SHIPPRIORITY` UInt8, `LO_QUANTITY` UInt8, `LO_EXTENDEDPRICE` UInt32, `LO_ORDTOTALPRICE` UInt32, `LO_DISCOUNT` UInt8, `LO_REVENUE` UInt32, `LO_SUPPLYCOST` UInt32, `LO_TAX` UInt8, `LO_COMMITDATE` UInt32, `LO_SHIPMODE` LowCardinality(String)) ENGINE = CnchMergeTree ORDER BY (LO_ORDERDATE, LO_ORDERKEY) SETTINGS index_granularity = 8192;

CREATE TABLE ci_ssb.lineorder
(
    LO_ORDERKEY             UInt32,
    LO_LINENUMBER           UInt8,
    LO_CUSTKEY              UInt32,
    LO_PARTKEY              UInt32,
    LO_SUPPKEY              UInt32,
    LO_ORDERDATE            Date,
    LO_ORDERPRIORITY        LowCardinality(String),
    LO_SHIPPRIORITY         UInt8,
    LO_QUANTITY             UInt8,
    LO_EXTENDEDPRICE        UInt32,
    LO_ORDTOTALPRICE        UInt32,
    LO_DISCOUNT             UInt8,
    LO_REVENUE              UInt32,
    LO_SUPPLYCOST           UInt32,
    LO_TAX                  UInt8,
    LO_COMMITDATE           Date,
    LO_SHIPMODE             LowCardinality(String)
)
ENGINE = CnchMergeTree PARTITION BY toYear(LO_ORDERDATE) ORDER BY (LO_ORDERDATE, LO_ORDERKEY);

CREATE TABLE ci_ssb.customer (`C_CUSTKEY` UInt32, `C_NAME` String, `C_ADDRESS` String, `C_CITY` LowCardinality(String), `C_NATION` LowCardinality(String), `C_REGION` LowCardinality(String), `C_PHONE` FixedString(15), `C_MKTSEGMENT` LowCardinality(String)) ENGINE = CnchMergeTree ORDER BY C_CUSTKEY SETTINGS index_granularity = 8192;

CREATE TABLE ci_ssb.part (`P_PARTKEY` UInt32, `P_NAME` String, `P_MFGR` LowCardinality(String), `P_CATEGORY` LowCardinality(String), `P_BRAND` LowCardinality(String), `P_COLOR` LowCardinality(String), `P_TYPE` LowCardinality(String), `P_SIZE` UInt8, `P_CONTAINER` LowCardinality(String)) ENGINE = CnchMergeTree ORDER BY P_PARTKEY SETTINGS index_granularity = 8192;

CREATE TABLE ci_ssb.dates (`D_DATEKEY` Date, `D_DATE` String, `D_DAYOFWEEK` String, `D_MONTH` String, `D_YEAR` UInt32, `D_YEARMONTHNUM` UInt32, `D_YEARMONTH` String, `D_DAYNUMINWEEK` UInt32, `D_DAYNUMINMONTH` UInt32, `D_DAYNUMINYEAR` UInt32, `D_MONTHNUMINYEAR` UInt32, `D_WEEKNUMINYEAR` UInt32, `D_SELLINGSEASON` String, `D_LASTDAYINWEEKFL` UInt32, `D_LASTDAYINMONTHFL` UInt32, `D_HOLIDAYFL` UInt32, `D_WEEKDAYFL` UInt32) ENGINE = CnchMergeTree ORDER BY D_DATEKEY SETTINGS index_granularity = 8192;

CREATE TABLE ci_ssb.lineorder_flat (`LO_ORDERKEY` UInt32, `LO_LINENUMBER` UInt8, `LO_CUSTKEY` UInt32, `LO_PARTKEY` UInt32, `LO_SUPPKEY` UInt32, `LO_ORDERDATE` UInt32, `LO_ORDERPRIORITY` LowCardinality(String), `LO_SHIPPRIORITY` UInt8, `LO_QUANTITY` UInt8, `LO_EXTENDEDPRICE` UInt32, `LO_ORDTOTALPRICE` UInt32, `LO_DISCOUNT` UInt8, `LO_REVENUE` UInt32, `LO_SUPPLYCOST` UInt32, `LO_TAX` UInt8, `LO_COMMITDATE` UInt32, `LO_SHIPMODE` LowCardinality(String), `C_NAME` String, `C_ADDRESS` String, `C_CITY` LowCardinality(String), `C_NATION` LowCardinality(String), `C_REGION` LowCardinality(String), `C_PHONE` FixedString(15), `C_MKTSEGMENT` LowCardinality(String), `S_NAME` String, `S_ADDRESS` String, `S_CITY` LowCardinality(String), `S_NATION` LowCardinality(String), `S_REGION` LowCardinality(String), `S_PHONE` String, `P_NAME` String, `P_MFGR` LowCardinality(String), `P_CATEGORY` LowCardinality(String), `P_BRAND` LowCardinality(String), `P_COLOR` LowCardinality(String), `P_TYPE` LowCardinality(String), `P_SIZE` UInt8, `P_CONTAINER` LowCardinality(String)) ENGINE = CnchMergeTree PARTITION BY toInt64(LO_ORDERDATE / 10000) ORDER BY (LO_ORDERDATE, LO_ORDERKEY) SETTINGS index_granularity = 8192;

CREATE TABLE ci_ssb.supplier (`S_SUPPKEY` UInt32, `S_NAME` String, `S_ADDRESS` String, `S_CITY` LowCardinality(String), `S_NATION` LowCardinality(String), `S_REGION` LowCardinality(String), `S_PHONE` String) ENGINE = CnchMergeTree ORDER BY S_SUPPKEY SETTINGS index_granularity = 8192;

use ci_ssb;
set enable_distributed_stages = 1;
set exchange_enable_force_remote_mode = 1;

--Q1.1
SELECT SUM(LO_EXTENDEDPRICE * LO_DISCOUNT) AS REVENUE
FROM lineorder_flat
WHERE LO_ORDERDATE >= 19930101 AND LO_ORDERDATE <= 19931231 AND LO_DISCOUNT BETWEEN 1 AND 3 AND LO_QUANTITY < 25;

SELECT SUM(LO_EXTENDEDPRICE * LO_DISCOUNT) AS REVENUE
FROM lineorder
WHERE LO_ORDERDATE >= '1993-01-01' AND LO_ORDERDATE <= '1993-12-31' AND LO_DISCOUNT BETWEEN 1 AND 3 AND LO_QUANTITY < 25;

SELECT count() AS REVENUE
FROM lineorder
WHERE LO_ORDERDATE >= '1993-01-01' AND LO_ORDERDATE <= '1993-12-31' AND LO_DISCOUNT BETWEEN 1 AND 3 AND LO_QUANTITY < 25 settings enable_distributed_stages = 1;

SELECT SUM(LO_EXTENDEDPRICE * LO_DISCOUNT) AS REVENUE FROM lineorder_flat WHERE LO_ORDERDATE >= 19940101 AND LO_ORDERDATE <= 19940131 AND LO_DISCOUNT BETWEEN 4 AND 6 AND LO_QUANTITY BETWEEN 26 AND 35;

--Q1.3
SELECT SUM(LO_EXTENDEDPRICE * LO_DISCOUNT) AS REVENUE
FROM lineorder_flat
WHERE toWeek(toDate(LO_ORDERDATE)) = 6 AND LO_ORDERDATE >= 19940101 AND LO_ORDERDATE <= 19941231
  AND LO_DISCOUNT BETWEEN 5 AND 7 AND LO_QUANTITY BETWEEN 26 AND 35;

--Q2.1
SELECT
    SUM(LO_REVENUE),
    (LO_ORDERDATE / 10000) AS YEAR,
    P_BRAND
FROM lineorder_flat
WHERE P_CATEGORY = 'MFGR#12' AND S_REGION = 'AMERICA'
GROUP BY
    YEAR,
    P_BRAND
ORDER BY
    YEAR,
    P_BRAND;

--Q2.2
SELECT
    SUM(LO_REVENUE),
    (LO_ORDERDATE / 10000) AS YEAR,
    P_BRAND
FROM lineorder_flat
WHERE P_BRAND >= 'MFGR#2221' AND P_BRAND <= 'MFGR#2228' AND S_REGION = 'ASIA'
GROUP BY
    YEAR,
    P_BRAND
ORDER BY
    YEAR,
    P_BRAND;

--Q2.3
SELECT
    SUM(LO_REVENUE),
    (LO_ORDERDATE / 10000) AS YEAR,
    P_BRAND
FROM lineorder_flat
WHERE P_BRAND = 'MFGR#2239' AND S_REGION = 'EUROPE'
GROUP BY
    YEAR,
    P_BRAND
ORDER BY
    YEAR,
    P_BRAND;

--Q3.1
SELECT
    C_NATION,
    S_NATION,
    (LO_ORDERDATE / 10000) AS YEAR,
    SUM(LO_REVENUE) AS REVENUE
FROM lineorder_flat
WHERE C_REGION = 'ASIA' AND S_REGION = 'ASIA' AND LO_ORDERDATE  >= 19920101 AND LO_ORDERDATE   <= 19971231
GROUP BY
    C_NATION,
    S_NATION,
    YEAR
ORDER BY
    YEAR ASC,
    REVENUE DESC;

--Q3.2
SELECT
    C_CITY,
    S_CITY,
    (LO_ORDERDATE / 10000) AS YEAR,
    SUM(LO_REVENUE) AS REVENUE
FROM lineorder_flat
WHERE C_NATION = 'UNITED STATES' AND S_NATION = 'UNITED STATES' AND LO_ORDERDATE  >= 19920101 AND LO_ORDERDATE <= 19971231
GROUP BY
    C_CITY,
    S_CITY,
    YEAR
ORDER BY
    YEAR ASC,
    REVENUE DESC;

--Q3.3
SELECT
    C_CITY,
    S_CITY,
    (LO_ORDERDATE / 10000) AS YEAR,
    SUM(LO_REVENUE) AS REVENUE
FROM lineorder_flat
WHERE C_CITY IN ( 'UNITED KI1' ,'UNITED KI5') AND S_CITY IN ( 'UNITED KI1' ,'UNITED KI5') AND LO_ORDERDATE  >= 19920101 AND LO_ORDERDATE <= 19971231
GROUP BY
    C_CITY,
    S_CITY,
    YEAR
ORDER BY
    YEAR ASC,
    REVENUE DESC;

--Q3.4
SELECT
    C_CITY,
    S_CITY,
    (LO_ORDERDATE / 10000) AS YEAR,
    SUM(LO_REVENUE) AS REVENUE
FROM lineorder_flat
WHERE C_CITY IN ('UNITED KI1', 'UNITED KI5') AND S_CITY IN ( 'UNITED KI1',  'UNITED KI5') AND  LO_ORDERDATE  >= 19971201 AND LO_ORDERDATE <= 19971231
GROUP BY
    C_CITY,
    S_CITY,
    YEAR
ORDER BY
    YEAR ASC,
    REVENUE DESC;

--Q4.1
SELECT
   (LO_ORDERDATE / 10000) AS YEAR,
    C_NATION,
    SUM(LO_REVENUE - LO_SUPPLYCOST) AS PROFIT
FROM lineorder_flat
WHERE C_REGION = 'AMERICA' AND S_REGION = 'AMERICA' AND P_MFGR IN ( 'MFGR#1' , 'MFGR#2')
GROUP BY
    YEAR,
    C_NATION
ORDER BY
    YEAR ASC,
    C_NATION ASC;

--Q4.2
SELECT
   (LO_ORDERDATE / 10000) AS YEAR,
    S_NATION,
    P_CATEGORY,
    SUM(LO_REVENUE - LO_SUPPLYCOST) AS PROFIT
FROM lineorder_flat
WHERE C_REGION = 'AMERICA' AND S_REGION = 'AMERICA' AND LO_ORDERDATE >= 19970101 AND LO_ORDERDATE <= 19981231 AND  P_MFGR IN ( 'MFGR#1' , 'MFGR#2')
GROUP BY
    YEAR,
    S_NATION,
    P_CATEGORY
ORDER BY
    YEAR ASC,
    S_NATION ASC,
    P_CATEGORY ASC;

--Q4.3
SELECT
    (LO_ORDERDATE / 10000) AS YEAR,
    S_CITY,
    P_BRAND,
    SUM(LO_REVENUE - LO_SUPPLYCOST) AS PROFIT
FROM lineorder_flat
WHERE S_NATION = 'UNITED STATES' AND LO_ORDERDATE >= 19970101 AND LO_ORDERDATE <= 19981231 AND P_CATEGORY = 'MFGR#14'
GROUP BY
    YEAR,
    S_CITY,
    P_BRAND
ORDER BY
    YEAR ASC,
    S_CITY ASC,
    P_BRAND ASC;



-- JOIN
SELECT 'JOIN';

--Q1.1
SELECT SUM(LO_REVENUE) AS REVENUE
FROM ci_ssb.lineorder JOIN ci_ssb.dates ON LO_ORDERDATE = D_DATEKEY
WHERE D_YEAR = 1993 AND LO_DISCOUNT BETWEEN 1 AND 3 AND LO_QUANTITY < 25;

--Q1.2
SELECT SUM(LO_REVENUE) AS REVENUE
FROM ci_ssb.lineorder
JOIN ci_ssb.dates ON LO_ORDERDATE = D_DATEKEY
WHERE D_YEARMONTHNUM = 199401
AND LO_DISCOUNT BETWEEN 4 AND 6
AND LO_QUANTITY BETWEEN 26 AND 35;

--Q1.3
SELECT SUM(LO_REVENUE) AS REVENUE
FROM ci_ssb.lineorder
JOIN ci_ssb.dates ON LO_ORDERDATE = D_DATEKEY
WHERE D_WEEKNUMINYEAR = 6 AND D_YEAR = 1994
AND LO_DISCOUNT BETWEEN 5 AND 7
AND LO_QUANTITY BETWEEN 26 AND 35;

--Q2.1
SELECT SUM(LO_REVENUE) AS LO_REVENUE, D_YEAR, P_BRAND
FROM ci_ssb.lineorder
JOIN ci_ssb.dates ON LO_ORDERDATE = D_DATEKEY
JOIN ci_ssb.part ON LO_PARTKEY = P_PARTKEY
JOIN ci_ssb.supplier ON LO_SUPPKEY = S_SUPPKEY
WHERE P_CATEGORY = 'MFGR#12' AND S_REGION = 'AMERICA'
GROUP BY D_YEAR, P_BRAND
ORDER BY D_YEAR, P_BRAND;

--Q2.2
SELECT SUM(LO_REVENUE) AS LO_REVENUE, D_YEAR, P_BRAND
FROM ci_ssb.lineorder
JOIN ci_ssb.dates ON LO_ORDERDATE = D_DATEKEY
JOIN ci_ssb.part ON LO_PARTKEY = P_PARTKEY
JOIN ci_ssb.supplier ON LO_SUPPKEY = S_SUPPKEY
WHERE P_BRAND BETWEEN 'MFGR#2221' AND 'MFGR#2228' AND S_REGION = 'ASIA'
GROUP BY D_YEAR, P_BRAND
ORDER BY D_YEAR, P_BRAND;

--Q2.3
SELECT SUM(LO_REVENUE) AS LO_REVENUE, D_YEAR, P_BRAND
FROM ci_ssb.lineorder
JOIN ci_ssb.dates ON LO_ORDERDATE = D_DATEKEY
JOIN ci_ssb.part ON LO_PARTKEY = P_PARTKEY
JOIN ci_ssb.supplier ON LO_SUPPKEY = S_SUPPKEY
WHERE P_BRAND = 'MFGR#2239' AND S_REGION = 'EUROPE'
GROUP BY D_YEAR, P_BRAND
ORDER BY D_YEAR, P_BRAND;

--Q3.1
SELECT C_NATION, S_NATION, D_YEAR, SUM(LO_REVENUE) AS LO_REVENUE
FROM ci_ssb.lineorder
JOIN ci_ssb.dates ON LO_ORDERDATE = D_DATEKEY
JOIN ci_ssb.customer ON LO_CUSTKEY = C_CUSTKEY
JOIN ci_ssb.supplier ON LO_SUPPKEY = S_SUPPKEY
WHERE C_REGION = 'ASIA' AND S_REGION = 'ASIA'AND D_YEAR >= 1992 AND D_YEAR <= 1997
GROUP BY C_NATION, S_NATION, D_YEAR
ORDER BY D_YEAR ASC, LO_REVENUE DESC;

--Q3.2
SELECT C_CITY, S_CITY, D_YEAR, SUM(LO_REVENUE) AS LO_REVENUE
FROM ci_ssb.lineorder
JOIN ci_ssb.dates ON LO_ORDERDATE = D_DATEKEY
JOIN ci_ssb.customer ON LO_CUSTKEY = C_CUSTKEY
JOIN ci_ssb.supplier ON LO_SUPPKEY = S_SUPPKEY
WHERE C_NATION = 'UNITED STATES' AND S_NATION = 'UNITED STATES'
AND D_YEAR >= 1992 AND D_YEAR <= 1997
GROUP BY C_CITY, S_CITY, D_YEAR
ORDER BY D_YEAR ASC, LO_REVENUE DESC;

--Q3.3
SELECT C_CITY, S_CITY, D_YEAR, SUM(LO_REVENUE) AS LO_REVENUE
FROM ci_ssb.lineorder
JOIN ci_ssb.dates ON LO_ORDERDATE = D_DATEKEY
JOIN ci_ssb.customer ON LO_CUSTKEY = C_CUSTKEY
JOIN ci_ssb.supplier ON LO_SUPPKEY = S_SUPPKEY
WHERE (C_CITY='UNITED KI1' OR C_CITY='UNITED KI5')
AND (S_CITY='UNITED KI1' OR S_CITY='UNITED KI5')
AND D_YEAR >= 1992 AND D_YEAR <= 1997
GROUP BY C_CITY, S_CITY, D_YEAR
ORDER BY D_YEAR ASC, LO_REVENUE DESC;

--Q3.4
SELECT C_CITY, S_CITY, D_YEAR, SUM(LO_REVENUE) AS LO_REVENUE
FROM ci_ssb.lineorder
JOIN ci_ssb.dates ON LO_ORDERDATE = D_DATEKEY
JOIN ci_ssb.customer ON LO_CUSTKEY = C_CUSTKEY
JOIN ci_ssb.supplier ON LO_SUPPKEY = S_SUPPKEY
WHERE (C_CITY='UNITED KI1' OR C_CITY='UNITED KI5') AND (S_CITY='UNITED KI1' OR S_CITY='UNITED KI5') AND D_YEARMONTH = 'DEC1997'
GROUP BY C_CITY, S_CITY, D_YEAR
ORDER BY D_YEAR ASC, LO_REVENUE DESC;

--Q4.1
SELECT D_YEAR, C_NATION, SUM(LO_REVENUE) - SUM(LO_SUPPLYCOST) AS PROFIT
FROM ci_ssb.lineorder
JOIN ci_ssb.dates ON LO_ORDERDATE = D_DATEKEY
JOIN ci_ssb.customer ON LO_CUSTKEY = C_CUSTKEY
JOIN ci_ssb.supplier ON LO_SUPPKEY = S_SUPPKEY
JOIN ci_ssb.part ON LO_PARTKEY = P_PARTKEY
WHERE C_REGION = 'AMERICA' AND S_REGION = 'AMERICA' AND (P_MFGR = 'MFGR#1' OR P_MFGR = 'MFGR#2')
GROUP BY D_YEAR, C_NATION
ORDER BY D_YEAR, C_NATION;

--Q4.2
SELECT D_YEAR, S_NATION, P_CATEGORY, SUM(LO_REVENUE) - SUM(LO_SUPPLYCOST) AS PROFIT
FROM ci_ssb.lineorder
JOIN ci_ssb.dates ON LO_ORDERDATE = D_DATEKEY
JOIN ci_ssb.customer ON LO_CUSTKEY = C_CUSTKEY
JOIN ci_ssb.supplier ON LO_SUPPKEY = S_SUPPKEY
JOIN ci_ssb.part ON LO_PARTKEY = P_PARTKEY
WHERE C_REGION = 'AMERICA'AND S_REGION = 'AMERICA'
AND (D_YEAR = 1997 OR D_YEAR = 1998)
AND (P_MFGR = 'MFGR#1' OR P_MFGR = 'MFGR#2')
GROUP BY D_YEAR, S_NATION, P_CATEGORY
ORDER BY D_YEAR, S_NATION, P_CATEGORY;

--Q4.3
SELECT D_YEAR, S_CITY, P_BRAND, SUM(LO_REVENUE) - SUM(LO_SUPPLYCOST) AS PROFIT
FROM ci_ssb.lineorder
JOIN ci_ssb.dates ON LO_ORDERDATE = D_DATEKEY
JOIN ci_ssb.customer ON LO_CUSTKEY = C_CUSTKEY
JOIN ci_ssb.supplier ON LO_SUPPKEY = S_SUPPKEY
JOIN ci_ssb.part ON LO_PARTKEY = P_PARTKEY
WHERE C_REGION = 'AMERICA'AND S_NATION = 'UNITED STATES'
AND (D_YEAR = 1997 OR D_YEAR = 1998)
AND P_CATEGORY = 'MFGR#14'
GROUP BY D_YEAR, S_CITY, P_BRAND
ORDER BY D_YEAR, S_CITY, P_BRAND;

drop table if exists ci_ssb.lineorder;
drop table if exists ci_ssb.customer;
drop table if exists ci_ssb.part;
drop table if exists ci_ssb.dates;
drop table if exists ci_ssb.lineorder_flat;
drop table if exists ci_ssb.supplier;