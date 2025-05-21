--business questions
--creating indexes for better performance
CREATE INDEX idx_products_name ON dim_products(product_name);
CREATE INDEX idx_chemicals_name ON dim_chemicals(chemical_name);
CREATE INDEX idx_cosmetics_snapshot_product ON fact_chemical_in_cosmetics_snapshot(product_id);
CREATE INDEX idx_consumer_snapshot_product ON fact_metals_in_consumer_products_snapshot(product_id);

CREATE INDEX idx_dim_products_product_id_type
ON dim_products (product_id, product_type); --composite index

--product categories that contain higest concentration of chemicals
SELECT
    dim_products.product_type AS category,
    AVG(fact_metals_in_consumer_products_snapshot.concentration) AS avg_concentration,
    MAX(fact_metals_in_consumer_products_snapshot.concentration) AS max_concentration,
    COUNT(*) AS sample_count
FROM fact_metals_in_consumer_products_snapshot
JOIN dim_products ON dim_products.product_id = fact_metals_in_consumer_products_snapshot.product_id
WHERE fact_metals_in_consumer_products_snapshot.concentration IS NOT NULL
GROUP BY dim_products.product_type
ORDER BY avg_concentration DESC
LIMIT 10;

--does manufacturing country have any correlation with harmful chemicals
SELECT
    dim_manufacturer_country.country_name,
    COUNT(DISTINCT CASE 
        WHEN dim_chemicals.chemical_name IN ('Lead', 'Mercury', 'Cadmium') THEN fact_metals_in_consumer_products_snapshot.product_id 
    END) AS harmful_products
FROM fact_metals_in_consumer_products_snapshot
JOIN dim_chemicals ON dim_chemicals.chemical_id = fact_metals_in_consumer_products_snapshot.chemical_id
JOIN dim_manufacturer_country ON dim_manufacturer_country.manufacturer_country_id = fact_metals_in_consumer_products_snapshot.manufacturer_country_id
GROUP BY dim_manufacturer_country.country_name
ORDER BY harmful_products DESC;

--checking the total product appearances for companies through different months
SELECT
    dim_cumulative_date.year,
    dim_cumulative_date.month,
    dim_company.company_name_2009 AS company,
    SUM(fact_chemical_in_cosmetics_cumulative.product_appearance_count) AS total_product_appearances
FROM fact_chemical_in_cosmetics_cumulative
JOIN dim_cumulative_date ON dim_cumulative_date.month_id = fact_chemical_in_cosmetics_cumulative.month_id
JOIN dim_company ON dim_company.company_id = fact_chemical_in_cosmetics_cumulative.company_id
GROUP BY dim_cumulative_date.year, dim_cumulative_date.month, dim_company.company_name_2009
ORDER BY dim_company.company_name_2009, dim_cumulative_date.year, dim_cumulative_date.month;
