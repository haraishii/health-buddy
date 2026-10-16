-- Three fictional test users from the brief's "Test data" section, with 14 days of logs ending today.
-- All passwords: password123
--
--   annida@example.com  Person A (student):  sleep ~1.5 h lower in week 2, protein below target, high stress on 3 days
--   bima@example.com    Person B (active):   exercise 5-6 days a week, regular meals, lower stress on exercise days
--   citra@example.com   Person C (inactive): low steps, frequent fried snacks, water below target

INSERT INTO users (email, password_hash, name, status, birth_date, sex, height_cm, weight_kg) VALUES
('annida@example.com', '$2b$10$zwzoUluaAWFoPtb58QBACeeUboTpX.JXFpyf4gTLTAJe32cKWIt2S', 'Annida', 'Student', '2006-03-14', 'F', 158, 52),
('bima@example.com', '$2b$10$zwzoUluaAWFoPtb58QBACeeUboTpX.JXFpyf4gTLTAJe32cKWIt2S', 'Bima', 'Student', '2004-07-02', 'M', 172, 68),
('citra@example.com', '$2b$10$zwzoUluaAWFoPtb58QBACeeUboTpX.JXFpyf4gTLTAJe32cKWIt2S', 'Citra', 'Student', '2005-11-20', 'F', 160, 63);

-- d = 0 is 13 days ago, d = 13 is today. Week 1 is d 0-6, week 2 is d 7-13.
CREATE TEMP TABLE seed_days ON COMMIT DROP AS
SELECT d, current_date - 13 + d AS day
FROM generate_series(0, 13) AS d;

-- Bima's rest days; used by both exercise and stress so stress drops on exercise days.
CREATE TEMP TABLE seed_bima_rest ON COMMIT DROP AS
SELECT unnest(ARRAY[3, 5, 10]) AS d;

-- Meals: each plan row picks foods[d mod n], so the menu rotates day by day.
INSERT INTO meal_logs (user_id, logged_on, meal_time, food_id, servings,
                       calories_kcal, protein_g, carbs_g, fat_g, fiber_g, sugar_g, sodium_mg)
SELECT u.id, s.day, p.meal_time, f.id, p.servings,
       f.calories_kcal * p.servings, f.protein_g * p.servings, f.carbs_g * p.servings, f.fat_g * p.servings,
       f.fiber_g * p.servings, f.sugar_g * p.servings, f.sodium_mg * p.servings
FROM (VALUES
    ('annida@example.com', 'breakfast', ARRAY['MK001', 'MK013', 'MK037'], 1.0, 1),
    ('annida@example.com', 'lunch', ARRAY['MK007', 'MK031', 'MK002'], 1.0, 1),
    ('annida@example.com', 'snack', ARRAY['MK006', 'MK032', 'MK035'], 1.0, 1),
    ('annida@example.com', 'dinner', ARRAY['MK011'], 1.5, 1),
    ('annida@example.com', 'dinner', ARRAY['MK021', 'MK022', 'MK024'], 1.0, 1),
    ('bima@example.com', 'breakfast', ARRAY['MK037', 'MK001'], 1.0, 1),
    ('bima@example.com', 'breakfast', ARRAY['MK017'], 2.0, 1),
    ('bima@example.com', 'lunch', ARRAY['MK011'], 2.0, 1),
    ('bima@example.com', 'lunch', ARRAY['MK016', 'MK015', 'MK019'], 1.0, 1),
    ('bima@example.com', 'lunch', ARRAY['MK025'], 1.0, 1),
    ('bima@example.com', 'snack', ARRAY['MK009', 'MK010', 'MK028'], 1.0, 1),
    ('bima@example.com', 'dinner', ARRAY['MK011'], 1.5, 1),
    ('bima@example.com', 'dinner', ARRAY['MK016', 'MK020', 'MK021'], 1.0, 1),
    ('bima@example.com', 'dinner', ARRAY['MK024', 'MK026'], 1.0, 1),
    ('citra@example.com', 'breakfast', ARRAY['MK037', 'MK013'], 1.0, 1),
    ('citra@example.com', 'lunch', ARRAY['MK030', 'MK031', 'MK007'], 1.0, 1),
    ('citra@example.com', 'snack', ARRAY['MK006', 'MK032', 'MK033'], 1.0, 1),
    ('citra@example.com', 'snack', ARRAY['MK004', 'MK035'], 1.0, 2),
    ('citra@example.com', 'dinner', ARRAY['MK011'], 1.0, 1),
    ('citra@example.com', 'dinner', ARRAY['MK015', 'MK018', 'MK019'], 1.0, 1)
) AS p (email, meal_time, foods, servings, every_n_days)
JOIN users u ON u.email = p.email
CROSS JOIN seed_days s
JOIN foods f ON f.id = p.foods[s.d % array_length(p.foods, 1) + 1]
WHERE s.d % p.every_n_days = 0;

