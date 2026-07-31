CREATE DATABASE customer_value_analytics;
USE customer_value_analytics;
SELECT *
FROM customer_value_analytics
LIMIT 10;
SELECT COUNT(*)
FROM customer_value_analytics;
DESCRIBE customer_value_analytics;
---------------------------------------------------------------------------------------------------------------------------------------------
# Module 1:- Customer Value & Loyalty Analysis
/*Questions Addressed
This module answers the following business questions:
1. Who are the genuinely loyal customers versus those who primarily purchase during promotions?
2. What characteristics distinguish high-value customers from low-value customers?
3. Which customer segments contribute the greatest share of revenue?
4. Which customers should receive premium retention efforts?
*/
-- Query 1.1: Customer Segmentation Overview
WITH customer_base AS (
    SELECT
        customer_id,
        commercial_loyalty,
        value_tier,
        purchase_amount_usd,
        previous_purchases,
        customer_health_index,
        promotion_dependency_index
    FROM customer_value_analytics
)
SELECT commercial_loyalty, value_tier,
    COUNT(*) AS customer_count,
    ROUND(AVG(purchase_amount_usd),2) AS avg_purchase_amount,
    ROUND(AVG(previous_purchases),2) AS avg_previous_purchases,
    ROUND(AVG(customer_health_index),2) AS avg_chi,
    ROUND(AVG(promotion_dependency_index),2) AS avg_pdi
FROM customer_base
GROUP BY commercial_loyalty, value_tier
ORDER BY commercial_loyalty DESC, avg_purchase_amount DESC;
-- Business Interpretation: Each row represents a customer segment defined by Commercial Loyalty and Value Tier. The summary statistics reveal how customer behaviour differs across segments.

-- Query 1.2: Behavioural Profile of Loyal vs Non-Loyal Customers
SELECT commercial_loyalty,
    COUNT(*) AS customer_count,
    ROUND(AVG(purchase_amount_usd),2) AS avg_revenue,
    ROUND(AVG(previous_purchases),2) AS avg_previous_purchases,
    ROUND(AVG(customer_health_index),2) AS avg_chi,
    ROUND(AVG(promotion_dependency_index),2) AS avg_pdi,
    ROUND(AVG(CASE
                WHEN satisfaction_flag='Satisfied'
                THEN 100
                ELSE 0
            END),2) AS satisfaction_rate
FROM customer_value_analytics
GROUP BY commercial_loyalty;
-- Business Interpretation: High-value customers are expected to exhibit stronger purchasing behaviour, healthier customer relationships and lower reliance on promotions.

-- Query 1.3: Revenue Contribution by Customer Segment
WITH revenue_summary AS (
    SELECT commercial_loyalty, SUM(purchase_amount_usd) AS total_revenue
    FROM customer_value_analytics
    GROUP BY commercial_loyalty
)
SELECT commercial_loyalty,
    ROUND(total_revenue,2) AS total_revenue,
    ROUND(total_revenue/SUM(total_revenue) OVER()*100, 2) AS revenue_share_percentage
FROM revenue_summary
ORDER BY total_revenue DESC;
-- Business Interpretation: If a relatively small proportion of customers contribute a large share of revenue, the brand should prioritise retaining these customers rather than increasing blanket promotional spending.

-- Query 1.4: Revenue Quartile Analysis
WITH customer_quartiles AS (
    SELECT
    customer_id,
    commercial_loyalty,
    purchase_amount_usd,
    NTILE(4) OVER(ORDER BY purchase_amount_usd DESC) AS revenue_quartile
    FROM customer_value_analytics
)
SELECT revenue_quartile, commercial_loyalty,
COUNT(*) AS customers,
ROUND(AVG(purchase_amount_usd),2) AS avg_purchase_amount
FROM customer_quartiles
GROUP BY revenue_quartile, commercial_loyalty
ORDER BY revenue_quartile, commercial_loyalty DESC;
-- Business Interpretation: Rather than analysing customers individually, divide the customer base into four equally sized spending groups, providing a better overview of the spending.

