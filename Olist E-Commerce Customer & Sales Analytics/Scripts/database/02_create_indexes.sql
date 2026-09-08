-- Database Indexes


-- Customers

CREATE UNIQUE INDEX IF NOT EXISTS idx_customers_customer_id
ON customers(customer_id);


-- Orders

CREATE UNIQUE INDEX IF NOT EXISTS idx_orders_order_id
ON orders(order_id);

CREATE INDEX IF NOT EXISTS idx_orders_customer_id
ON orders(customer_id);

CREATE INDEX IF NOT EXISTS idx_orders_order_status
ON orders(order_status);


-- Order Items

CREATE UNIQUE INDEX IF NOT EXISTS idx_order_items_order_item
ON order_items(order_id, order_item_id);

CREATE INDEX IF NOT EXISTS idx_order_items_product_id
ON order_items(product_id);

CREATE INDEX IF NOT EXISTS idx_order_items_seller_id
ON order_items(seller_id);


-- Payments

CREATE UNIQUE INDEX IF NOT EXISTS idx_order_payments_order_payment
ON order_payments(order_id, payment_sequential);


-- Reviews

CREATE INDEX IF NOT EXISTS idx_order_reviews_order_id
ON order_reviews(order_id);


-- Products

CREATE UNIQUE INDEX IF NOT EXISTS idx_products_product_id
ON products(product_id);

CREATE INDEX IF NOT EXISTS idx_products_category
ON products(product_category_name);


-- Sellers

CREATE UNIQUE INDEX IF NOT EXISTS idx_sellers_seller_id
ON sellers(seller_id);