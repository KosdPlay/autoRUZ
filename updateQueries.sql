UPDATE service.users
SET phoneNumber = '+70001833811'
WHERE fullName = 'Иван Иванов';

UPDATE service.advertisements as a
SET costOf = costOf + 100000
FROM (
	SELECT DISTINCT transportId
	FROM service.carLibrary
	WHERE usedInTaxi = 'no'
) AS cl
WHERE a.transportId = cl.transportId;

UPDATE service.transport
SET color = 'Белый';