-- Query 1.5: Ranking the Highest-Value Loyal Customers
WITH ranked_customers AS (
    SELECT
    customer_id,
    purchase_amount_usd,
    previous_purchases,
    customer_health_index,
    promotion_dependency_index,
    ROW_NUMBER()OVER(ORDER BY purchase_amount_usd DESC) AS customer_rank
    FROM customer_value_analytics
    WHERE commercial_loyalty='High'
)
SELECT customer_rank,
customer_id,
purchase_amount_usd,
previous_purchases,
customer_health_index,
promotion_dependency_index
FROM ranked_customers
WHERE customer_rank<=10;
-- Business Interpretation: These customers generate exceptional commercial value and have a healthy customer relationships.

-- Query 1.6: Validating the Commercial Loyalty Definition
SELECT commercial_loyalty,
COUNT(*) AS customer_count,
ROUND(AVG(customer_health_index),2) AS avg_chi,
ROUND(AVG(promotion_dependency_index),2) AS avg_pdi,
ROUND(AVG(previous_purchases),2) AS avg_previous_purchases,
ROUND(AVG(purchase_amount_usd),2) AS avg_purchase_amount
FROM customer_value_analytics
GROUP BY commercial_loyalty;
-- Business Interpretation: We verify whether customers classified as Commercially Loyal genuinely demonstrate stronger business characteristics.

/*Key Findings From Module 1
This module establishes the relationship between customer behaviour, customer health and commercial value.
The findings from this module provide evidence for selecting Commercial Loyalty as the project's primary customer segmentation framework.
*/
----------------------------------------------------------------------------------------------------------------------------------------------------
# Module 2:- Product Lifecycle & Category Analysis
/*Questions Addressed:
This module contributes to answering the following business questions:
1. Which product categories attract new customers?
2. Which categories are associated with repeat purchasing?
3. Which seasons produce healthier customer relationships?
4. Which category-season combinations generate the strongest commercial value?
*/

-- Query 2.1: Entry vs Retention Categories
WITH category_summary AS (
    SELECT category,
        COUNT(*) AS customer_count,
        ROUND(AVG(previous_purchases),2) AS avg_previous_purchases,
        ROUND(AVG(customer_health_index),2) AS avg_chi,
        ROUND(AVG(promotion_dependency_index),2) AS avg_pdi,
        ROUND(AVG(purchase_amount_usd),2) AS avg_purchase_amount
    FROM customer_value_analytics
    GROUP BY category
)
SELECT *
FROM category_summary
ORDER BY avg_previous_purchases DESC;
-- Business Interpretation: Categories at the top of this table are associated with customers who have stronger purchasing histories, representing potential retention products.

-- Query 2.2: Seasonal Customer Behaviour
SELECT season,
    COUNT(*) AS customer_count,
    ROUND(AVG(previous_purchases),2) AS avg_previous_purchases,
    ROUND(AVG(customer_health_index),2) AS avg_chi,
    ROUND(AVG(promotion_dependency_index),2) AS avg_pdi,
    ROUND(SUM(purchase_amount_usd),2) AS total_revenue,
    ROUND(AVG(purchase_amount_usd),2) AS avg_purchase_amount
FROM customer_value_analytics
GROUP BY season
ORDER BY total_revenue DESC;
-- Business Interpretation: Seasonal collections attracting customers with stronger purchasing histories and healthier customer relationships may warrant greater marketing investment.

-- Query 2.3: Category × Season Performance Matrix
WITH category_season AS (
    SELECT category, season,
        COUNT(*) AS customer_count,
        ROUND(SUM(purchase_amount_usd),2) AS total_revenue,
        ROUND(AVG(previous_purchases),2) AS avg_previous_purchases,
        ROUND(AVG(customer_health_index),2) AS avg_chi,
        ROUND(AVG(promotion_dependency_index),2) AS avg_pdi
    FROM customer_value_analytics
    GROUP BY category, season
)
SELECT *
FROM category_season
ORDER BY total_revenue DESC, avg_chi DESC;
-- Business Interpretation: This analysis highlights category-season combinations that have stronger customer relationships and higher commercial value.

-- Query 2.4: Ranking Categories by Retention Strength
WITH category_retention AS (
SELECT category,
    ROUND(AVG(previous_purchases),2) AS avg_previous_purchases,
    ROUND(AVG(customer_health_index),2) AS avg_chi,
    ROUND((AVG(previous_purchases)+AVG(customer_health_index)) / 2, 2) AS retention_index
FROM customer_value_analytics
GROUP BY category
)
SELECT category, avg_previous_purchases, avg_chi, retention_index, DENSE_RANK()OVER(ORDER BY retention_index DESC) AS retention_rank
FROM category_retention
ORDER BY retention_rank;
-- Business Interpretation: Unlike ROW_NUMBER(), DENSE_RANK() assigns the same rank to categories with identical Retention Index values. 
-- This is appropriate because categories exhibiting equivalent customer retention characteristics should be treated equally from a business perspective.

