/* 
PROJECT: PT. KIMIA FARMA PERFORMANCE ANALYSIS (2020-2023)
OBJECTIVE: Menghasilkan tabel analisa dasar untuk laporan evaluasi kinerja bisnis PT. Kimia
Farma dari tahun 2020 hingga 2023.
AUTHOR: Muhammad Reyhan Marciano
*/

-- Membuat tabel master untuk keperluan analisa final dan reporting ke BI tools dengan menggabungkan seluruh tabel (transaksi, inventory, kantor cabang, dan product) menggunakan CTE.

CREATE OR REPLACE TABLE `kimia_farma.analysis_table` AS
WITH 
base_data AS (
  SELECT
    tran.transaction_id,
    tran.date,
    tran.branch_id,
    cab.branch_name,
    cab.kota,
    cab.provinsi,
    cab.rating AS rating_cabang,
    tran.customer_name,
    tran.product_id,
    prod.product_name,
    prod.price AS actual_price,
    tran.discount_percentage,
    tran.rating AS rating_transaksi,
    inv.opname_stock AS stok_tersedia
  FROM `kimia_farma.kf_final_transaction` AS tran
  LEFT JOIN `kimia_farma.kf_kantor_cabang` AS cab ON tran.branch_id = cab.branch_id
  LEFT JOIN `kimia_farma.kf_product` AS prod ON tran.product_id = prod.product_id
  LEFT JOIN `kimia_farma.kf_inventory` AS inv ON tran.branch_id = inv.branch_id AND tran.product_id = inv.product_id 

),

-- Menentukan persentase laba kotor berdasarkan tiering harga menggunakan logika kondisional CASE WHEN untuk menggambarkan skema profit margin perusahaan.

profit_calculation AS (
  SELECT *,
    CASE 
      WHEN actual_price <= 50000 THEN 0.10
      WHEN actual_price > 50000 AND actual_price <= 100000 THEN 0.15
      WHEN actual_price > 100000 AND actual_price <= 300000 THEN 0.20
      WHEN actual_price > 300000 AND actual_price <= 500000 THEN 0.25
      ELSE 0.30 
    END AS persentase_gross_laba
  FROM base_data
),

-- Menghitung metrik finansial (Nett Sales & Nett Profit) untuk melihat profit dan sales bersih.

final_metrics AS (
  SELECT *,
    -- Menghitung harga setelah diskon yang dibayar konsumen
    (actual_price * (1 - discount_percentage)) AS nett_sales,
    
    -- Menghitung laba bersih dari nett sales
    ((actual_price * (1 - discount_percentage)) * persentase_gross_laba) AS nett_profit
  FROM profit_calculation
)

-- Final Selection kolom yang relevan untuk report di dashboard
SELECT
  transaction_id,
  date,
  branch_id,
  branch_name,
  kota,
  provinsi,
  rating_cabang,
  customer_name,
  product_id,
  product_name,
  actual_price,
  discount_percentage,
  persentase_gross_laba,
  nett_sales,
  nett_profit,
  rating_transaksi
  stok_tersedia
FROM final_metrics;