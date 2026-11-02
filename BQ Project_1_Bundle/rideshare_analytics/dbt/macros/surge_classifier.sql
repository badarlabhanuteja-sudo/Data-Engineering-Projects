{% macro classify_surge(surge_col) %}
    case
        when {{ surge_col }} < 1.2 then 'normal'
        when {{ surge_col }} < 1.5 then 'mild'
        when {{ surge_col }} < {{ var('surge_threshold_high') }} then 'elevated'
        when {{ surge_col }} < 3.0 then 'high'
        else 'extreme'
    end
{% endmacro %}
