-- DUMMY reference data for development and testing only.
-- Every row has source = 'DUMMY ...'. The numbers are rough estimates so the screens look
-- plausible; they are NOT verified against TKPI, AKG, the Compendium or any label.
-- Replace with the team's package files before release (see the brief, rule 4: never invent numbers).

INSERT INTO foods (id, name, name_en, aliases, category, cooking_method, serving, serving_grams,
                   calories_kcal, protein_g, carbs_g, fat_g, fiber_g, sugar_g, sodium_mg, source, notes) VALUES
('MK001', 'Oatmeal pisang', 'Oatmeal with banana', '{oat,oatmeal}', 'snack and breakfast', 'boiled', '1 mangkuk', 250, 320, 9, 58, 6, 6, 14, 10, 'DUMMY', 'calculated from recipe (dummy)'),
('MK002', 'Nasi ayam bowl', 'Chicken rice bowl', '{rice bowl,ricebowl}', 'mixed dish', 'stir-fried', '1 mangkuk', 350, 640, 28, 82, 18, 3, 5, 820, 'DUMMY', NULL),
('MK003', 'Es teh kurang gula', 'Iced tea, less sugar', '{es teh,teh manis}', 'drink', 'none', '1 gelas', 250, 72, 0, 18, 0, 0, 18, 5, 'DUMMY', NULL),
('MK004', 'Es teh manis', 'Sweet iced tea', '{es teh,teh manis}', 'drink', 'none', '1 gelas', 250, 120, 0, 30, 0, 0, 30, 5, 'DUMMY', NULL),
('MK005', 'Teh tawar', 'Unsweetened tea', '{teh}', 'drink', 'none', '1 gelas', 250, 2, 0, 0.5, 0, 0, 0, 5, 'DUMMY', 'no sugar variant'),
('MK006', 'Gorengan campur', 'Mixed fried snacks', '{gorengan}', 'snack and fried food', 'fried', '3 potong', 150, 430, 8, 45, 24, 3, 3, 450, 'DUMMY', NULL),
('MK007', 'Nasi goreng', 'Fried rice', '{nasgor}', 'mixed dish', 'fried', '1 piring', 300, 520, 15, 70, 18, 2, 4, 900, 'DUMMY', NULL),
('MK008', 'Gado-gado', 'Gado-gado', '{gado gado,pecel}', 'mixed dish', 'boiled', '1 piring', 300, 410, 17, 40, 22, 7, 8, 600, 'DUMMY', NULL),
('MK009', 'Pisang ambon', 'Banana', '{pisang}', 'fruit', 'raw', '1 buah sedang', 118, 105, 1.3, 27, 0.4, 3.1, 14, 1, 'DUMMY', NULL),
('MK010', 'Yogurt Yunani tawar', 'Plain Greek yogurt', '{yogurt,yoghurt}', 'snack and breakfast', 'none', '1 cup', 150, 140, 15, 6, 6, 0, 6, 55, 'DUMMY', NULL),
('MK011', 'Nasi putih', 'Steamed white rice', '{nasi}', 'staple', 'steamed', '1 centong', 100, 130, 2.7, 28, 0.3, 0.4, 0, 1, 'DUMMY', NULL),
('MK012', 'Nasi merah', 'Brown rice', '{nasi}', 'staple', 'steamed', '1 centong', 100, 112, 2.6, 23, 0.9, 1.8, 0, 5, 'DUMMY', NULL),
('MK013', 'Roti gandum', 'Whole wheat bread', '{roti}', 'staple', 'none', '2 lembar', 60, 150, 7, 25, 2, 4, 3, 270, 'DUMMY', NULL),
('MK014', 'Kentang rebus', 'Boiled potato', '{kentang}', 'staple', 'boiled', '1 buah sedang', 150, 130, 3, 30, 0.2, 3, 1, 8, 'DUMMY', NULL),
('MK015', 'Ayam goreng paha', 'Fried chicken thigh', '{ayam goreng}', 'animal-based side dish', 'fried', '1 potong', 100, 270, 25, 5, 17, 0, 0, 400, 'DUMMY', NULL),
('MK016', 'Ayam bakar', 'Grilled chicken', '{ayam}', 'animal-based side dish', 'grilled', '1 potong', 100, 200, 27, 3, 9, 0, 2, 350, 'DUMMY', NULL),
('MK017', 'Telur rebus', 'Boiled egg', '{telur}', 'animal-based side dish', 'boiled', '1 butir', 55, 78, 6.9, 0.6, 5.3, 0, 0.6, 70, 'DUMMY', NULL),
('MK018', 'Telur dadar', 'Omelette', '{telur,omelet}', 'animal-based side dish', 'fried', '1 butir', 65, 120, 7, 1, 10, 0, 0.5, 200, 'DUMMY', NULL),
('MK019', 'Lele goreng', 'Fried catfish', '{pecel lele,lele}', 'animal-based side dish', 'fried', '1 ekor', 100, 230, 17, 5, 15, 0, 0, 300, 'DUMMY', NULL),
('MK020', 'Rendang daging', 'Beef rendang', '{rendang}', 'animal-based side dish', 'boiled', '1 potong', 75, 195, 15, 5, 13, 1, 2, 380, 'DUMMY', 'slow-cooked; nearest cooking_method'),
('MK021', 'Tempe goreng', 'Fried tempeh', '{tempe}', 'plant-based side dish', 'fried', '2 potong', 50, 160, 9.5, 5, 11, 1, 0, 10, 'DUMMY', NULL),
('MK022', 'Tahu bacem', 'Sweet braised tofu', '{tahu}', 'plant-based side dish', 'boiled', '2 potong', 80, 120, 8, 10, 5, 1, 7, 250, 'DUMMY', NULL),
('MK023', 'Kacang merah rebus', 'Boiled red beans', '{kacang merah}', 'plant-based side dish', 'boiled', '1/2 mangkuk', 90, 115, 7.8, 20, 0.5, 6, 0.3, 2, 'DUMMY', NULL),
('MK024', 'Sayur bayam bening', 'Clear spinach soup', '{bayam}', 'vegetable', 'boiled', '1 mangkuk', 200, 40, 3, 6, 0.5, 2.5, 2, 300, 'DUMMY', NULL),
('MK025', 'Tumis kangkung', 'Stir-fried water spinach', '{kangkung,cah kangkung}', 'vegetable', 'stir-fried', '1 porsi', 100, 90, 3, 5, 6, 2, 1.5, 400, 'DUMMY', NULL),
('MK026', 'Sayur asem', 'Tamarind vegetable soup', '{sayur asam}', 'vegetable', 'boiled', '1 mangkuk', 200, 70, 2.5, 12, 1, 3, 5, 450, 'DUMMY', NULL),
('MK027', 'Pepaya', 'Papaya', '{}', 'fruit', 'raw', '1 potong', 150, 65, 0.7, 16, 0.4, 2.5, 12, 12, 'DUMMY', NULL),
('MK028', 'Apel', 'Apple', '{apple}', 'fruit', 'raw', '1 buah sedang', 180, 95, 0.5, 25, 0.3, 4.4, 19, 2, 'DUMMY', NULL),
('MK029', 'Soto ayam', 'Chicken soto', '{soto}', 'mixed dish', 'boiled', '1 mangkuk', 350, 250, 18, 15, 12, 1.5, 2, 1000, 'DUMMY', NULL),
('MK030', 'Bakso kuah', 'Meatball soup', '{bakso,baso}', 'mixed dish', 'boiled', '1 mangkuk', 350, 300, 16, 30, 14, 1.5, 3, 1100, 'DUMMY', NULL),
('MK031', 'Mie ayam', 'Chicken noodles', '{mi ayam,mie}', 'mixed dish', 'boiled', '1 mangkuk', 300, 450, 20, 60, 15, 2, 5, 1200, 'DUMMY', NULL),
('MK032', 'Pisang goreng', 'Banana fritter', '{gorengan,pisgor}', 'snack and fried food', 'fried', '1 buah', 80, 200, 1.5, 30, 8, 1.5, 12, 60, 'DUMMY', NULL),
('MK033', 'Bakwan sayur', 'Vegetable fritter', '{bakwan,gorengan,bala-bala}', 'snack and fried food', 'fried', '1 buah', 50, 140, 2, 15, 8, 1, 1, 180, 'DUMMY', NULL),
('MK034', 'Air putih', 'Water', '{air,air mineral}', 'drink', 'none', '1 gelas', 250, 0, 0, 0, 0, 0, 0, 0, 'DUMMY', NULL),
('MK035', 'Kopi susu gula aren', 'Iced palm sugar latte', '{kopi susu,es kopi}', 'drink', 'none', '1 gelas', 250, 190, 5, 30, 6, 0, 25, 80, 'DUMMY', NULL),
('MK036', 'Susu UHT tawar', 'Plain UHT milk', '{susu}', 'drink', 'none', '1 kotak', 200, 125, 6, 9, 7, 0, 9, 100, 'DUMMY', NULL),
('MK037', 'Bubur ayam', 'Chicken porridge', '{bubur}', 'snack and breakfast', 'boiled', '1 mangkuk', 300, 300, 12, 45, 8, 1, 2, 800, 'DUMMY', NULL);

