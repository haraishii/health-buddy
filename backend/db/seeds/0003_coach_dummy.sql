-- DUMMY data for the columns added in migration 0004. Texts are drafts, not reviewed by a health professional.

UPDATE coach_tips AS t SET trigger_key = v.trigger_key, tip_text_en = v.tip_text_en
FROM (VALUES
    ('TP001', 'sleep_drop_gt_1h', 'Your sleep dropped this week. Try going to bed 30 minutes earlier tonight.'),
    ('TP002', 'sleep_below_min_last_night', 'You slept too little last night. Put screens away 1 hour before bed.'),
    ('TP003', NULL, 'A regular bedtime helps your body recover. Try sleeping at the same time every night.'),
    ('TP004', 'fried_snacks_3_days', 'Fried snacks showed up often this week. Swap one snack for fruit.'),
    ('TP005', 'no_vegetables_today', 'No vegetables yet today. Fill half your plate with vegetables and fruit.'),
    ('TP006', 'calories_over_110_today', 'You have eaten quite a lot today. Pick a light, high-fibre dinner.'),
    ('TP007', 'protein_below_70_today', 'Your protein is still low. Add egg, tempeh, tofu or chicken at dinner.'),
    ('TP008', 'protein_below_target_4_days', 'Protein is often below target. Add a protein side dish to every meal.'),
    ('TP009', NULL, 'A breakfast with protein keeps you full longer. Try adding a boiled egg.'),
    ('TP010', 'water_below_50_today', 'You have not drunk much yet. Fill your bottle and keep it close.'),
    ('TP011', NULL, 'Lots of sweet drinks today. Have some water in between.'),
    ('TP012', 'water_target_reached', 'Water goal reached! Keep up the good habit.'),
    ('TP013', 'steps_below_50_today', 'Your step count is low. A 15-minute walk after a meal helps.'),
    ('TP014', 'no_exercise_3_days', 'Three days without exercise. Try 20 minutes of light activity today.'),
    ('TP015', 'exercise_5_days', 'You have been very active this week! Remember to rest and drink enough.'),
    ('TP016', 'high_stress_today', 'Today feels heavy. Try the 1-minute breathing exercise in Stress Check.'),
    ('TP017', 'stress_lower_on_exercise', 'Your stress is lower on exercise days. A short walk can refresh you.'),
    ('TP018', 'high_stress_3_days', 'This week has been stressful. Talk to someone you trust.')
) AS v (id, trigger_key, tip_text_en)
WHERE t.id = v.id;

UPDATE insight_templates AS t SET template_text_en = v.en
FROM (VALUES
    ('IN01', 'Your stress drops {percent}% on days you exercise.'),
    ('IN02', 'Your average sleep dropped by {hours} hours compared with last week.'),
    ('IN03', 'Your protein was below target on {days} of the last 7 days.'),
    ('IN04', 'Your stress was high on {days} days this week.'),
    ('IN05', 'Your daily steps changed by {percent}% compared with last week.'),
    ('IN06', 'Recommendation: walk {minutes} minutes after class to keep your progress going.')
) AS v (id, en)
WHERE t.id = v.id;

