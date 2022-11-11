--How many deals are SAs paid on?
SELECT
	fiscal_year || '-Q' || fiscal_qtr yr_qtr,
	rep_id,
	summary_roles,
	job_title,
	COUNT(DISTINCT opportunity_number) deal_count,
	SUM(commission_payout) AS commissions,
	SUM(total_earnings) AS earnings
FROM fin_ds.sales_expense_proxy
WHERE summary_roles IN ('Acct SAs','Solution Architect')
AND dept = 'Sales'
--Set Threshold
AND commission_payout > 10
GROUP BY yr_qtr, rep_id, summary_roles, job_title
ORDER BY yr_qtr, deal_count DESC