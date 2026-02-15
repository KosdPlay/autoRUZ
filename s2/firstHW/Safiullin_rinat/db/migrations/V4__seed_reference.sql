INSERT INTO service.body_types(code, name) VALUES
('sedan','Sedan'),('hatchback','Hatchback'),('suv','SUV'),('wagon','Wagon')
ON CONFLICT (code) DO NOTHING;

INSERT INTO service.transmissions(code, name) VALUES
('manual','Manual'),('automatic','Automatic'),('cvt','CVT')
ON CONFLICT (code) DO NOTHING;

INSERT INTO service.fuel_types(code, name) VALUES
('petrol','Petrol'),('diesel','Diesel'),('electric','Electric'),('hybrid','Hybrid')
ON CONFLICT (code) DO NOTHING;

INSERT INTO service.ad_statuses(code, name) VALUES
('active','Active'),('in_processing','In processing'),('sold','Sold')
ON CONFLICT (code) DO NOTHING;

INSERT INTO service.moderator_roles(code, name) VALUES
('supervisor','Supervisor'),('editor','Editor'),('viewer','Viewer')
ON CONFLICT (code) DO NOTHING;