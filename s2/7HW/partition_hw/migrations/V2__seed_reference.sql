INSERT INTO service.body_types(code, name) VALUES
  ('sedan','Sedan'),
  ('hatchback','Hatchback'),
  ('suv','SUV'),
  ('coupe','Coupe'),
  ('truck','Truck'),
  ('van','Van')
ON CONFLICT DO NOTHING;

INSERT INTO service.transmissions(code, name) VALUES
  ('manual','Manual'),
  ('automatic','Automatic'),
  ('cvt','CVT')
ON CONFLICT DO NOTHING;

INSERT INTO service.fuel_types(code, name) VALUES
  ('petrol','Petrol'),
  ('diesel','Diesel'),
  ('electric','Electric'),
  ('hybrid','Hybrid')
ON CONFLICT DO NOTHING;

INSERT INTO service.ad_statuses(code, name) VALUES
  ('active','Active'),
  ('sold','Sold'),
  ('blocked','Blocked'),
  ('draft','Draft')
ON CONFLICT DO NOTHING;

INSERT INTO service.moderator_roles(code, name) VALUES
  ('supervisor','Supervisor'),
  ('editor','Editor'),
  ('viewer','Viewer')
ON CONFLICT DO NOTHING;
