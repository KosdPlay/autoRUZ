ALTER TABLE service.ads
  ADD COLUMN IF NOT EXISTS doc tsvector,
  ADD COLUMN IF NOT EXISTS meta jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS active_period tsrange;

UPDATE service.ads
SET doc = to_tsvector('russian', coalesce(header_text,'') || ' ' || coalesce(description,''))
WHERE doc IS NULL;

CREATE INDEX IF NOT EXISTS idx_sellers_user ON service.sellers(user_id);

CREATE INDEX IF NOT EXISTS idx_ads_seller ON service.ads(seller_id);
CREATE INDEX IF NOT EXISTS idx_ads_vehicle ON service.ads(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_ads_pubdate ON service.ads(publication_date);
CREATE INDEX IF NOT EXISTS idx_ads_status ON service.ads(status_id);
CREATE INDEX IF NOT EXISTS idx_ads_price ON service.ads(price);

-- full-text
CREATE INDEX IF NOT EXISTS idx_ads_doc_gin ON service.ads USING GIN(doc);

-- jsonb
CREATE INDEX IF NOT EXISTS idx_ads_meta_gin ON service.ads USING GIN(meta);

-- range (GiST)
CREATE INDEX IF NOT EXISTS idx_ads_active_period_gist ON service.ads USING GIST(active_period);

-- favourites / feedbacks
CREATE INDEX IF NOT EXISTS idx_fav_user ON service.favourites(user_id);
CREATE INDEX IF NOT EXISTS idx_fav_ad ON service.favourites(ad_id);

CREATE INDEX IF NOT EXISTS idx_feedback_seller ON service.feedbacks(seller_id);
CREATE INDEX IF NOT EXISTS idx_feedback_user ON service.feedbacks(user_id);
