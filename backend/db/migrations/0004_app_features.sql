-- Columns and tables the app screens need so that no number or text is hardcoded in Flutter.

-- Package 7: machine-readable triggers so the API can pick tips, English text for the English UI (brief rule 7),
-- and keywords so the coach can recognise restricted topics in free-text questions.
ALTER TABLE coach_tips
    ADD COLUMN trigger_key text,
    ADD COLUMN tip_text_en text CHECK (char_length(tip_text_en) <= 140);
ALTER TABLE insight_templates ADD COLUMN template_text_en text;
ALTER TABLE coach_restricted_topics
    ADD COLUMN keywords text[] NOT NULL DEFAULT '{}',
    ADD COLUMN safe_answer_en text;

-- Profile > Settings switches and language.
ALTER TABLE users
    ADD COLUMN reminder_daily  boolean NOT NULL DEFAULT true,
    ADD COLUMN reminder_bedtime boolean NOT NULL DEFAULT true,
    ADD COLUMN bedtime_time    time NOT NULL DEFAULT '22:30',
    ADD COLUMN weekly_summary  boolean NOT NULL DEFAULT false,
    ADD COLUMN language        text NOT NULL DEFAULT 'en' CHECK (language IN ('en', 'id'));

-- AI Coach conversation, so History shows real past questions.
CREATE TABLE coach_chat_messages (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id    bigint NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role       text NOT NULL CHECK (role IN ('user', 'coach')),
    text       text NOT NULL CHECK (char_length(text) <= 2000),
    -- Structured coach reply (points and recommendations) so the app can render it the same way later.
    payload    jsonb,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX coach_chat_messages_user_idx ON coach_chat_messages (user_id, created_at DESC);
ALTER TABLE coach_chat_messages ENABLE ROW LEVEL SECURITY;