-- Fictional products: brand "DUMMY" and barcodes in the in-store prefix 200, so they never match a real product.
INSERT INTO packaged_products (barcode, product_group, brand, product_name, variant, package_size, serving_size,
                               serving_unit, servings_per_package, calories_kcal, protein_g, carbs_g, fat_g,
                               sugar_g, fiber_g, sodium_mg, photo_front, photo_label, notes) VALUES
('2000000000015', 'packaged drink', 'DUMMY', 'Teh Melati Botol', 'less sugar', '350 ml', 350, 'ml', 1, 70, 0, 18, 0, 17, NULL, 10, '2000000000015_front.jpg', '2000000000015_label.jpg', 'label does not list fiber'),
('2000000000022', 'packaged drink', 'DUMMY', 'Minuman Isotonik', NULL, '500 ml', 250, 'ml', 2, 60, 0, 15, 0, 14, NULL, 120, '2000000000022_front.jpg', '2000000000022_label.jpg', NULL),
('2000000000039', 'snack', 'DUMMY', 'Keripik Kentang', 'original', '68 g', 30, 'g', 2.3, 160, 2, 15, 10, 1, 1, 170, '2000000000039_front.jpg', '2000000000039_label.jpg', NULL),
('2000000000046', 'snack', 'DUMMY', 'Wafer Cokelat', 'chocolate', '110 g', 22, 'g', 5, 110, 1, 14, 6, 8, 0, 25, '2000000000046_front.jpg', '2000000000046_label.jpg', NULL),
('2000000000053', 'instant food', 'DUMMY', 'Mi Instan Goreng', NULL, '85 g', 85, 'g', 1, 380, 8, 54, 14, 6, 2, 1000, '2000000000053_front.jpg', '2000000000053_label.jpg', NULL),
('2000000000060', 'milk and yogurt', 'DUMMY', 'Susu UHT Cokelat', 'chocolate', '200 ml', 200, 'ml', 1, 140, 5, 21, 4, 18, 0, 100, '2000000000060_front.jpg', '2000000000060_label.jpg', NULL),
('2000000000077', 'milk and yogurt', 'DUMMY', 'Yogurt Minum Stroberi', 'strawberry', '200 ml', 200, 'ml', 1, 150, 5, 26, 3, 22, 0, 80, '2000000000077_front.jpg', '2000000000077_label.jpg', NULL),
('2000000000084', 'bread, cereal, oats', 'DUMMY', 'Oat Instan', 'plain', '800 g', 40, 'g', 20, 150, 5, 27, 3, 0.5, 4, 0, '2000000000084_front.jpg', '2000000000084_label.jpg', NULL),
('2000000000091', 'biscuit', 'DUMMY', 'Biskuit Gandum', NULL, '150 g', 30, 'g', 5, 140, 2, 20, 6, 5, 2, 120, '2000000000091_front.jpg', '2000000000091_label.jpg', NULL),
('2000000000107', 'other', 'DUMMY', 'Selai Kacang', 'creamy', '170 g', 32, 'g', 5.3, 190, 7, 7, 16, 3, 2, 140, '2000000000107_front.jpg', '2000000000107_label.jpg', NULL);

