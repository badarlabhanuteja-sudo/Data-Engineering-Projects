{% macro safe_divide(numerator, denominator) %}
    case when {{ denominator }} = 0 or {{ denominator }} is null
         then null
         else SAFE_DIVIDE(CAST({{ numerator }} AS FLOAT64), CAST({{ denominator }} AS FLOAT64))
    end
{% endmacro %}
