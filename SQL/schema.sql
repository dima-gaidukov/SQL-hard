SET search_path TO homeworcksql2, public;
CREATE TABLE orders(
    order_id SERIAL PRIMARY KEY ,
    customer_id INT,
    product_id INT,
    created_at TIMESTAMP NOT NULL ,
    amount NUMERIC(10,2),
    status TEXT
);

CREATE TABLE customers(
    customer_id SERIAL PRIMARY KEY ,
    name TEXT,
    email TEXT
);

CREATE TABLE products(
    product_id SERIAL PRIMARY KEY ,
    name TEXT,
    price NUMERIC(10,2)
);

ALTER TABLE orders DROP CONSTRAINT orders_pkey;
ALTER TABLE orders ADD PRIMARY KEY (order_id,created_at);


-- Разбиваем на партиции по диапазону created_at

CREATE TABLE orders_partitioned (
                                    order_id SERIAL,
                                    customer_id INT,
                                    product_id INT,
                                    created_at TIMESTAMP NOT NULL,
                                    amount NUMERIC(10,2),
                                    status TEXT,
                                    PRIMARY KEY (order_id, created_at)
) PARTITION BY RANGE (created_at);

-- Создаем партиции для каждого месяца с 2023-01 по 2026-12
DO $$
    DECLARE
        start_date date := '2023-01-01';
        end_date date := '2027-01-01';
        current_month date := start_date;
        partition_name text;
    BEGIN
        WHILE current_month < end_date LOOP
                partition_name := 'orders_partitioned_' || to_char(current_month, 'YYYYMM');

                IF NOT EXISTS (
                    SELECT 1 FROM pg_tables
                    WHERE tablename = partition_name
                ) THEN
                    EXECUTE format(
                            'CREATE TABLE %I PARTITION OF orders_partitioned FOR VALUES FROM (%L) TO (%L)',
                            partition_name,
                            current_month,
                            current_month + interval '1 month'
                            );
                    RAISE NOTICE 'Создана партиция: %', partition_name;
                ELSE
                    RAISE NOTICE 'Партиция % уже существует', partition_name;
                END IF;

                current_month := current_month + interval '1 month';
            END LOOP;
    END $$;


-- Копируем данные из старой таблицы


INSERT INTO orders_partitioned
SELECT * FROM orders
WHERE created_at >= '2023-01-01' AND created_at < '2026-01-01';

--Переименовать таблицы

ALTER TABLE orders RENAME TO orders_old;

ALTER TABLE orders_partitioned RENAME TO orders;

--Триггер

CREATE TABLE orders_audit(
    audit_id SERIAL PRIMARY KEY ,
    order_id INT,
    old_amount NUMERIC(10,2),
    new_amount NUMERIC(10,2),
    changed_at TIMESTAMP DEFAULT now()
);

CREATE OR REPLACE FUNCTION log_order_change()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO orders_audit (order_id,old_amount,new_amount)
    VALUES (OLD.order_id, OLD.amount, NEW.amount);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER orders_audit_trg
AFTER UPDATE ON orders
FOR EACH ROW
EXECUTE PROCEDURE log_order_change();