-- MET values are rough estimates and source_code is left empty on purpose: copy both from the
-- latest Compendium of Physical Activities when the real Package 3 is filled in.
INSERT INTO activities (id, activity_name, activity_name_en, category, activity_group, met, source_code, source, notes) VALUES
('OR001', 'Jalan pelan 3,2 km/jam', 'Slow walking 3.2 km/h', 'walking and running', 'walk', 2.8, NULL, 'DUMMY', NULL),
('OR002', 'Jalan santai 4,8 km/jam', 'Leisurely walking 4.8 km/h', 'walking and running', 'walk', 3.5, NULL, 'DUMMY', NULL),
('OR003', 'Jalan cepat 6,4 km/jam', 'Brisk walking 6.4 km/h', 'walking and running', 'walk', 5.0, NULL, 'DUMMY', NULL),
('OR004', 'Jalan kaki ke kampus/sekolah', 'Walking to campus or school', 'walking and running', 'walk', 4.0, NULL, 'DUMMY', NULL),
('OR005', 'Naik tangga', 'Climbing stairs', 'walking and running', 'walk', 4.0, NULL, 'DUMMY', NULL),
('OR006', 'Jogging', 'Jogging', 'walking and running', 'run', 7.0, NULL, 'DUMMY', NULL),
('OR007', 'Lari 8 km/jam', 'Running 8 km/h', 'walking and running', 'run', 8.3, NULL, 'DUMMY', NULL),
('OR008', 'Lari 10 km/jam', 'Running 10 km/h', 'walking and running', 'run', 9.8, NULL, 'DUMMY', NULL),
('OR009', 'Bersepeda santai', 'Leisure cycling', 'cycling', 'cycling', 4.0, NULL, 'DUMMY', NULL),
('OR010', 'Bersepeda cepat', 'Fast cycling', 'cycling', 'cycling', 8.0, NULL, 'DUMMY', NULL),
('OR011', 'Renang santai', 'Leisure swimming', 'swimming', 'swim', 6.0, NULL, 'DUMMY', NULL),
('OR012', 'Angkat beban ringan-sedang', 'Weight lifting, light to moderate', 'weights and calisthenics', 'gym', 3.5, NULL, 'DUMMY', NULL),
('OR013', 'Angkat beban berat', 'Weight lifting, vigorous', 'weights and calisthenics', 'gym', 6.0, NULL, 'DUMMY', NULL),
('OR014', 'Push-up dan sit-up', 'Push-ups and sit-ups', 'weights and calisthenics', 'gym', 3.8, NULL, 'DUMMY', NULL),
('OR015', 'HIIT', 'HIIT', 'weights and calisthenics', 'gym', 8.0, NULL, 'DUMMY', NULL),
('OR016', 'Lompat tali', 'Jump rope', 'weights and calisthenics', 'gym', 11.0, NULL, 'DUMMY', NULL),
('OR017', 'Yoga hatha', 'Hatha yoga', 'aerobics and yoga', 'yoga', 2.5, NULL, 'DUMMY', NULL),
('OR018', 'Pilates', 'Pilates', 'aerobics and yoga', 'yoga', 3.0, NULL, 'DUMMY', NULL),
('OR019', 'Senam aerobik', 'Aerobics', 'aerobics and yoga', 'other', 7.0, NULL, 'DUMMY', NULL),
('OR020', 'Zumba', 'Zumba', 'aerobics and yoga', 'other', 6.5, NULL, 'DUMMY', NULL),
('OR021', 'Futsal', 'Futsal', 'ball sports', 'sports', 7.0, NULL, 'DUMMY', NULL),
('OR022', 'Sepak bola', 'Football', 'ball sports', 'sports', 8.0, NULL, 'DUMMY', NULL),
('OR023', 'Bola basket', 'Basketball', 'ball sports', 'sports', 6.5, NULL, 'DUMMY', NULL),
('OR024', 'Bola voli rekreasi', 'Recreational volleyball', 'ball sports', 'sports', 3.0, NULL, 'DUMMY', NULL),
('OR025', 'Bulu tangkis rekreasi', 'Recreational badminton', 'racket sports', 'sports', 5.5, NULL, 'DUMMY', NULL),
('OR026', 'Tenis meja', 'Table tennis', 'racket sports', 'sports', 4.0, NULL, 'DUMMY', NULL),
('OR027', 'Pencak silat', 'Pencak silat', 'martial arts', 'sports', 10.0, NULL, 'DUMMY', 'taken from closest category'),
('OR028', 'Taekwondo', 'Taekwondo', 'martial arts', 'sports', 10.0, NULL, 'DUMMY', NULL),
('OR029', 'Mendaki gunung', 'Hiking', 'outdoor', 'other', 6.0, NULL, 'DUMMY', NULL),
('OR030', 'Membersihkan rumah', 'House cleaning', 'daily activities', 'daily', 3.3, NULL, 'DUMMY', NULL),
('OR031', 'Berkebun', 'Gardening', 'daily activities', 'daily', 3.8, NULL, 'DUMMY', NULL);

