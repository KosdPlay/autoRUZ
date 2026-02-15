CREATE SCHEMA IF NOT EXISTS service;


CREATE TABLE service.body_types (
    id SERIAL PRIMARY KEY,
    code VARCHAR(30) UNIQUE NOT NULL,  -- 'sedan', 'hatchback' ...
    name VARCHAR(60) NOT NULL
);

CREATE TABLE service.transmissions (
    id SERIAL PRIMARY KEY,
    code VARCHAR(30) UNIQUE NOT NULL,  -- 'manual', 'automatic', 'CVT'
    name VARCHAR(60) NOT NULL
);

CREATE TABLE service.fuel_types (
    id SERIAL PRIMARY KEY,
    code VARCHAR(30) UNIQUE NOT NULL,  -- 'petrol','diesel','electric','hybrid'
    name VARCHAR(60) NOT NULL
);

CREATE TABLE service.ad_statuses (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,  -- 'active','in_processing','sold'
    name VARCHAR(100) NOT NULL
);

CREATE TABLE service.moderator_roles (
    id SERIAL PRIMARY KEY,
    code VARCHAR(30) UNIQUE NOT NULL,  -- 'supervisor','editor','viewer'
    name VARCHAR(60) NOT NULL
);

CREATE TABLE service.users (
    user_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(254) UNIQUE NOT NULL,
    phone_number VARCHAR(20) CHECK (phone_number ~ '^\+[0-9]{10,15}$'),
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE service.sellers (
    seller_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES service.users(user_id) ON DELETE CASCADE,
    seller_type VARCHAR(50) NOT NULL CHECK (seller_type IN ('individual','company')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE service.vehicles (
    vehicle_id SERIAL PRIMARY KEY,
    brand VARCHAR(60) NOT NULL,
    model VARCHAR(60) NOT NULL,
    year_of_manufacture INTEGER CHECK (year_of_manufacture >= 1886 AND year_of_manufacture <= EXTRACT(YEAR FROM CURRENT_DATE)),
    color VARCHAR(30),
    body_type_id INTEGER REFERENCES service.body_types(id),
    transmission_id INTEGER REFERENCES service.transmissions(id),
    fuel_type_id INTEGER REFERENCES service.fuel_types(id),
    power_hp INTEGER CHECK (power_hp > 0),
    state_code VARCHAR(20) CHECK (state_code IN ('new','used','damaged')),
    vin VARCHAR(17) UNIQUE NOT NULL
);

CREATE TABLE service.ads (
    ad_id SERIAL PRIMARY KEY,
    seller_id INTEGER NOT NULL REFERENCES service.sellers(seller_id) ON DELETE CASCADE,
    vehicle_id INTEGER NOT NULL REFERENCES service.vehicles(vehicle_id) ON DELETE CASCADE,
    header_text VARCHAR(200) NOT NULL,
    description TEXT,
    price INTEGER CHECK (price >= 0),
    publication_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status_id INTEGER NOT NULL REFERENCES service.ad_statuses(id)
);

CREATE TABLE service.ad_photos (
    photo_id SERIAL PRIMARY KEY,
    ad_id INTEGER NOT NULL REFERENCES service.ads(ad_id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE
);

CREATE TABLE service.favourites (
    user_id INTEGER NOT NULL REFERENCES service.users(user_id) ON DELETE CASCADE,
    ad_id INTEGER NOT NULL REFERENCES service.ads(ad_id) ON DELETE CASCADE,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, ad_id)
);

CREATE TABLE service.feedbacks (
    feedback_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES service.users(user_id) ON DELETE SET NULL,
    seller_id INTEGER NOT NULL REFERENCES service.sellers(seller_id) ON DELETE CASCADE,
    ad_id INTEGER REFERENCES service.ads(ad_id) ON DELETE SET NULL,
    text TEXT,
    rating NUMERIC(3,2) CHECK (rating BETWEEN 0 AND 5),
    publication_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, seller_id, ad_id) 
);

CREATE TABLE service.ownerships (
    ownership_id SERIAL PRIMARY KEY,
    vehicle_id INTEGER NOT NULL REFERENCES service.vehicles(vehicle_id) ON DELETE CASCADE,
    owner_user_id INTEGER REFERENCES service.users(user_id) ON DELETE SET NULL,
    purchase_date DATE,
    sale_date DATE,
    note TEXT
);

CREATE TABLE service.mileage_log (
    mileage_id SERIAL PRIMARY KEY,
    vehicle_id INTEGER NOT NULL REFERENCES service.vehicles(vehicle_id) ON DELETE CASCADE,
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    mileage_km INTEGER CHECK (mileage_km >= 0)
);

CREATE TABLE service.insurances (
    insurance_id SERIAL PRIMARY KEY,
    vehicle_id INTEGER NOT NULL REFERENCES service.vehicles(vehicle_id) ON DELETE CASCADE,
    insurer VARCHAR(200),
    policy_number VARCHAR(100),
    valid_from DATE,
    valid_to DATE,
    info TEXT
);

CREATE TABLE service.vehicle_flags (
    vehicle_id INTEGER PRIMARY KEY REFERENCES service.vehicles(vehicle_id) ON DELETE CASCADE,
    is_classic BOOLEAN DEFAULT FALSE,
    used_in_taxi BOOLEAN DEFAULT FALSE
);

CREATE TABLE service.moderators (
    moderator_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES service.users(user_id) ON DELETE CASCADE,
    appointment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    role_id INTEGER REFERENCES service.moderator_roles(id)
);

CREATE TABLE service.contracts (
    contract_id SERIAL PRIMARY KEY,
    ad_id INTEGER REFERENCES service.ads(ad_id),
    seller_id INTEGER NOT NULL REFERENCES service.sellers(seller_id),
    buyer_user_id INTEGER NOT NULL REFERENCES service.users(user_id),
    amount INTEGER NOT NULL CHECK (amount >= 0),
    currency CHAR(3) DEFAULT 'USD',
    contract_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL CHECK (status IN ('active','closed','pending'))
);

CREATE VIEW service.seller_ratings AS
SELECT s.seller_id,
       AVG(f.rating) AS avg_rating,
       COUNT(f.feedback_id) AS reviews_count
FROM service.sellers s
LEFT JOIN service.feedbacks f ON f.seller_id = s.seller_id
GROUP BY s.seller_id;