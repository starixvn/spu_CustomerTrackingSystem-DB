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
    DROP TEMPORARY TABLE IF EXISTS tempAssRevDeviceCount;
    CREATE TEMPORARY TABLE tempAssRevDeviceCount
    SELECT		assRev.DeviceID, COUNT(1) AS NoOfAccount
	FROM		CTS_Adhoc.cs0519_Association_RemoveBK AS assRev
	GROUP BY	assRev.DeviceID;
        
    DROP TEMPORARY TABLE IF EXISTS tempAssociationDeviceCount;
    CREATE TEMPORARY TABLE tempAssociationDeviceCount
    SELECT		revCou.DeviceID, COUNT(1) AS NoOfAccount
	FROM		tempAssRevDeviceCount AS revCou
	INNER JOIN	CTS_DataCenter.Association AS ass
				ON revCou.DeviceID = ass.DeviceID
	GROUP BY	revCou.DeviceID;    

	DROP TABLE IF EXISTS CTS_Adhoc.cs0519_Device_RemoveBK;
	CREATE TABLE CTS_Adhoc.cs0519_Device_RemoveBK
    SELECT 		dev.*
    FROM 		DCS_DataCenter.Device AS dev
	INNER JOIN 	(	SELECT 		DeviceID
					FROM 		tempAssRevDeviceCount AS revCou
                    INNER JOIN 	tempAssociationDeviceCount AS assCou
								ON revCou.DeviceID = assCou.DeviceID
									AND revCou.NoOfAccount = assCou.NoOfAccount
				) AS tmpDev
				ON dev.DeviceID = tmpDev.DeviceID;
                
END$$
DELIMITER ;