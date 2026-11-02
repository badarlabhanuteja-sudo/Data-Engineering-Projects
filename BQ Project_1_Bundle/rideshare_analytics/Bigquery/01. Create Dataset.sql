-- Run each line separately in BigQuery console

CREATE SCHEMA IF NOT EXISTS `your-project-id.raw`
OPTIONS (location = 'US');

CREATE SCHEMA IF NOT EXISTS `your-project-id.staging`
OPTIONS (location = 'US');

CREATE SCHEMA IF NOT EXISTS `your-project-id.intermediate`
OPTIONS (location = 'US');

CREATE SCHEMA IF NOT EXISTS `your-project-id.marts`
OPTIONS (location = 'US');

CREATE SCHEMA IF NOT EXISTS `your-project-id.snapshots`
OPTIONS (location = 'US');

CREATE SCHEMA IF NOT EXISTS `your-project-id.seeds`
OPTIONS (location = 'US');

CREATE SCHEMA IF NOT EXISTS `your-project-id.meta`
OPTIONS (location = 'US');

CREATE SCHEMA IF NOT EXISTS `your-project-id.streams_dt`
OPTIONS (location = 'US');