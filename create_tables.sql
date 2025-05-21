--dimension tables
--Products dimension(shared by both datasets) : SCD2
CREATE TABLE dim_products (
    product_id SERIAL PRIMARY KEY,
	cdph_id INTEGER,
    product_name VARCHAR(255) NOT NULL,
    product_type VARCHAR(100),
	source_system VARCHAR(20) CHECK (source_system IN ('COSMETICS', 'CONSUMER')),
    current_flag BOOLEAN DEFAULT TRUE,
    entry_date DATE DEFAULT CURRENT_DATE,
    expiry_date DATE DEFAULT '9999-12-31'
);

--Chemicals dimension : SCD1
CREATE TABLE dim_chemicals (
    chemical_id SERIAL PRIMARY KEY,
	cas_id INTEGER,
    cas_number VARCHAR(50),
	chemical_name VARCHAR(255) NOT NULL
);

--Company dimension(for cosmetics) : SCD3
CREATE TABLE dim_company (
    company_id SERIAL PRIMARY KEY,
	CompanyId INTEGER, --existing key from the table
    company_name_2009 VARCHAR(255) NOT NULL
);

ALTER TABLE dim_company
ADD COLUMN company_name_2010 VARCHAR(255);

select * from dim_company

--Tested_by dimension(shared by both datasets)
CREATE TABLE dim_tested_by (
    tester_id SERIAL PRIMARY KEY,
    tester_name VARCHAR(100) CHECK (tester_name IN ('CALIFORNIA', 'NYC'))
);

--Manufacturer_Country dimension table(for consumer products)
CREATE TABLE dim_manufacturer_country (
    manufacturer_country_id SERIAL PRIMARY KEY,
	manufacturer_name VARCHAR(20) NOT NULL,
    country_name VARCHAR(100)
);
ALTER TABLE dim_manufacturer_country 
ALTER COLUMN manufacturer_name TYPE VARCHAR(100);

--Cumulative_Date dimension(Month grain for cumulative fact tables)
CREATE TABLE dim_cumulative_date (
    month_id SERIAL PRIMARY KEY,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),
    month_name VARCHAR(10),
    UNIQUE(year, month)
);

--Date dimension(for snapshot fact tables)
CREATE TABLE dim_date (
	date_id SERIAL PRIMARY KEY,
	date DATE NOT NULL UNIQUE,
	day_of_month INTEGER NOT NULL,
	month INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),
	year INTEGER NOT NULL
)


--fact tables
--Consumer Products Snapshot
CREATE TABLE fact_metals_in_consumer_products_snapshot (
    cp_snapshot_fact_id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES dim_products(product_id),
    chemical_id INTEGER REFERENCES dim_chemicals(chemical_id),
    tester_id INTEGER REFERENCES dim_tested_by(tester_id),
    manufacturer_country_id INTEGER REFERENCES dim_manufacturer_country(manufacturer_country_id),
    date_id INTEGER REFERENCES dim_date(date_id),
	concentration NUMERIC,
    units VARCHAR(10)
);

--Consumer Products Cumulative
CREATE TABLE fact_metal_in_consumer_products_cumulative (
    cp_cumulative_fact_id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES dim_products(product_id),
    chemical_id INTEGER REFERENCES dim_chemicals(chemical_id),
    tester_id INTEGER REFERENCES dim_tested_by(tester_id),
    manufacturer_country_id INTEGER REFERENCES dim_manufacturer_country(manufacturer_country_id),
    cumulative_metal_count INTEGER,
    month_id INTEGER REFERENCES dim_cumulative_date(month_id)
);
ALTER TABLE fact_metal_in_consumer_products_cumulative
DROP COLUMN chemical_id;
ALTER TABLE fact_metal_in_consumer_products_cumulative
RENAME COLUMN cumulative_metal_count TO product_appearance_count;

--Cosmetics Snapshot
CREATE TABLE fact_chemical_in_cosmetics_snapshot (
    cosmetic_snapshot_fact_id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES dim_products(product_id),
    chemical_id INTEGER REFERENCES dim_chemicals(chemical_id),
    company_id INTEGER REFERENCES dim_company(company_id),
    tester_id INTEGER REFERENCES dim_tested_by(tester_id),
    date_id INTEGER REFERENCES dim_date(date_id),
    chemical_count INTEGER
);

--Cosmetics Cumulative
CREATE TABLE fact_chemical_in_cosmetics_cumulative (
    cosmetic_cumulative_fact_id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES dim_products(product_id),
    chemical_id INTEGER REFERENCES dim_chemicals(chemical_id),
    company_id INTEGER REFERENCES dim_company(company_id),
    tester_id INTEGER REFERENCES dim_tested_by(tester_id),
    cumulative_chemical_count INTEGER,
    month_id INTEGER REFERENCES dim_cumulative_date(month_id)
);
ALTER TABLE fact_chemical_in_cosmetics_cumulative
DROP COLUMN chemical_id;
ALTER TABLE fact_chemical_in_cosmetics_cumulative
RENAME COLUMN cumulative_chemical_count TO product_appearance_count;

--Staging Tables
--Cosmetics staging
CREATE TABLE staging_cosmetics (
    CDPHId INTEGER,
    ProductName TEXT,
	CSFId NUMERIC,
	CSF TEXT,
    CompanyId INTEGER,
    CompanyName TEXT,
	BrandName TEXT,
	PrimaryCategoryId NUMERIC,
	PrimaryCategory TEXT,
	SubCategoryId NUMERIC,
	SubCategory TEXT,
    CasId INTEGER,
    CasNumber TEXT,
    ChemicalId INTEGER,
    ChemicalName TEXT,
    InitialDateReported DATE,
    MostRecentDateReported DATE,
	Chemical_Count NUMERIC
);
--drop table staging_cosmetics

-- Consumer products staging
CREATE TABLE staging_consumer (
	Row_ID NUMERIC,
	ProductType VARCHAR(40),
    ProductName TEXT,
    Metal TEXT,
    Concentration NUMERIC,
    Units VARCHAR(10),
    Manufacturer TEXT,
    Made_In_Country TEXT,
	Purchase_Country TEXT,
    Collection_Date TIMESTAMP,
	Investigation_Type VARCHAR(2)
);
--drop table staging_consumer

INSERT INTO staging_consumer (
    Product_Type, Product_Name, Metal, Concentration, Units, 
    Manufacturer, Made_In_Country, Collection_Date, Investigation_Type
)
VALUES (
    'Food-Spice', 'Turmeric powder', 'Lead', 2.9, 'ppm',
    'UNKNOWN OR NOT STATED', 'INDIA', '2011-01-04 00:00', 'C'
);

--populating staging tables
--Cosmetics
SELECT * FROM staging_consumer
SET DateStyle TO 'ISO, MDY';
SELECT * FROM staging_cosmetics