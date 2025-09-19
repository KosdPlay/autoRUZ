ALTER TABLE service.contracts
DROP COLUMN headerText;

ALTER TABLE service.advertisiments 
RENAME TO advertisements;

ALTER TABLE service.transport 
RENAME COLUMN powerOf TO horsepower;