-- Placeholders only. The brief requires the exact text of a validated Indonesian version (do not translate).
-- reverse_scored follows the usual PSS-10 layout (items 4, 5, 7, 8); verify against the chosen article.
INSERT INTO stress_questions (question_id, text_id, reverse_scored, answer_options, source)
SELECT format('P%s', lpad(n::text, 2, '0')),
       format('[DUMMY] Pertanyaan %s - ganti dengan teks PSS-10 versi Indonesia yang tervalidasi', n),
       n IN (4, 5, 7, 8),
       '0 = tidak pernah, 1 = hampir tidak pernah, 2 = kadang-kadang, 3 = cukup sering, 4 = sangat sering',
       'DUMMY'
FROM generate_series(1, 10) AS n;

INSERT INTO stress_score_bands (category, score_min, score_max, scale_min, scale_max, short_message, support_advice, source) VALUES
('Low', 0, 13, 1, 3, 'Kamu terlihat cukup tenang. Pertahankan tidur dan aktivitasmu.', NULL, 'DUMMY'),
('Medium', 14, 26, 4, 6, 'Sedikit tegang itu wajar. Coba tarik napas pelan 1 menit atau jalan sebentar.', NULL, 'DUMMY'),
('High', 27, 40, 7, 10, 'Sepertinya kamu sedang berat. Istirahat sejenak dan jangan memendamnya sendiri.',
 'Ceritakan ke orang yang kamu percaya atau tenaga profesional. [DUMMY: isi kontak layanan kesehatan jiwa resmi setelah diverifikasi di situs Kemenkes]', 'DUMMY');

