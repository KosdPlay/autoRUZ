ALTER TABLE service.users
  ADD COLUMN IF NOT EXISTS profile_json JSONB;

ALTER TABLE service.vehicles
  ADD COLUMN IF NOT EXISTS features TEXT[];

ALTER TABLE service.vehicles
  ADD COLUMN IF NOT EXISTS mileage_range int4range;

ALTER TABLE service.ads
  ADD COLUMN IF NOT EXISTS geo_point point;

ALTER TABLE service.ads
  ADD COLUMN IF NOT EXISTS search_tsv tsvector;

CREATE INDEX IF NOT EXISTS idx_ads_search_tsv
  ON service.ads USING GIN (search_tsv);

-- частичный индекс под NULL-анализ (есть смысл если 5–20% NULL)
CREATE INDEX IF NOT EXISTS idx_users_phone_notnull
  ON service.users(phone_number)
  WHERE phone_number IS NOT NULL;