/*Key Findings From Module 2
This module's analysis distinguishes between acquisition-focused product categories and retention-focused categories while also evaluating seasonal purchasing behaviour.
These insights extend the customer segmentation developed in Module 1 by explaining which products and seasons cultivate long-term customer value, 
providing a bridge between customer analytics and merchandising strategy.*/
---------------------------------------------------------------------------------------------------------------------------------------------------

# Module 3:- Geographic Opportunity Analysis
/*Questions Addressed
This module contributes to answering the following business questions:
1. Which geographies demonstrate genuine organic demand?
2. Which regions rely heavily on promotional incentives?
3. Which regions appear commercially underleveraged?
4. Where should future customer acquisition efforts be concentrated?*/

-- Query 3.1: Geographic Performance Overview
SELECT location,
    COUNT(*) AS customer_count,
    ROUND(SUM(purchase_amount_usd),2) AS total_revenue,
    ROUND(AVG(purchase_amount_usd),2) AS avg_purchase_amount,
    ROUND(AVG(customer_health_index),2) AS avg_chi,
    ROUND(AVG(promotion_dependency_index),2) AS avg_pdi
FROM customer_value_analytics
GROUP BY location
ORDER BY total_revenue DESC;
-- Business Interpretation: This query provides an initial comparison of commercial performance across all regions.

-- Query 3.2: Classifying Regional Demand Using Median-Based Benchmarks
WITH regional_summary AS (
    SELECT location,
        ROUND(AVG(customer_health_index), 2) AS avg_chi,
        ROUND(AVG(promotion_dependency_index), 2) AS avg_pdi,
        ROUND(SUM(purchase_amount_usd), 2) AS total_revenue
    FROM customer_value_analytics
    GROUP BY location
),
ordered_chi AS (
    SELECT avg_chi,
        ROW_NUMBER() OVER (ORDER BY avg_chi) AS rn,
        COUNT(*) OVER () AS total_rows
    FROM regional_summary
),
ordered_pdi AS (
    SELECT avg_pdi,
        ROW_NUMBER() OVER (ORDER BY avg_pdi) AS rn,
        COUNT(*) OVER () AS total_rows
    FROM regional_summary
),
median_chi AS (
    SELECT
        AVG(avg_chi) AS chi_median
    FROM ordered_chi
    WHERE rn IN (FLOOR((total_rows + 1) / 2),FLOOR((total_rows + 2) / 2))
),
median_pdi AS (
    SELECT
        AVG(avg_pdi) AS pdi_median
    FROM ordered_pdi
    WHERE rn IN (FLOOR((total_rows + 1) / 2),FLOOR((total_rows + 2) / 2))
)
SELECT rs.location, rs.total_revenue, 
	rs.avg_chi, 
    ROUND(mc.chi_median, 2) AS median_chi,
    ROUND(rs.avg_chi - mc.chi_median,2) AS chi_gap,
    rs.avg_pdi, 
    ROUND(mp.pdi_median, 2) AS median_pdi,
    ROUND(rs.avg_pdi - mp.pdi_median,2) AS pdi_gap,
    CASE
        WHEN rs.avg_chi >= mc.chi_median
         AND rs.avg_pdi <= mp.pdi_median
        THEN 'Organic Demand'
        WHEN rs.avg_chi < mc.chi_median
         AND rs.avg_pdi > mp.pdi_median
        THEN 'Promotion-Driven'
        ELSE 'Balanced'
	END AS regional_segment
FROM regional_summary AS rs
CROSS JOIN median_chi AS mc
CROSS JOIN median_pdi AS mp
ORDER BY rs.total_revenue DESC;
/*Business Interpretation: Median instead of average is used since customer behaviour is rarely distributed evenly. 
A small number of regions with exceptionally high Customer Health Index or Promotion Dependency Index values can disproportionately influence the average.
Each geography is assigned to one of three(Organic Demand, Promotion-Driven, Balanced) commercially meaningful segments.
This query goes beyond assigning each region to a commercial segment by also quantifying how far each geography differs from the business benchmark.(using CHI and PDI gaps)*/

