SET search_path TO homeworcksql2, public;


-- Заполнение справочников

INSERT INTO customers (name, email)
SELECT
    'Customer_' || generate_series(1, 50000),
    'customer_' || generate_series(1, 50000) || '@example.com';

INSERT INTO products(name,price)
SELECT
    'Product_' || generate_series(1,50000),
    (random() * 1000 + 10)::NUMERIC(10,2);

-- Генерация 30 млн заказов (пакетами по 500к)

DO
$$
    DECLARE
        batch_size INT := 500000;
        total_batches INT := 60; -- 60 * 500k = 30 млн
        i INT;
        inserted_count BIGINT := 0;
    BEGIN
        FOR i IN 1..total_batches LOOP
                BEGIN
                    INSERT INTO orders (customer_id, product_id, created_at, amount, status)
                    SELECT
                        (random() * 49999 + 1)::INT, -- от 1 до 50000
                        (random() * 49999 + 1)::INT, -- ← ИСПРАВЛЕНО: от 1 до 50000
                        NOW() - (random() * 1095) * INTERVAL '1 day', -- 3 года назад
                        (random() * 1000 + 1)::NUMERIC(10, 2),
                        CASE (random() * 5)::INT -- ← ИСПРАВЛЕНО: 5 вариантов
                            WHEN 0 THEN 'pending'
                            WHEN 1 THEN 'processing'
                            WHEN 2 THEN 'shipped'
                            WHEN 3 THEN 'delivered'
                            WHEN 4 THEN 'cancelled'
                            END
                    FROM generate_series(1, batch_size);

                    inserted_count := inserted_count + batch_size;

                    IF i % 5 = 0 THEN
                        RAISE NOTICE 'Пакет %, всего вставлено % млн строк', i, inserted_count::FLOAT / 1000000;
                    END IF;

                    COMMIT;

                EXCEPTION WHEN OTHERS THEN
                    RAISE WARNING 'Ошибка в пакете %: %', i, SQLERRM;
                    ROLLBACK;
                    -- Продолжаем со следующим пакетом
                    CONTINUE;
                END;
            END LOOP;

        RAISE NOTICE 'Готово. Всего вставлено примерно % строк', inserted_count;
    END
$$;


--Триггер


UPDATE orders SET amount = 555.55 WHERE order_id = 3446;