INSERT INTO stress_factors (id, name, name_en, sort_order) VALUES
('SF01', 'Ujian', 'Exams', 1),
('SF02', 'Tugas', 'Assignments', 2),
('SF03', 'Tidur', 'Sleep', 3),
('SF04', 'Teman', 'Friends', 4),
('SF05', 'Keluarga', 'Family', 5),
('SF06', 'Uang', 'Money', 6);

-- Approximate AKG 2019 figures written from memory: check every value against Permenkes No. 28 of 2019.
INSERT INTO nutrition_targets (group_name, age_min, age_max, sex, life_stage, values_are_additions, reference_weight_kg,
                               reference_height_cm, energy_kcal, protein_g, fat_g, carbs_g, fiber_g, water_ml, source) VALUES
('10-12 years', 10, 12, 'M', 'general', false, 36, 145, 2000, 50, 65, 300, 28, 1850, 'DUMMY (AKG 2019, unverified)'),
('13-15 years', 13, 15, 'M', 'general', false, 50, 163, 2400, 70, 80, 350, 34, 2100, 'DUMMY (AKG 2019, unverified)'),
('16-18 years', 16, 18, 'M', 'general', false, 60, 168, 2650, 75, 85, 400, 37, 2300, 'DUMMY (AKG 2019, unverified)'),
('19-29 years', 19, 29, 'M', 'general', false, 60, 168, 2650, 65, 75, 430, 37, 2500, 'DUMMY (AKG 2019, unverified)'),
('30-49 years', 30, 49, 'M', 'general', false, 60, 166, 2550, 65, 70, 415, 36, 2500, 'DUMMY (AKG 2019, unverified)'),
('50-64 years', 50, 64, 'M', 'general', false, 60, 166, 2150, 65, 60, 340, 30, 2500, 'DUMMY (AKG 2019, unverified)'),
('65-80 years', 65, 80, 'M', 'general', false, 58, 164, 1800, 64, 50, 275, 25, 1800, 'DUMMY (AKG 2019, unverified)'),
('80+ years', 81, NULL, 'M', 'general', false, 58, 164, 1600, 64, 45, 235, 22, 1600, 'DUMMY (AKG 2019, unverified)'),
('10-12 years', 10, 12, 'F', 'general', false, 38, 147, 1900, 55, 65, 280, 27, 1850, 'DUMMY (AKG 2019, unverified)'),
('13-15 years', 13, 15, 'F', 'general', false, 48, 156, 2050, 65, 70, 300, 29, 2100, 'DUMMY (AKG 2019, unverified)'),
('16-18 years', 16, 18, 'F', 'general', false, 52, 159, 2100, 65, 70, 300, 29, 2150, 'DUMMY (AKG 2019, unverified)'),
('19-29 years', 19, 29, 'F', 'general', false, 55, 159, 2250, 60, 65, 360, 32, 2350, 'DUMMY (AKG 2019, unverified)'),
('30-49 years', 30, 49, 'F', 'general', false, 56, 158, 2150, 60, 60, 340, 30, 2350, 'DUMMY (AKG 2019, unverified)'),
('50-64 years', 50, 64, 'F', 'general', false, 56, 158, 1800, 60, 50, 280, 25, 2350, 'DUMMY (AKG 2019, unverified)'),
('65-80 years', 65, 80, 'F', 'general', false, 53, 157, 1550, 58, 45, 230, 22, 1550, 'DUMMY (AKG 2019, unverified)'),
('80+ years', 81, NULL, 'F', 'general', false, 53, 157, 1400, 58, 40, 200, 20, 1400, 'DUMMY (AKG 2019, unverified)'),
('pregnant trimester 1', 10, NULL, 'F', 'pregnant_t1', true, NULL, NULL, 180, 1, 2.3, 25, 3, 300, 'DUMMY (AKG 2019, unverified)'),
('pregnant trimester 2', 10, NULL, 'F', 'pregnant_t2', true, NULL, NULL, 300, 10, 2.3, 40, 4, 300, 'DUMMY (AKG 2019, unverified)'),
('pregnant trimester 3', 10, NULL, 'F', 'pregnant_t3', true, NULL, NULL, 300, 30, 2.3, 40, 4, 300, 'DUMMY (AKG 2019, unverified)'),
('breastfeeding 0-6 months', 10, NULL, 'F', 'breastfeeding_0_6m', true, NULL, NULL, 330, 20, 2.2, 45, 5, 800, 'DUMMY (AKG 2019, unverified)'),
('breastfeeding 7-12 months', 10, NULL, 'F', 'breastfeeding_7_12m', true, NULL, NULL, 400, 15, 2.2, 55, 6, 650, 'DUMMY (AKG 2019, unverified)');