INSERT INTO exercise_logs (user_id, logged_on, activity_id, minutes, met, weight_kg, calories_kcal)
SELECT u.id, s.day, a.id, x.minutes, a.met, u.weight_kg, round(a.met * u.weight_kg * x.minutes / 60.0, 1)
FROM (
    SELECT 'annida@example.com' AS email, d, 'OR004' AS activity_id, 25 AS minutes
    FROM seed_days WHERE d IN (1, 4, 8, 11)
    UNION ALL
    SELECT 'bima@example.com', d, (ARRAY['OR007', 'OR013', 'OR021'])[d % 3 + 1], (ARRAY[40, 60, 60])[d % 3 + 1]
    FROM seed_days WHERE d NOT IN (SELECT d FROM seed_bima_rest)
    UNION ALL
    SELECT 'citra@example.com', d, 'OR030', 30
    FROM seed_days WHERE d = 6
) AS x
JOIN users u ON u.email = x.email
JOIN seed_days s ON s.d = x.d
JOIN activities a ON a.id = x.activity_id;

INSERT INTO stress_logs (user_id, logged_on, level, factor_ids)
SELECT u.id, s.day, x.level, x.factor_ids
FROM (
    SELECT 'annida@example.com' AS email, d,
           CASE d WHEN 8 THEN 8 WHEN 10 THEN 9 WHEN 12 THEN 8 ELSE 4 + d % 3 END AS level,
           CASE WHEN d IN (8, 10, 12) THEN ARRAY['SF01', 'SF02', 'SF03'] ELSE ARRAY['SF02'] END AS factor_ids
    FROM seed_days
    UNION ALL
    SELECT 'bima@example.com', d,
           CASE WHEN d IN (SELECT d FROM seed_bima_rest) THEN 4 + d % 2 ELSE 2 + d % 2 END,
           CASE WHEN d IN (SELECT d FROM seed_bima_rest) THEN ARRAY['SF02'] ELSE ARRAY[]::text[] END
    FROM seed_days
    UNION ALL
    SELECT 'citra@example.com', d, 4 + d % 3, ARRAY['SF06']
    FROM seed_days
) AS x
JOIN users u ON u.email = x.email
JOIN seed_days s ON s.d = x.d;

-- One row per "+ 250 ml" tap: Annida 5-7 taps, Bima 9-11, Citra 3-4.
INSERT INTO water_logs (user_id, logged_on, amount_ml)
SELECT u.id, s.day, 250
FROM (VALUES ('annida@example.com', 5, 3), ('bima@example.com', 9, 3), ('citra@example.com', 3, 2)) AS w (email, base, spread)
JOIN users u ON u.email = w.email
CROSS JOIN seed_days s
CROSS JOIN LATERAL generate_series(1, w.base + s.d % w.spread) AS tap;

INSERT INTO sleep_logs (user_id, sleep_date, hours)
SELECT u.id, s.day,
       CASE u.email
           WHEN 'annida@example.com' THEN CASE WHEN s.d < 7 THEN 7.5 ELSE 6.0 END + (s.d % 3 - 1) * 0.25
           WHEN 'bima@example.com' THEN 7.5 + (s.d % 3 - 1) * 0.25
           ELSE 7.0 + (s.d % 4 - 1.5) * 0.3
       END
FROM users u
CROSS JOIN seed_days s
WHERE u.email IN ('annida@example.com', 'bima@example.com', 'citra@example.com');

INSERT INTO step_logs (user_id, step_date, steps)
SELECT u.id, s.day,
       CASE u.email
           WHEN 'annida@example.com' THEN 5000 + s.d * 739 % 2000
           WHEN 'bima@example.com' THEN 10500 + s.d * 977 % 2500
           ELSE 2600 + s.d * 431 % 1300
       END
FROM users u
CROSS JOIN seed_days s
WHERE u.email IN ('annida@example.com', 'bima@example.com', 'citra@example.com');
