{% macro safe_divide(numerator, denominator) %}
    CASE WHEN {{ denominator }} = 0 OR {{ denominator }} IS NULL
         THEN NULL
         ELSE SAFE_DIVIDE(CAST({{ numerator }} AS FLOAT64), CAST({{ denominator }} AS FLOAT64))
    END
{% endmacro %}

{% macro create_run_history_table_if_not_exists() %}
    {# Disabled: DML not available on BigQuery free tier #}
{% endmacro %}

{% macro insert_run_history_row(results) %}
    {# Disabled: DML not available on BigQuery free tier #}
{% endmacro %}