INSERT INTO sleep_recommendations (age_min, age_max, sleep_hours_min, sleep_hours_max, source) VALUES
(6, 13, 9, 11, 'DUMMY (sleep body guidance, unverified)'),
(14, 17, 8, 10, 'DUMMY (sleep body guidance, unverified)'),
(18, 64, 7, 9, 'DUMMY (sleep body guidance, unverified)'),
(65, NULL, 7, 8, 'DUMMY (sleep body guidance, unverified)');

INSERT INTO daily_intake_limits (nutrient, daily_limit, unit, source) VALUES
('sugar', 50, 'g', 'DUMMY (Permenkes 30/2013, unverified)'),
('sodium', 2000, 'mg', 'DUMMY (Permenkes 30/2013, unverified)'),
('total_fat', 67, 'g', 'DUMMY (Permenkes 30/2013, unverified)');

INSERT INTO activity_recommendations (age_group, age_min, age_max, recommendation, unit, source) VALUES
('5-17 years', 5, 17, 'average of 60 minutes per day of moderate-to-vigorous activity', 'minutes per day', 'DUMMY (WHO 2020, unverified)'),
('18-64 years', 18, 64, '150-300 minutes of moderate activity per week', 'minutes per week', 'DUMMY (WHO 2020, unverified)'),
('65+ years', 65, NULL, '150-300 minutes of moderate activity per week, plus balance training', 'minutes per week', 'DUMMY (WHO 2020, unverified)');

INSERT INTO app_defaults (key, value, notes) VALUES
('steps_target', 8000, 'Placeholder from the prototype; the real value is a developer and expert decision');

-- Draft rules, NOT approved by a nutritionist. The API ignores unapproved rules unless
-- ALLOW_DRAFT_LABEL_RULES=true (set in .env.example for local testing).
INSERT INTO food_label_rules (label_name, applies_to, condition, nutrient, operator, threshold_value, basis, unit_and_basis, rule_basis) VALUES
('Healthy', 'all foods', 'fat at most 10 g per serving', 'fat_g', '<=', 10, 'per_serving', 'grams per serving', 'DUMMY draft'),
('Healthy', 'all foods', 'sugar at most 15 g per serving', 'sugar_g', '<=', 15, 'per_serving', 'grams per serving', 'DUMMY draft'),
('Healthy', 'solid foods only', 'fiber at least 3 g per serving', 'fiber_g', '>=', 3, 'per_serving', 'grams per serving', 'DUMMY draft'),
('High fat', 'all foods', 'fat more than 20 g per serving', 'fat_g', '>', 20, 'per_serving', 'grams per serving', 'DUMMY draft'),
('High sugar', 'all foods', 'sugar more than 20 g per serving', 'sugar_g', '>', 20, 'per_serving', 'grams per serving', 'DUMMY draft'),
('High sodium', 'all foods', 'sodium more than 800 mg per serving', 'sodium_mg', '>', 800, 'per_serving', 'milligrams per serving', 'DUMMY draft'),
('High protein', 'solid foods only', 'protein at least 20 g per serving', 'protein_g', '>=', 20, 'per_serving', 'grams per serving', 'DUMMY draft');

