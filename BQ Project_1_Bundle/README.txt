========================================================================
Project 1 — Real-Time Ride-Sharing Analytics Platform
MSc Computer Science Capstone — Complete Bundle
========================================================================

This bundle contains three files:

  1. Project_1_Overview_TechStack.docx   (~22 KB)
     The "what" — design intent, architecture, schemas, dbt structure,
     Snowflake Streams + Tasks + Dynamic Tables, Airflow DAGs,
     dissertation research angle, 12-week timeline.
     READ THIS FIRST.

  2. Project_1_Execution_Guide.docx       (~19 KB)
     The "do" — phase-by-phase setup, run, validate, troubleshoot.
     12 sections including 12 troubleshooting entries.
     READ THIS SECOND, while executing the steps.

  3. Project_1_Codebase.zip                (~70 KB, 69 files)
     The "how" — complete working codebase. Extract and follow
     Project_1_Execution_Guide.docx step by step.

------------------------------------------------------------------------
Stack: BigQuery (Materialized Views) + dbt Core + Apache Airflow + Docker + Python

Empirical research angle: dbt incremental models (BASELINE, 5-minute Airflow refresh) versus BigQuery Materialized Views (INTERVENTION, 1-minute automatic refresh).
20 paired runs measured on freshness lag, bytes processed, slot consumption, and processing time.
------------------------------------------------------------------------

Quick start:
  1. Extract Project_1_Codebase.zip
  2. cd rideshare_analytics
  3. Open Project_1_Execution_Guide.docx
  4. Follow Phase 0 → Phase 8 in order
  5. ~2 hours from clean machine to dissertation results
