/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20251117@Jonathan.Doan [Redmine ID: #233405]
	Task: New tables for storing MB transaction summary data
	DB: DCS_DataCenter
*/
USE DCS_DataCenter;

CREATE TABLE RawTransaction_bk LIKE RawTransaction;

INSERT INTO RawTransaction_bk
SELECT *
FROM RawTransaction
WHERE CreatedDate < DATE(NOW());

SELECT COUNT(1) FROM RawTransaction_bk;

DELETE FROM RawTransaction
WHERE CreatedDate < DATE(NOW());