INSERT INTO coach_tips (id, topic, trigger_condition, tip_text, source) VALUES
('TP001', 'sleep', 'weekly average sleep dropped by more than 1 hour compared with last week', 'Tidurmu berkurang minggu ini. Coba tidur 30 menit lebih awal malam ini.', 'DUMMY'),
('TP002', 'sleep', 'last night sleep below the minimum recommendation', 'Semalam tidurmu kurang. Kurangi layar 1 jam sebelum tidur agar lebih cepat terlelap.', 'DUMMY'),
('TP003', 'sleep', 'bedtime varies by more than 2 hours across the week', 'Jam tidur yang teratur membantu tubuh pulih. Coba tidur di jam yang sama setiap malam.', 'DUMMY'),
('TP004', 'food and nutrition', 'fried snacks logged on 3 or more days this week', 'Gorengan cukup sering minggu ini. Ganti satu camilan dengan buah, yuk.', 'DUMMY'),
('TP005', 'food and nutrition', 'no vegetables logged today', 'Belum ada sayur hari ini. Isi setengah piringmu dengan sayur dan buah.', 'DUMMY'),
('TP006', 'food and nutrition', 'calories today above 110% of target', 'Asupan hari ini sudah cukup banyak. Pilih makan malam yang ringan dan berserat.', 'DUMMY'),
('TP007', 'protein', 'protein below 70% of target by evening', 'Proteinmu masih kurang. Tambahkan telur, tempe, tahu, atau ayam di makan malam.', 'DUMMY'),
('TP008', 'protein', 'protein below target on 4 or more days this week', 'Protein sering di bawah target. Coba sertakan lauk berprotein di setiap makan.', 'DUMMY'),
('TP009', 'protein', 'breakfast has less than 5 g protein', 'Sarapan dengan protein bikin kenyang lebih lama. Coba tambah telur rebus.', 'DUMMY'),
('TP010', 'drinking water', 'water below 50% of target by afternoon', 'Minummu masih sedikit. Isi botol minum dan taruh di dekatmu.', 'DUMMY'),
('TP011', 'drinking water', 'sweet drinks logged more often than water today', 'Minuman manis cukup banyak hari ini. Selingi dengan air putih, ya.', 'DUMMY'),
('TP012', 'drinking water', 'water target reached', 'Target minum tercapai! Pertahankan kebiasaan baik ini.', 'DUMMY'),
('TP013', 'activity', 'steps below 50% of target by evening', 'Langkahmu masih sedikit. Jalan kaki 15 menit setelah makan bisa membantu.', 'DUMMY'),
('TP014', 'activity', 'no exercise logged in the last 3 days', 'Sudah 3 hari tanpa olahraga. Coba aktivitas ringan 20 menit hari ini.', 'DUMMY'),
('TP015', 'activity', 'exercise logged on 5 or more days this week', 'Kamu aktif sekali minggu ini! Jangan lupa istirahat dan cukup minum.', 'DUMMY'),
('TP016', 'stress', 'stress level 7 or higher today', 'Hari ini terasa berat. Coba latihan napas 1 menit di Stress Check.', 'DUMMY'),
('TP017', 'stress', 'stress lower on exercise days than on rest days', 'Stresmu lebih rendah saat berolahraga. Jalan santai bisa jadi penyegar.', 'DUMMY'),
('TP018', 'stress', 'stress level 7 or higher on 3 or more days this week', 'Minggu ini cukup menekan. Bicarakan dengan orang yang kamu percaya.', 'DUMMY');

INSERT INTO coach_quick_questions (id, question_text, question_text_en, topic, is_default, sort_order) VALUES
('QQ01', 'Kenapa aku merasa capek?', 'Why am I feeling tired?', 'sleep', true, 1),
('QQ02', 'Aku sebaiknya makan apa hari ini?', 'What should I eat today?', 'food and nutrition', true, 2),
('QQ03', 'Bagaimana cara mengurangi stres?', 'How can I reduce my stress?', 'stress', true, 3),
('QQ04', 'Analisis progres mingguanku', 'Analyze my weekly progress', 'general', true, 4),
('QQ05', 'Bagaimana supaya bisa tidur lebih cepat?', 'How do I fall asleep earlier?', 'sleep', false, 5),
('QQ06', 'Camilan apa yang lebih sehat dari gorengan?', 'What snacks are healthier than fried food?', 'food and nutrition', false, 6),
('QQ07', 'Apa yang sebaiknya dimakan sebelum ujian?', 'What should I eat before an exam?', 'food and nutrition', false, 7),
('QQ08', 'Bagaimana cara memenuhi target protein?', 'How can I reach my protein target?', 'protein', false, 8),
('QQ09', 'Berapa banyak aku harus minum?', 'How much water should I drink?', 'drinking water', false, 9),
('QQ10', 'Olahraga apa yang cocok di sela kuliah?', 'What exercise fits between classes?', 'activity', false, 10),
('QQ11', 'Bagaimana cara rutin olahraga?', 'How do I make exercise a habit?', 'activity', false, 11),
('QQ12', 'Kenapa stresku naik minggu ini?', 'Why did my stress go up this week?', 'stress', false, 12);

