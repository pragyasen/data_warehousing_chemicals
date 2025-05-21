# Data Warehousing Term Project
This project explores hazardous substances found in everyday consumer products & cosmetics using data warehousing techniques. PostGre SQL has been used for implementation.

## Datasets used
1. Chemicals in Cosmetics (from official California state dept.)
2. Metals in Consumer products (from official New York state dept.)

## Concepts covered
1. Fact tables (Cumulative, Snapshot)
2. Dimension tables (Slowly Changing Dimensions: SCD0, SCD1, SCD2, SCD3)

## ERD
![ER Diagram](/ERD_Term_Project.drawio.png)

1. Have created 4 Fact tables (2 cumulative, 2 snapshot).
2. The **fact_metals_in_consumer_products_snapshot**, **fact_metals_in_consumer_products_cumulative** fact tables contain the measures from the **Metals in Consumer Products** dataset.
3. The **fact_chemicals_in_cosmetics_snapshot**, **fact_chemicals_in_cosmetics_cumulative** fact tables contain measures from the **Chemicals in Cosmetics** dataset.
4. Both the Cumulative fact tables have a Month grain while the Snapshot table function with a regular Date grain.
5. The **Products**, **Chemicals** dimension tables connect the data from both datasets.

## Business Questions
1. Which product categories contain the highest concentration of chemicals?
2. Does the manufacturing country have any correlation with harmful chemicals?
3. Checking the total number of product appearances for companies through different months.

## Implementation steps
1. Created the dimension and fact tables.
2. Filled data from the datasets into 2 staging tables.
3. Moved data from these staging tables into the created dimension and fact tables.
4. Checked tables for different SCDs. Used Triggers and Stored Procedures to ensure each table works according to the assigned SCD.
5. Queries for answering business questions.