/*Key findings from Module 3
Customer purchasing behaviour varies significantly across product categories and regions, 
indicating that retention strategies should be tailored rather than uniformly applied.*/
------------------------------------------------------------------------------------------------------------------------------------------
# Module 4:- Promotion Strategy & Margin Protection
/*Questions Addressed
This module contributes directly to the following business question:
How should the brand restructure its promotional strategy to protect margins without losing sales volume?
Specifically, the analysis investigates:
1. Which customer segments rely most heavily on promotions?
2. Which regions are promotion-driven?
3. Which product categories naturally generate purchases without extensive discounting?*/

-- Query 4.1: Promotion Dependence Across Customer Value Tiers
SELECT value_tier,
    COUNT(*) AS customer_count,
    ROUND(AVG(promotion_dependency_index),2) AS avg_pdi,
    ROUND(AVG(customer_health_index),2) AS avg_chi,
    ROUND(AVG(purchase_amount_usd),2) AS avg_purchase_amount
FROM customer_value_analytics
GROUP BY value_tier
ORDER BY avg_pdi ASC;
/*Business Interpretation: Comparing Value Tiers reveals whether customer value increases alongside decreasing promotional dependence. 
Reduce blanket promotional campaigns for Premium Value customers.
Instead, prioritise personalised engagement initiatives such as loyalty rewards, 
exclusive launches and early-access benefits, preserving margins while maintaining customer satisfaction.*/

-- Query 4.2: Regional Promotion Dependence
SELECT location,
    COUNT(*) AS customer_count,
    ROUND(AVG(promotion_dependency_index),2) AS avg_pdi,
    ROUND(SUM(purchase_amount_usd),2) AS total_revenue
FROM customer_value_analytics
GROUP BY location
ORDER BY avg_pdi DESC;
/* Business Interpretation: Regions exhibiting consistently high Promotion Dependency Index values 
may generate revenue primarily through discounts rather than customer loyalty.
Transition high-PDI regions away from broad discounting by introducing targeted 
promotional campaigns based on customer value and purchase history.*/

-- Query 4.3: Promotion Dependence Across Product Categories
WITH category_summary AS (
    SELECT category,
        COUNT(*) AS customer_count,
        ROUND(AVG(promotion_dependency_index),2) AS avg_pdi,
        ROUND(AVG(customer_health_index),2) AS avg_chi,
        ROUND(SUM(purchase_amount_usd),2) AS total_revenue
    FROM customer_value_analytics
    GROUP BY category
)
SELECT category, customer_count, avg_pdi, avg_chi, total_revenue, DENSE_RANK() OVER (ORDER BY avg_pdi ASC) AS promotion_efficiency_rank
FROM category_summary
ORDER BY promotion_efficiency_rank;
/* Business Interpretation: Categories with lower Promotion Dependency Index values 
generate healthier demand with less reliance on discounts.
Redirect promotional spending toward categories demonstrating 
high customer acquisition potential but currently exhibiting higher promotional dependence.*/

-- Query 4.4: Does Commercial Loyalty Reduce Promotion Dependence?
SELECT commercial_loyalty,
    COUNT(*) AS customer_count,
    ROUND(AVG(promotion_dependency_index),2) AS avg_pdi,
    ROUND(AVG(customer_health_index),2) AS avg_chi,
    ROUND(AVG(previous_purchases),2) AS avg_previous_purchases,
    ROUND(AVG(purchase_amount_usd),2) AS avg_purchase_amount
FROM customer_value_analytics
GROUP BY commercial_loyalty
ORDER BY avg_pdi;
-- Business Interpretation: Shift marketing investment away from universal discounts and toward loyalty-driven retention programmes.

/*Key Findings from Module 4
This module demonstrates that promotional effectiveness varies considerably across customer segments, geographies and product categories.
Rather than applying blanket discounting, promotional investment should be tailored according to customer quality and promotional dependence.
Such an approach enables the business to protect profit margins while preserving long-term customer loyalty.*/
-----------------------------------------------------------------------------------------------------------------------------

# Module 5:- Ideal Customer Profile & Acquisition Strategy
/*Questions Addressed
This module contributes directly to the following business question:
What does the brand's ideal customer profile look like, and how can the business acquire more customers like them?*/

