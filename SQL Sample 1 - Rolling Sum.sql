----QUERIES FOR ROLLING SERVICES FLAGS----

----FULL QUERY (LONG)
WITH z AS (
			----FULL CTE (INNER QUERY)
			SELECT
			    x.account_name,
			    x.reporting_services_geo,
			    DATE_TRUNC('quarter',x.opportunity_close_date) outter_q,
			    DATEADD(QUARTER,-3,DATE_TRUNC('quarter',x.opportunity_close_date)) bound_q,
			    y.inner_q,
			    y.inner_q_gls,
			    y.inner_q_gps,
			    y.inner_q_tam,
			    SUM(CASE WHEN x.product_forecast_group = 'TRAINING' THEN x.syb_amount_usd_cy_pr ELSE 0 END) outter_q_gls,
			    SUM(CASE WHEN x.product_forecast_group = 'CONSULTING' THEN x.syb_amount_usd_cy_pr ELSE 0 END) outter_q_gps,
			    SUM(CASE WHEN UPPER(x.product_line) LIKE '%TAM%' THEN x.syb_amount_usd_cy_pr ELSE 0 END) outter_q_tam
			FROM bf_ard.core_global_historical_bookings_pipeline x
			LEFT JOIN
			----INNERMOST SUBQUERY----
			(SELECT
				account_name,
				reporting_services_geo,
				DATE_TRUNC('quarter',opportunity_close_date) inner_q,
				SUM(CASE WHEN product_forecast_group = 'TRAINING' THEN syb_amount_usd_cy_pr ELSE 0 END) inner_q_gls,
			    SUM(CASE WHEN product_forecast_group = 'CONSULTING' THEN syb_amount_usd_cy_pr ELSE 0 END) inner_q_gps,
			    SUM(CASE WHEN UPPER(product_line) LIKE '%TAM%' THEN syb_amount_usd_cy_pr ELSE 0 END) inner_q_tam
			FROM bf_ard.core_global_historical_bookings_pipeline
			GROUP BY 1,2,3 ORDER BY 1,2,3) y
			----END INNERMOST QUERY----
			ON x.account_name = y.account_name
				AND x.reporting_services_geo = y.reporting_services_geo
				AND y.inner_q BETWEEN DATEADD(QUARTER,-3,DATE_TRUNC('quarter',x.opportunity_close_date)) AND DATE_TRUNC('quarter',x.opportunity_close_date)
			GROUP BY 1,2,3,4,5,6,7,8
			----END CTE----
)
----QUERY OF CTE FOR FINAL INFO----
SELECT 
	account_name,
	reporting_services_geo,
	outter_q close_quarter,
	outter_q_gls gls,
	outter_q_gps gps,
	outter_q_tam tam,
	SUM(inner_q_gls) rolling_gls,
	SUM(inner_q_gps) rolling_gps,
	SUM(inner_q_tam) rolling_tam,
	SUM(inner_q_gls) > 0 has_gls,
	SUM(inner_q_gps) > 0 has_gps,
	SUM(inner_q_tam) > 0 has_tam
FROM z WHERE DATE_PART('year',outter_q) >= 2019 --AND account_name = 'DELL'
GROUP BY 1,2,3,4,5,6
ORDER BY 1,2,3,4,5,6


----FULL QUERY (SHORT)
WITH a AS (
			SELECT
				account_name,
				reporting_services_geo,
				DATE_TRUNC('quarter',opportunity_close_date) close_quarter,
				SUM(CASE WHEN product_forecast_group = 'TRAINING' THEN syb_amount_usd_cy_pr ELSE 0 END) gls,
				SUM(CASE WHEN product_forecast_group = 'CONSULTING' THEN syb_amount_usd_cy_pr ELSE 0 END) gps,
				SUM(CASE WHEN UPPER(product_line) LIKE '%TAM%' THEN syb_amount_usd_cy_pr ELSE 0 END) tam
			FROM bf_ard.core_global_historical_bookings GROUP BY 1,2,3 ORDER BY 1,2,3
)
SELECT
	a.*,
	SUM(b.gls) rolling_gls,
	SUM(b.gps) rolling_gps,
	SUM(b.tam) rolling_tam,
	SUM(b.gls) > 0 has_gls,
	SUM(b.gps) > 0 has_gps,
	SUM(b.tam) > 0 has_tam
FROM a LEFT JOIN a AS b
ON
	a.account_name = b.account_name
	AND a.reporting_services_geo = b.reporting_services_geo
	AND b.close_quarter BETWEEN DATEADD(QUARTER,-3,a.close_quarter) AND a.close_quarter
	GROUP BY 1,2,3,4,5,6 ORDER BY 1,2,3,4,5,6	