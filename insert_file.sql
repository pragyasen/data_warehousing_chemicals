--populating dimension tables
--Chemicals (SCD1)
INSERT INTO dim_chemicals (cas_id, cas_number, chemical_name)
SELECT DISTINCT
    CasId,
    CasNumber,
    ChemicalName
FROM staging_cosmetics --inserting from cosmetics table
WHERE CasId IS NOT NULL;

select * from dim_chemicals

INSERT INTO dim_chemicals (chemical_name)
SELECT DISTINCT
	Metal
FROM staging_consumer;

--Company dimension (SCD3)
INSERT INTO dim_company (CompanyId, company_name_2009)
SELECT DISTINCT
    CompanyId, 
	CompanyName
FROM staging_cosmetics
WHERE CompanyName IS NOT NULL;

SELECT *  FROM dim_company WHERE company_name_2010 IS NOT NULL

--filling data for 2010
UPDATE dim_company
SET company_name_2010 = staging_cosmetics.CompanyName
FROM (
    SELECT DISTINCT CompanyId, CompanyName
    FROM staging_cosmetics
    WHERE EXTRACT(YEAR FROM MostRecentDateReported) = 2010
      AND CompanyId IS NOT NULL
      AND CompanyName IS NOT NULL
) staging_cosmetics
WHERE dim_company.company_id = staging_cosmetics.CompanyId
  AND dim_company.company_name_2009 IS DISTINCT FROM staging_cosmetics.CompanyName;



--Tested_by dimension (SCD1)
INSERT INTO dim_tested_by (tester_name)
VALUES 
	('CALIFORNIA'),
	('NYC');
SELECT * FROM dim_tested_by;

--Manufacturer Country Dimension (SCD1)
INSERT INTO dim_manufacturer_country (manufacturer_name, country_name)
SELECT DISTINCT
    Manufacturer,
    Made_In_Country
FROM staging_consumer
WHERE Manufacturer IS NOT NULL;
SELECT * FROM dim_manufacturer_country;

--Products Dimension (SCD2)
INSERT INTO dim_products (cdph_id, product_name, product_type, source_system)
SELECT DISTINCT
    CDPHId,
    ProductName,
    PrimaryCategory,
    'COSMETICS'
FROM staging_cosmetics
WHERE CDPHId IS NOT NULL;

INSERT INTO dim_products (product_name, product_type, source_system)
SELECT DISTINCT
    ProductName,
    ProductType,
    'CONSUMER'
FROM staging_consumer
WHERE ProductName IS NOT NULL;

SELECT * FROM dim_products
WHERE cdph_id IS NULL

--Cumulative Date dimension (SCD0)
INSERT INTO dim_cumulative_date (year, month, month_name)
SELECT DISTINCT
    EXTRACT(YEAR FROM Collection_Date)::INTEGER,
    EXTRACT(MONTH FROM Collection_Date)::INTEGER,
    TO_CHAR(Collection_Date, 'Month')
FROM staging_consumer
WHERE Collection_Date IS NOT NULL
UNION
SELECT DISTINCT
    EXTRACT(YEAR FROM InitialDateReported)::INTEGER,
    EXTRACT(MONTH FROM InitialDateReported)::INTEGER,
    TO_CHAR(InitialDateReported, 'Month')
FROM staging_cosmetics
WHERE InitialDateReported IS NOT NULL;

SELECT * FROM dim_cumulative_date

--Date dimension (SCD0)
INSERT INTO dim_date (date, day_of_month, month, year)
SELECT DISTINCT
    InitialDateReported,
    EXTRACT(DAY FROM InitialDateReported)::INTEGER,
    EXTRACT(MONTH FROM InitialDateReported)::INTEGER,
    EXTRACT(YEAR FROM InitialDateReported)::INTEGER
FROM staging_cosmetics
WHERE InitialDateReported IS NOT NULL;

INSERT INTO dim_date (date, day_of_month, month, year)
SELECT DISTINCT
    DATE(Collection_Date),
    EXTRACT(DAY FROM Collection_Date)::INTEGER,
    EXTRACT(MONTH FROM Collection_Date)::INTEGER,
    EXTRACT(YEAR FROM Collection_Date)::INTEGER
FROM staging_consumer
WHERE Collection_Date IS NOT NULL
  AND DATE(Collection_Date) NOT IN (SELECT date FROM dim_date);