-- Query 5.1: Behavioural Characteristics of the Ideal Customer
SELECT COUNT(*) AS loyal_customers,
    ROUND(AVG(customer_health_index),2) AS avg_chi,
    ROUND(AVG(promotion_dependency_index),2) AS avg_pdi,
    ROUND(AVG(previous_purchases),2) AS avg_previous_purchases,
    ROUND(AVG(purchase_amount_usd),2) AS avg_purchase_amount
FROM customer_value_analytics
WHERE commercial_loyalty = 'High';
/* Business Interpretation: These metrics define the average behavioural profile of the brand's strongest customers.
Future acquisition campaigns should prioritise customers exhibiting behavioural characteristics similar to this profile, 
as these customers are more likely to generate sustainable long-term value.*/

-- Query 5.2: Demographic and Geographic Characteristics
SELECT location, age, gender,
    COUNT(*) AS loyal_customer_count,
    ROUND(AVG(purchase_amount_usd),2) AS avg_purchase_amount
FROM customer_value_analytics
WHERE commercial_loyalty NOT IN ('Low')
GROUP BY location, age, gender
ORDER BY loyal_customer_count DESC, avg_purchase_amount DESC;
/*Business Interpretation: This query identifies demographic clusters where commercially valuable customers(Highly and Moderately commercially loyal) are concentrated.
Increase acquisition investment in these demographic segments that consistently exhibit stronger purchasing behaviour while tailoring 
messaging to the needs of these customer groups.*/

-- Query 5.3: Product Preferences of the Ideal Customer
SELECT category, season,
    COUNT(*) AS loyal_customer_count,
    ROUND(AVG(purchase_amount_usd),2) AS avg_purchase_amount,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS preference_rank
FROM customer_value_analytics
WHERE commercial_loyalty = 'High'
GROUP BY category, season
ORDER BY preference_rank;
/*Business Interpretation: The highest-ranked category-season combinations represent the product preferences most 
commonly observed among the brand's strongest customers.
Feature these products prominently in acquisition campaigns, homepage recommendations and personalised marketing 
initiatives to maximise conversion among high-potential customers.*/

-- Query 5.4: Ideal Customer Scorecard
SELECT commercial_loyalty,
    ROUND(AVG(customer_health_index),2) AS avg_chi,
    ROUND(AVG(promotion_dependency_index),2) AS avg_pdi,
    ROUND(AVG(previous_purchases),2) AS avg_previous_purchases,
    ROUND(AVG(purchase_amount_usd),2) AS avg_purchase_amount,
    MODE_CATEGORY.category AS most_common_category,
    MODE_SEASON.season AS most_common_season,
    MODE_LOCATION.location AS most_common_location
FROM customer_value_analytics
CROSS JOIN (
    SELECT category
    FROM customer_value_analytics
    WHERE commercial_loyalty NOT IN ('Low')
    GROUP BY category
    ORDER BY COUNT(*) DESC
    LIMIT 1
) AS MODE_CATEGORY
CROSS JOIN (
    SELECT season
    FROM customer_value_analytics
    WHERE commercial_loyalty NOT IN ('Low')
    GROUP BY season
    ORDER BY COUNT(*) DESC
    LIMIT 1
) AS MODE_SEASON
CROSS JOIN (
    SELECT location
    FROM customer_value_analytics
    WHERE commercial_loyalty NOT IN ('Low')
    GROUP BY location
    ORDER BY COUNT(*) DESC
    LIMIT 1
) AS MODE_LOCATION
WHERE commercial_loyalty NOT IN ('Low')
GROUP BY commercial_loyalty, most_common_category, most_common_season, most_common_location
ORDER BY commercial_loyalty;
/* Business Interpretation: The Ideal Customer Scorecard consolidates behavioural, transactional and demographic insights into a summary.
The Ideal Customer Scorecard should serve as the benchmark for future customer acquisition initiatives.
Marketing campaigns should prioritise audiences that resemble this profile, while merchandising teams should emphasise the products and seasons 
most frequently associated with these customers.*/
---------------------------------------------------------------------------------------------------------------------------------
/*SQL Stage Summary
Across 5 analytical modules, the project has:
- Distinguished genuinely loyal customers from promotion-driven customers.
- Identified behavioural characteristics associated with long-term customer value.
- Evaluated product categories and seasonal purchasing behaviour.
- Identified commercially attractive geographic markets.
- Developed a data-driven promotional strategy.
- Constructed an Ideal Customer Profile to guide future customer acquisition.*/
----------------------------------------------------------------------------------------------------------------------------------
