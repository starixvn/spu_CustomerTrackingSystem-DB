DELIMITER $$
USE CTS_Adhoc $$
DROP PROCEDURE IF EXISTS CTS_Adhoc.cs0519_DCSAccountNotInCTS_GetDevice$$

CREATE PROCEDURE CTS_Adhoc.cs0519_DCSAccountNotInCTS_GetDevice()
BEGIN
	/*
		Created:	20200519@Casey
		Task:		Remove Account NOT In CTS
		DB:			CTS_Adhoc
		Original:

		Revisions:
		Param's Explanation (filtered by):
	*/
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    DROP TEMPORARY TABLE IF EXISTS tempDeviceID_Remove;
    CREATE TEMPORARY TABLE tempDeviceID_Remove
    SELECT		dev.DeviceID
	FROM 		DCS_DataCenter.Device AS dev
	INNER JOIN 	CTS_Adhoc.cs0519_Association_RemoveBK AS devRev
				ON dev.DeviceID = devRev.DeviceID
	GROUP BY	dev.DeviceID
    HAVING		COUNT(AccountID) = 1;	

	DROP TABLE IF EXISTS CTS_Adhoc.cs0519_Device_RemoveBK;
	CREATE TABLE CTS_Adhoc.cs0519_Device_RemoveBK
    SELECT 		dev.*
    FROM 		DCS_DataCenter.Device AS dev
	INNER JOIN 	tempDeviceID_Remove AS tmpDev
				ON dev.DeviceID = tmpDev.DeviceID;
                
END$$
DELIMITER ;