SELECT * FROM dim_date;

--populating fact tables
--cosmetics snapshot table
INSERT INTO fact_chemical_in_cosmetics_snapshot (
    product_id, chemical_id, company_id, tester_id, date_id, chemical_count
)
SELECT
    dim_products.product_id,
    dim_chemicals.chemical_id,
    dim_company.company_id,
    dim_tested_by.tester_id,
    dim_date.date_id,
    staging_cosmetics.Chemical_Count
FROM staging_cosmetics
JOIN dim_products ON dim_products.product_name = staging_cosmetics.ProductName AND dim_products.source_system = 'COSMETICS'
JOIN dim_chemicals ON dim_chemicals.chemical_name = staging_cosmetics.ChemicalName
JOIN dim_company ON dim_company.company_name_2009 = staging_cosmetics.CompanyName
JOIN dim_tested_by ON dim_tested_by.tester_name = 'CALIFORNIA'
JOIN dim_date ON dim_date.date = staging_cosmetics.InitialDateReported;

SELECT * FROM fact_chemical_in_cosmetics_snapshot


--consumer products snapshot table
INSERT INTO fact_metals_in_consumer_products_snapshot (
    product_id, chemical_id, tester_id, manufacturer_country_id, date_id, concentration, units
)
SELECT
    dim_products.product_id,
    dim_chemicals.chemical_id,
    dim_tested_by.tester_id,
    dim_manufacturer_country.manufacturer_country_id,
    dim_date.date_id,
    staging_consumer.Concentration,
    staging_consumer.Units
FROM staging_consumer
JOIN dim_products ON dim_products.product_name = staging_consumer.ProductName AND dim_products.source_system = 'CONSUMER'
JOIN dim_chemicals ON dim_chemicals.chemical_name = staging_consumer.Metal
JOIN dim_tested_by ON dim_tested_by.tester_name = 'NYC'
JOIN dim_manufacturer_country ON dim_manufacturer_country.manufacturer_name = staging_consumer.Manufacturer
JOIN dim_date ON dim_date.date = DATE(staging_consumer.Collection_Date);

SELECT * FROM fact_metals_in_consumer_products_snapshot;


--cosmetics cumulative table
INSERT INTO fact_chemical_in_cosmetics_cumulative (
    product_id, company_id, tester_id, product_appearance_count, month_id
)
SELECT
    dim_products.product_id,
    dim_company.company_id,
    dim_tested_by.tester_id,
    COUNT(*) AS product_appearance_count,
    dim_cumulative_date.month_id
FROM staging_cosmetics
JOIN dim_products ON dim_products.product_name = staging_cosmetics.ProductName AND dim_products.source_system = 'COSMETICS'
JOIN dim_company ON dim_company.company_name_2009 = staging_cosmetics.CompanyName
JOIN dim_tested_by ON dim_tested_by.tester_name = 'CALIFORNIA'
JOIN dim_cumulative_date
    ON dim_cumulative_date.month = EXTRACT(MONTH FROM staging_cosmetics.InitialDateReported)::INTEGER
    AND dim_cumulative_date.year = EXTRACT(YEAR FROM staging_cosmetics.InitialDateReported)::INTEGER
WHERE staging_cosmetics.InitialDateReported IS NOT NULL
GROUP BY
    dim_products.product_id,
    dim_company.company_id,
	dim_tested_by.tester_id,
    dim_cumulative_date.month_id;

SELECT * FROM fact_chemical_in_cosmetics_cumulative;


--consumer products cumulative table
INSERT INTO fact_metal_in_consumer_products_cumulative (
    product_id, manufacturer_country_id, tester_id, product_appearance_count, month_id
)
SELECT
    dim_products.product_id,
    dim_manufacturer_country.manufacturer_country_id,
    dim_tested_by.tester_id,
    COUNT(*) AS product_appearance_count,
    dim_cumulative_date.month_id
FROM staging_consumer
JOIN dim_products ON dim_products.product_name = staging_consumer.ProductName AND dim_products.source_system = 'CONSUMER'
JOIN dim_manufacturer_country ON dim_manufacturer_country.manufacturer_name = staging_consumer.Manufacturer
JOIN dim_tested_by ON dim_tested_by.tester_name = 'NYC'
JOIN dim_cumulative_date
    ON dim_cumulative_date.month = EXTRACT(MONTH FROM staging_consumer.Collection_Date)::INTEGER
    AND dim_cumulative_date.year = EXTRACT(YEAR FROM staging_consumer.Collection_Date)::INTEGER
