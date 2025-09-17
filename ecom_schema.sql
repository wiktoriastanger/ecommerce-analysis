CREATE TABLE customers (
	customer_id	INT PRIMARY KEY,
	first_name	VARCHAR(100),
	last_name	VARCHAR(100),
	email	VARCHAR(100),
	country	VARCHAR(100),
	city	VARCHAR(100)
);

CREATE TABLE products (
	product_id	INT PRIMARY KEY,
  	product_name	VARCHAR(200),
 	 category	VARCHAR(100),
  	unit_price	DECIMAL(10,2) NOT NULL
);

CREATE TABLE orders (
  order_id	INT PRIMARY KEY,
  customer_id	INT NOT NULL,
  order_date	TIMESTAMP NOT NULL,
  payment_method	VARCHAR(50),
  order_status	VARCHAR(50),
  shipping_address	VARCHAR(255),
  CONSTRAINT	fk_orders_customer
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
  order_item_id	INT PRIMARY KEY,
  order_id	INT NOT NULL,
  product_id	INT NOT NULL,
  quantity	INT NOT NULL,
  unit_price	NUMERIC(10,2) NOT NULL,
  total_price	NUMERIC(12,2) NOT NULL,
  CONSTRAINT fk_oi_order    FOREIGN KEY (order_id)  REFERENCES orders(order_id),
  CONSTRAINT fk_oi_product  FOREIGN KEY (product_id) REFERENCES products(product_id),
  CONSTRAINT quantity_check CHECK (quantity >= 1)
);



