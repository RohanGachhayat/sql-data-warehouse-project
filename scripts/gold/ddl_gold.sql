/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- ======================================================
-- CREATE DIMENSION TABLE: gold.dim_customers
-- ======================================================

IF OBJECT_ID('gold.dim_customers','V') IS NOT NULL
	DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
    cc.cst_id                           AS customer_id,
    cc.cst_key                          AS customer_number,
    cc.cst_firstname                    AS first_name,
    cc.cst_lastname                     AS last_name,
    el.cntry                            AS country,
    cc.cst_marital_status               AS marital_status,
    CASE WHEN cc.cst_gndr != 'n/a' THEN cc.cst_gndr
         ELSE COALESCE(ca.gen,'n/a')
    END AS gender,
    ca.bdate                            AS birth_date,
    cc.cst_create_date                  AS create_date
FROM silver.crm_cust_info AS cc
LEFT JOIN silver.erp_cust_az12 AS ca
	ON cc.cst_key=ca.cid
LEFT JOIN silver.erp_loc_a101 AS el
	ON cc.cst_key=el.cid
GO

-- ======================================================
-- CREATE DIMENSION TABLE: gold.dim_products
-- ======================================================

IF OBJECT_ID('gold.dim_products','V') IS NOT NULL
	DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT 
	ROW_NUMBER () OVER (ORDER BY cp.prd_start_dt,cp.prd_key) AS product_key,
	cp.prd_id							AS product_id, 
	cp.prd_key							AS product_number,
	cp.prd_nm							AS product_name,
	cp.cat_id							AS category_id,
	pc.cat								AS product_category,
	pc.subcat							AS product_suabcategory,
	pc.maintenance						AS product_submaintenance,
	cp.prd_cost							AS product_cost,
	cp.prd_line							AS product_line,
	cp.prd_start_dt						AS start_date
FROM silver.crm_prd_info AS cp
LEFT JOIN silver.erp_px_cat_g1v2 AS pc
	ON cp.cat_id=pc.id
WHERE prd_end_dt IS NULL
GO

-- =====================================================
-- CREATE FACT TABLE: gold.fact_sales
-- =====================================================

IF OBJECT_ID('gold.fact_sales','V') IS NOT NULL
	DROP VIEW gold.fact_sales;
GO
 
CREATE VIEW gold.fact_sales AS
SELECT 
ss.sls_ord_num							AS order_number,
gp.product_key,
gc.customer_key,
ss.sls_order_dt							AS order_date,
ss.sls_ship_dt							AS shipping_date,
ss.sls_due_dt							AS due_date,
ss.sls_sales							AS sales_amount,
ss.sls_quantity							AS sales_quantity,
ss.sls_price							AS sales_price
FROM silver.crm_sales_details AS ss
LEFT JOIN gold.dim_products AS gp
	ON ss.sls_prd_key = gp.product_number
LEFT JOIN gold.dim_customers AS gc
	ON ss.sls_cust_id = gc.customer_id
GO