WHERE staging_consumer.Collection_Date IS NOT NULL
GROUP BY
    dim_products.product_id,
    dim_manufacturer_country.manufacturer_country_id,
    dim_tested_by.tester_id,
    dim_cumulative_date.month_id;

SELECT * FROM fact_metal_in_consumer_products_cumulative;



--Delta Report
CREATE OR REPLACE PROCEDURE insert_dim_product_scd2(
    p_cdph_id INTEGER,
    p_product_name VARCHAR,
    p_product_type VARCHAR,
    p_source_system VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    existing_record dim_products%ROWTYPE;
BEGIN
    --Checking if current record exists for the same business key (cdph_id, source_system)
    SELECT *
    INTO existing_record
    FROM dim_products
    WHERE cdph_id = p_cdph_id
      AND source_system = p_source_system
      AND current_flag = TRUE;

    --If no such record exists, inserting new one
    IF NOT FOUND THEN
        INSERT INTO dim_products (cdph_id, product_name, product_type, source_system)
        VALUES (p_cdph_id, p_product_name, p_product_type, p_source_system);
    ELSE
        --Checking if attributes differ
        IF existing_record.product_name IS DISTINCT FROM p_product_name
           OR existing_record.product_type IS DISTINCT FROM p_product_type THEN

            --Expire old record
            UPDATE dim_products
            SET current_flag = FALSE,
                expiry_date = CURRENT_DATE
            WHERE product_id = existing_record.product_id;

            --Insert new version
            INSERT INTO dim_products (cdph_id, product_name, product_type, source_system)
            VALUES (p_cdph_id, p_product_name, p_product_type, p_source_system);
        END IF;
        --Else: No change, do nothing
    END IF;
END;
$$;


--testing
select * from dim_products limit 1
--making changes to existing record
CALL insert_dim_product_scd2(
    7151,
    'Bluebell Shower Gel',
    'Bath Products',
    'COSMETICS'
);

--trying to insert an identical record
CALL insert_dim_product_scd2(7151, 'Bluebell Shower Gel', 'Bath Products', 'COSMETICS');


--using merge function
CREATE OR REPLACE PROCEDURE insert_dim_product_scd2_merge(
    p_cdph_id INTEGER,
    p_product_name VARCHAR,
    p_product_type VARCHAR,
    p_source_system VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    existing_product_id INTEGER;
    changes_needed BOOLEAN;
BEGIN
    --Checking if an active version exists
    SELECT product_id INTO existing_product_id
    FROM dim_products
    WHERE cdph_id = p_cdph_id
      AND source_system = p_source_system
      AND current_flag = TRUE;

    --If it exists, checking if changes are needed
    IF existing_product_id IS NOT NULL THEN
        SELECT (product_name IS DISTINCT FROM p_product_name OR product_type IS DISTINCT FROM p_product_type)
        INTO changes_needed
        FROM dim_products
        WHERE product_id = existing_product_id;

        IF changes_needed THEN
            --Expire the old version
            UPDATE dim_products
            SET current_flag = FALSE,
                expiry_date = CURRENT_DATE
            WHERE product_id = existing_product_id;

            --Insert new version
            INSERT INTO dim_products (
                cdph_id, product_name, product_type, source_system, current_flag, entry_date, expiry_date
            )
            VALUES (
                p_cdph_id, p_product_name, p_product_type, p_source_system, TRUE, CURRENT_DATE, '9999-12-31'
            );
        END IF;

    ELSE
        --No existing active version: insert new record
        INSERT INTO dim_products (
            cdph_id, product_name, product_type, source_system, current_flag, entry_date, expiry_date
        )
        VALUES (
            p_cdph_id, p_product_name, p_product_type, p_source_system, TRUE, CURRENT_DATE, '9999-12-31'
        );
    END IF;
END;
$$;


--testing merge
CALL insert_dim_product_scd2_merge(
    7151,
    'Bluebell Shower Gel (New)',  --new name
    'Bath Products',
    'COSMETICS'
);


select * from dim_products where cdph_id = 7151