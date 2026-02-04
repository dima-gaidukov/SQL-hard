SET search_path TO homeworcksql2, public;

--Запрос с JOIN 510ms

SELECT o.order_id,c.name,p.name,o.amount
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products p ON o.product_id = p.product_id
WHERE o.created_at BETWEEN '2025-01-01' AND '2025-01-31';


--Запрос с фильтром по дате 526ms

SELECT * FROM orders WHERE created_at >= '2025-01-01' AND created_at < '2025-02-01';


--С EXPLAIN
EXPLAIN ANALYZE
SELECT o.order_id, c.name, p.name, o.amount
FROM orders o
         JOIN customers c ON o.customer_id = c.customer_id
         JOIN products p ON o.product_id = p.product_id
WHERE o.created_at BETWEEN '2025-01-01' AND '2025-01-31';

EXPLAIN ANALYZE
SELECT * FROM orders WHERE created_at >= '2025-01-01' AND created_at < '2025-02-01';

-- 1. Создание индекса

CREATE INDEX idx_orders_created_at ON orders(created_at);

-- 2. Проверка плана после индекса

EXPLAIN ANALYZE
SELECT * FROM orders
WHERE created_at >= '2025-01-01' AND created_at < '2025-02-01';

-- 3. Проверка JOIN-запроса

EXPLAIN ANALYZE
SELECT o.order_id, c.name, p.name, o.amount
FROM orders o
         JOIN customers c ON o.customer_id = c.customer_id
         JOIN products p ON o.product_id = p.product_id
WHERE o.created_at BETWEEN '2025-01-01' AND '2025-01-31';

DROP INDEX idx_orders_created_at;
CREATE INDEX idx_orders_created_at ON orders(created_at);
ANALYZE orders;

-- Временное отключение Seq Scan
SET enable_seqscan = OFF;

-- Верните настройку
SET enable_seqscan = ON;

-- Проверяем запрос за январь 2025
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders
WHERE created_at >= '2025-01-01'
  AND created_at < '2025-02-01';



