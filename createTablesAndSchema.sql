CREATE SCHEMA service;

CREATE TABLE service.users (
	userId SERIAL PRIMARY KEY,
	fullName VARCHAR(50) NOT NULL,
	email VARCHAR(254) UNIQUE NOT NULL,
	phoneNumber VARCHAR(20) CHECK (phoneNumber ~ '^\+[0-9]{10,15}'),
	registrationDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE service.sellers (
	sellerId SERIAL PRIMARY KEY,
	userId INTEGER NOT NULL REFERENCES service.users(userId),
	typeOf VARCHAR(50) NOT NULL CHECK (typeOf IN ('individual', 'company')),
	rating NUMERIC (3,2) DEFAULT 0 CHECK (rating BETWEEN 0 AND 5),
	countOfAds INTEGER DEFAULT 0 CHECK (countOfAds >= 0)
);

CREATE TABLE service.transport (
	transportId SERIAL PRIMARY KEY,
	brand VARCHAR(60) NOT NULL,
	model VARCHAR(60) NOT NULL,
	yearOfManufacture INTEGER CHECK (yearOfManufacture >= 1886 AND yearOfManufacture <= EXTRACT(YEAR FROM CURRENT_DATE)),
	color VARCHAR(30),
	bodyType VARCHAR(30) CHECK (bodyType IN ('sedan', 'hatchback', 'SUV', 'coupe', 'truck', 'van')),
	transmission VARCHAR(20) CHECK (transmission IN ('manual', 'automatic', 'CVT')),
	fuelType VARCHAR(20) CHECK (fuelType IN ('petrol', 'diesel', 'electric', 'hybrid')),
	powerOf INTEGER CHECK (powerOf > 0),
	stateOf VARCHAR(20) CHECK (stateOf IN ('new', 'used', 'damaged')),
	VIN VARCHAR(17) UNIQUE NOT NULL
);

CREATE TABLE service.advertisiments (
	adId SERIAL PRIMARY KEY,
	sellerId INTEGER NOT NULL REFERENCES service.sellers(sellerId),
	transportId INTEGER NOT NULL REFERENCES service.transport(transportId),
	headerText VARCHAR(70) NOT NULL,
	description TEXT,
	costOf INTEGER CHECK (costOf >= 0),
	publicationDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	status VARCHAR(50) CHECK (status IN ('saled', 'in processing', 'active'))
);

CREATE TABLE service.photos (
	photoId SERIAL PRIMARY KEY,
	adId INTEGER NOT NULL REFERENCES service.advertisiments(adId),
	url TEXT NOT NULL
);

CREATE TABLE service.carLibrary(
	libraryId SERIAL PRIMARY KEY,
	transportId INTEGER NOT NULL REFERENCES service.transport(transportId),
	ownersCount INTEGER DEFAULT 0 CHECK (ownersCount >= 0),
	ancients VARCHAR(10) CHECK (ancients in ('yes', 'no')),
	milleage INTEGER DEFAULT 0 CHECK (milleage >= 0),
	insurancesInformation TEXT,
	usedInTaxi VARCHAR(10) CHECK (usedInTaxi in ('yes', 'no'))
);

CREATE TABLE service.moderator (
	moderatorId SERIAL PRIMARY KEY,
	userId INTEGER NOT NULL REFERENCES service.users(userId),
	appointmentDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	roleOf VARCHAR(20) CHECK (roleOf IN ('supervisor', 'editor', 'viewer'))
);

CREATE TABLE service.favourites (
	likeId SERIAL PRIMARY KEY,
	userId INTEGER NOT NULL REFERENCES service.users(userId),
	adId INTEGER NOT NULL REFERENCES service.advertisiments(adId)
);

CREATE TABLE service.feedbacks (
	responseId SERIAL PRIMARY KEY,
	userId INTEGER NOT NULL REFERENCES service.users(userId),
	sellerId INTEGER NOT NULL REFERENCES service.sellers(sellerId),
	textOf TEXT,
	rating NUMERIC (3,2) DEFAULT 0 CHECK (rating BETWEEN 0 AND 5),
	publicationDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE service.contracts (
	contractId SERIAL PRIMARY KEY,
	sellerId INTEGER NOT NULL REFERENCES service.sellers(sellerId),
	transportId INTEGER NOT NULL REFERENCES service.transport(transportId),
	amount INTEGER NOT NULL CHECK (amount >= 0),
	status VARCHAR(20) NOT NULL CHECK (status IN ('active','closed','pending'))
);