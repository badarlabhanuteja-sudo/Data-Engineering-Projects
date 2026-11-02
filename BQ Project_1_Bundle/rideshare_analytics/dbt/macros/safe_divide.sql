{% macro safe_divide(numerator, denominator) %}
    SAFE_DIVIDE(CAST({{ numerator }} AS FLOAT64), CAST({{ denominator }} AS FLOAT64))
{% endmacro %}
