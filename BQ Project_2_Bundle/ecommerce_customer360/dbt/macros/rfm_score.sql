{#--
   rfm_score
   ----------
   Returns a SQL expression that produces an integer 1..N (default 5) RFM score
   for the given column, based on quintile binning over the input set.

   For Recency: lower days_since_last_order = better, so we invert the bin order.
   For Frequency / Monetary: higher = better.
--#}

{% macro rfm_quintile(column, ascending=true, n_bins=None) %}
    {% set n = n_bins or var('rfm_n_bins') %}
    {% if ascending %}
        ntile({{ n }}) over (order by {{ column }})
    {% else %}
        ntile({{ n }}) over (order by {{ column }} desc)
    {% endif %}
{% endmacro %}


{#-- Combined R-F-M-score → segment label using the canonical Hughes 5x5x5 scheme --#}
{% macro rfm_segment_label(r_col, f_col, m_col) %}
    case
        when {{ r_col }} >= 4 and {{ f_col }} >= 4 and {{ m_col }} >= 4 then 'Champions'
        when {{ r_col }} >= 3 and {{ f_col }} >= 3 and {{ m_col }} >= 3 then 'Loyal'
        when {{ r_col }} >= 4 and {{ f_col }} <= 2                       then 'Potential Loyalists'
        when {{ r_col }} >= 4 and {{ f_col }} = 3                        then 'New Customers'
        when {{ r_col }} = 3 and {{ f_col }} <= 2                        then 'Promising'
        when {{ r_col }} = 2 and {{ f_col }} >= 4                        then 'At Risk'
        when {{ r_col }} <= 2 and {{ f_col }} >= 4 and {{ m_col }} >= 4 then 'Cannot Lose Them'
        when {{ r_col }} <= 2 and {{ f_col }} <= 2 and {{ m_col }} >= 3 then 'Hibernating'
        when {{ r_col }} = 1 and {{ f_col }} = 1                         then 'Lost'
        else 'About to Sleep'
    end
{% endmacro %}