-- Sentences the AI Coach uses to build answers from the user's data. {placeholders} are filled by the API.
INSERT INTO insight_templates (id, topic, trigger_key, template_text, template_text_en, source) VALUES
('IN07', 'sleep', 'coach_sleep_avg', 'Rata-rata tidurmu {hours} jam dalam 7 hari terakhir.', 'You slept {hours} h on average over the last 7 days.', 'DUMMY'),
('IN08', 'protein', 'coach_protein_left', 'Kamu masih butuh {grams} g protein hari ini untuk mencapai {target} g.', 'You still need {grams} g of protein today to reach {target} g.', 'DUMMY'),
('IN09', 'protein', 'coach_protein_done', 'Target protein hari ini sudah tercapai ({grams} g).', 'You reached your protein target today ({grams} g).', 'DUMMY'),
('IN10', 'stress', 'coach_stress_avg', 'Rata-rata stresmu minggu ini {level}/10.', 'Your average stress this week is {level}/10.', 'DUMMY'),
('IN11', 'general', 'coach_score', 'Health Score-mu {score}/100 ({change}% dibanding minggu lalu).', 'Your Health Score is {score}/100 ({change}% vs last week).', 'DUMMY'),
('IN12', 'general', 'coach_best_day', 'Hari terbaik: {day} ({score}).', 'Best day: {day} ({score}).', 'DUMMY'),
('IN13', 'general', 'coach_weakest', '{component} ({score}) paling bisa ditingkatkan.', '{component} ({score}) has the most room to grow.', 'DUMMY'),
('IN14', 'activity', 'coach_steps_avg', 'Rata-rata langkahmu {steps} per hari; targetmu {target}.', 'You averaged {steps} steps a day; your target is {target}.', 'DUMMY'),
('IN15', 'drinking water', 'coach_water_today', 'Hari ini kamu minum {ml} ml dari target {target} ml.', 'You have had {ml} ml of water today out of {target} ml.', 'DUMMY'),
('IN16', 'sleep', 'coach_intro_tired', 'Dari 7 hari terakhirmu, ini mungkin penyebab kamu capek:', 'From your last 7 days, these might be why you feel tired:', 'DUMMY'),
('IN17', 'general', 'coach_intro_generic', 'Ini yang aku lihat dari 7 hari terakhirmu:', 'Here is what I see in your last 7 days:', 'DUMMY'),
('IN18', 'general', 'coach_recommendations', 'Rekomendasiku:', 'My recommendations:', 'DUMMY'),
('IN19', 'general', 'coach_fallback', 'Aku bisa menjawab soal tidur, makan, minum, aktivitas, dan stres. Coba salah satu pertanyaan cepat.', 'I can answer questions about your sleep, food, water, activity and stress. Try one of the quick questions.', 'DUMMY'),
('IN20', 'general', 'coach_no_data', 'Datamu belum cukup. Catat makan, tidur, dan stres beberapa hari, lalu tanya lagi.', 'I do not have enough data yet. Log your meals, sleep and stress for a few days, then ask again.', 'DUMMY'),
('IN21', 'general', 'coach_profile_needed', 'Lengkapi profilmu (tanggal lahir, jenis kelamin, berat) supaya aku bisa membandingkan dengan target harianmu.', 'Complete your profile (birth date, sex, weight) so I can compare with your daily targets.', 'DUMMY'),
('IN22', 'food and nutrition', 'healthy_meals_up', '{percent}% lebih banyak makanan sehat dibanding minggu lalu.', '{percent}% more healthy meals than last week.', 'DUMMY'),
('IN23', 'food and nutrition', 'healthy_meals_down', '{percent}% lebih sedikit makanan sehat dibanding minggu lalu.', '{percent}% fewer healthy meals than last week.', 'DUMMY'),
('IN24', 'food and nutrition', 'healthy_meals_count', '{count} makanan sehat tercatat minggu ini.', '{count} healthy meals logged this week.', 'DUMMY');

UPDATE coach_restricted_topics AS t SET keywords = v.keywords, safe_answer_en = v.en
FROM (VALUES
    ('RT01', '{diagnosis,diagnosa,penyakit,gejala,symptom,disease,diabetes,kanker,cancer}'::text[], 'I cannot assess illnesses. For symptoms like this, please see a doctor or your local health centre.'),
    ('RT02', '{obat,dosis,dose,drug,medicine,paracetamol,antibiotik,antibiotic}'::text[], 'For medicines and doses, please ask a doctor or pharmacist so it is safe for you.'),
    ('RT03', '{diet ekstrem,extreme diet,crash diet,500 kalori,500 calories,turun 10 kg,lose 10 kg}'::text[], 'Losing weight very fast can be risky. A dietitian can help you make a safe plan.'),
    ('RT04', '{tidak makan,puasa air,water fast,fasting,starve}'::text[], 'Not eating for a long time can be dangerous. Please talk to a doctor or dietitian first.'),
    ('RT05', '{muntah,takut gemuk,vomit,binge,anoreksia,anorexia,bulimia}'::text[], 'Thank you for sharing. These feelings matter; please talk to someone you trust and a health professional.'),
    ('RT06', '{bunuh diri,menyakiti diri,suicide,self-harm,self harm,kill myself,tidak ingin hidup,want to die}'::text[], 'I am glad you told me. You are not alone; please contact someone close to you or a support service now.'),
    ('RT07', '{hamil,kehamilan,pregnant,pregnancy}'::text[], 'Needs during pregnancy differ for everyone. A midwife or obstetrician can give the right advice.'),
    ('RT08', '{jantung,ginjal,heart disease,kidney,asma,asthma}'::text[], 'With a special medical condition, exercise and diet advice should come from your own doctor.'),
    ('RT09', '{suplemen,pelangsing,supplement,diet pill,pil diet,slimming}'::text[], 'I cannot recommend supplements or slimming products. Please ask a doctor or pharmacist.'),
    ('RT10', '{alkohol,alcohol,rokok,merokok,smoking,narkoba}'::text[], 'For this topic, a health worker can help in a way that is safe for you.')
) AS v (id, keywords, en)
WHERE t.id = v.id;

-- Provisional Health Score settings (open question 4 in the brief): equal weights until experts decide.
INSERT INTO app_defaults (key, value, notes) VALUES
('health_weight_nutrition', 25, 'Placeholder: Health Score weight for nutrition'),
('health_weight_sleep', 25, 'Placeholder: Health Score weight for sleep'),
('health_weight_stress', 25, 'Placeholder: Health Score weight for stress'),
('health_weight_exercise', 25, 'Placeholder: Health Score weight for exercise'),
('exercise_minutes_target', 30, 'Placeholder: daily exercise minutes that count as a full exercise score');
