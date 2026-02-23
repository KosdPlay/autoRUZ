ALTER TABLE service.ads
  ADD COLUMN IF NOT EXISTS doc tsvector,
  ADD COLUMN IF NOT EXISTS meta jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS active_period tsrange;

UPDATE service.ads
SET doc = to_tsvector('russian', coalesce(header_text,'') || ' ' || coalesce(description,''))
WHERE doc IS NULL;

CREATE INDEX IF NOT EXISTS idx_sellers_user_id ON service.sellers(user_id);
CREATE INDEX IF NOT EXISTS idx_ads_seller_id ON service.ads(seller_id);
CREATE INDEX IF NOT EXISTS idx_ads_vehicle_id ON service.ads(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_ads_pub_date ON service.ads(publication_date);
CREATE INDEX IF NOT EXISTS idx_ads_status_id ON service.ads(status_id);
CREATE INDEX IF NOT EXISTS idx_ads_price_val ON service.ads(price);


CREATE INDEX IF NOT EXISTS idx_ads_doc_gin ON service.ads USING GIN(doc);

CREATE INDEX IF NOT EXISTS idx_ads_meta_gin ON service.ads USING GIN(meta);

CREATE INDEX IF NOT EXISTS idx_ads_active_period_gist ON service.ads USING GiST(active_period);


CREATE INDEX IF NOT EXISTS idx_favourites_user ON service.favourites(user_id);
CREATE INDEX IF NOT EXISTS idx_favourites_ad ON service.favourites(ad_id);


CREATE INDEX IF NOT EXISTS idx_feedbacks_seller ON service.feedbacks(seller_id);
CREATE INDEX IF NOT EXISTS idx_feedbacks_user ON service.feedbacks(user_id);


CREATE INDEX IF NOT EXISTS idx_vehicles_vin ON service.vehicles(vin);
CREATE INDEX IF NOT EXISTS idx_vehicles_power_hp ON service.vehicles(power_hp);


CREATE INDEX IF NOT EXISTS idx_contracts_ad ON service.contracts(ad_id);
CREATE INDEX IF NOT EXISTS idx_contracts_seller ON service.contracts(seller_id);
CREATE INDEX IF NOT EXISTS idx_contracts_buyer ON service.contracts(buyer_user_id);


CREATE INDEX IF NOT EXISTS idx_moderators_user ON service.moderators(user_id);
CREATE INDEX IF NOT EXISTS idx_moderators_role ON service.moderators(role_id);