INSERT INTO coach_restricted_topics (id, topic, example_questions, safe_answer, support_referral) VALUES
('RT01', 'disease diagnosis', '{"Apa aku kena diabetes?","Gejalaku ini penyakit apa?"}', 'Aku tidak bisa menilai penyakit. Untuk keluhan seperti ini, sebaiknya periksa ke dokter atau puskesmas.', 'Dokter atau puskesmas terdekat'),
('RT02', 'drug doses or choices', '{"Obat apa untuk sakit kepala?","Berapa dosis paracetamol?"}', 'Soal obat dan dosis, tanyakan ke dokter atau apoteker supaya aman untukmu.', 'Dokter atau apoteker'),
('RT03', 'extreme diets', '{"Bagaimana turun 10 kg sebulan?","Boleh makan 500 kalori sehari?"}', 'Penurunan berat badan yang terlalu cepat bisa berisiko. Ahli gizi bisa bantu buat rencana yang aman.', 'Ahli gizi atau dokter'),
('RT04', 'prolonged fasting', '{"Boleh tidak makan 3 hari?","Puasa air seminggu aman?"}', 'Tidak makan dalam waktu lama bisa membahayakan. Bicarakan dulu dengan dokter atau ahli gizi.', 'Dokter atau ahli gizi'),
('RT05', 'eating disorders', '{"Aku sering muntahkan makanan","Aku takut sekali gemuk"}', 'Terima kasih sudah cerita. Perasaan ini penting untuk dibicarakan dengan orang yang kamu percaya dan tenaga profesional.', '[DUMMY: isi layanan resmi setelah diverifikasi di situs Kemenkes]'),
('RT06', 'self-harm thoughts', '{"Aku ingin menyakiti diriku","Aku tidak ingin hidup lagi"}', 'Aku senang kamu mau bercerita. Kamu tidak sendirian; segera hubungi orang terdekat atau layanan bantuan sekarang.', '[DUMMY: isi nomor layanan krisis resmi setelah diverifikasi di situs Kemenkes]'),
('RT07', 'pregnancy', '{"Aku hamil, boleh olahraga apa?","Makanan apa untuk ibu hamil?"}', 'Kebutuhan saat hamil berbeda untuk tiap orang. Bidan atau dokter kandungan bisa memberi saran yang tepat.', 'Bidan atau dokter kandungan'),
('RT08', 'special medical conditions', '{"Aku punya penyakit jantung, boleh lari?","Diet untuk penderita ginjal?"}', 'Dengan kondisi medis khusus, saran olahraga dan makan sebaiknya dari dokter yang merawatmu.', 'Dokter yang merawat'),
('RT09', 'supplements and weight-loss products', '{"Suplemen pelangsing apa yang bagus?","Boleh minum pil diet?"}', 'Aku tidak bisa merekomendasikan suplemen atau produk pelangsing. Tanyakan ke dokter atau apoteker.', 'Dokter atau apoteker'),
('RT10', 'alcohol and drugs', '{"Berapa banyak alkohol yang aman?","Gimana cara berhenti merokok cepat?"}', 'Untuk topik ini, tenaga kesehatan bisa membantu dengan cara yang aman dan sesuai kondisimu.', 'Dokter atau puskesmas terdekat');

INSERT INTO reminder_texts (id, time_of_day, kind, message_text) VALUES
('RM01', 'morning', 'daily_check_in', 'Selamat pagi! Jangan lupa sarapan, ya.'),
('RM02', 'morning', 'daily_check_in', 'Awali hari dengan segelas air putih.'),
('RM03', 'morning', 'daily_check_in', 'Sudah catat jam tidurmu semalam?'),
('RM04', 'morning', 'daily_check_in', 'Jalan kaki ke kampus? Langkahmu akan tercatat otomatis.'),
('RM05', 'afternoon', 'daily_check_in', 'Waktunya makan siang. Jangan lupa lauk berprotein.'),
('RM06', 'afternoon', 'daily_check_in', 'Sudah minum air siang ini? Yuk isi botolmu.'),
('RM07', 'afternoon', 'daily_check_in', 'Regangkan badan 5 menit di sela kuliah.'),
('RM08', 'afternoon', 'daily_check_in', 'Bagaimana perasaanmu siang ini? Coba Stress Check.'),
('RM09', 'evening', 'daily_check_in', 'Catat makan malammu agar ringkasan hari ini lengkap.'),
('RM10', 'evening', 'daily_check_in', 'Sudah olahraga hari ini? Catat aktivitasmu, yuk.'),
('RM11', 'evening', 'bedtime', 'Sebentar lagi waktunya tidur. Kurangi layar, ya.'),
('RM12', 'evening', 'weekly_summary', 'Ringkasan mingguanmu sudah siap. Lihat progresmu!');

INSERT INTO insight_templates (id, topic, trigger_key, template_text, source) VALUES
('IN01', 'stress', 'stress_lower_on_exercise_days', 'Stresmu turun {percent}% di hari kamu berolahraga.', 'DUMMY'),
('IN02', 'sleep', 'sleep_drop_vs_last_week', 'Rata-rata tidurmu turun {hours} jam dibanding minggu lalu.', 'DUMMY'),
('IN03', 'protein', 'protein_below_target_days', 'Protein di bawah target pada {days} dari 7 hari terakhir.', 'DUMMY'),
('IN04', 'stress', 'high_stress_days', 'Stresmu tinggi pada {days} hari minggu ini.', 'DUMMY'),
('IN05', 'activity', 'steps_change_vs_last_week', 'Langkah harianmu berubah {percent}% dibanding minggu lalu.', 'DUMMY'),
('IN06', 'activity', 'recommendation_walk_after_class', 'Rekomendasi: jalan {minutes} menit setelah kuliah untuk menjaga progresmu.', 'DUMMY');
