-- Rename the tables

ALTER TABLE olist_customers_dataset
RENAME TO customers;

ALTER TABLE olist_geolocation_dataset
RENAME TO geolocation;

ALTER TABLE olist_order_items_dataset
RENAME TO order_items;

ALTER TABLE olist_order_payments_dataset 
RENAME TO order_payments;

ALTER TABLE olist_order_reviews_dataset
RENAME TO order_reviews;

ALTER TABLE olist_orders_dataset
RENAME TO orders;

ALTER TABLE olist_products_dataset
RENAME TO products;

ALTER TABLE olist_sellers_dataset
RENAME TO sellers;

ALTER TABLE product_category_name_translation
RENAME TO category_translation;