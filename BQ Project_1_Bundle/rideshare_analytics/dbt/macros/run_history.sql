{% macro create_run_history_table_if_not_exists() %}
    {% set sql %}
        CREATE TABLE IF NOT EXISTS `{{ env_var('GCP_PROJECT_ID') }}.meta.dbt_run_history` (
            invocation_id       STRING,
            run_started_at      TIMESTAMP,
            run_completed_at    TIMESTAMP,
            target_name         STRING,
            command             STRING,
            status              STRING,
            num_models_total    INT64,
            num_models_pass     INT64,
            num_models_fail     INT64,
            num_models_warn     INT64,
            execution_time_s    NUMERIC
        )
    {% endset %}
    {% if execute %}
        {% do run_query(sql) %}
    {% endif %}
{% endmacro %}


{% macro insert_run_history_row(results) %}
    {% if execute %}
        {% set total = results | length %}
        {% set passes = results | selectattr('status', 'equalto', 'success') | list | length %}
        {% set fails  = results | selectattr('status', 'equalto', 'error')   | list | length %}
        {% set warns  = results | selectattr('status', 'equalto', 'warn')    | list | length %}
        {% set elapsed = results | sum(attribute='execution_time') %}
        {% set sql %}
            INSERT INTO `{{ env_var('GCP_PROJECT_ID') }}.meta.dbt_run_history`
              (invocation_id, run_started_at, run_completed_at, target_name,
               command, status, num_models_total, num_models_pass,
               num_models_fail, num_models_warn, execution_time_s)
            VALUES (
              '{{ invocation_id }}',
              '{{ run_started_at }}',
              CURRENT_TIMESTAMP(),
              '{{ target.name }}',
              '{{ flags.WHICH }}',
              CASE WHEN {{ fails }} > 0 THEN 'error'
                   WHEN {{ warns }} > 0 THEN 'warn'
                   ELSE 'success' END,
              {{ total }}, {{ passes }}, {{ fails }}, {{ warns }},
              {{ elapsed | round(3) }}
            )
        {% endset %}
        {% do run_query(sql) %}
    {% endif %}
{% endmacro %}