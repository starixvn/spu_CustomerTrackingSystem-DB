/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_ET_Transaction_InitialData_Update`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_ET_Transaction_InitialData_Update`(
	IN ip_TransJs JSON 
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20230809@Casey.Huynh
		Task :		Update IP Detail for Transaction 
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20230809@Casey.Huynh: Created [Redmine ID: 192402]
			
		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_ET_Transaction_InitialData_Update('[{"TransID":1,"CountryCode":"THA","Region":"Islamabad","City":"Manduria","ISP":"Rise Manila"},{"TransID":2,"CountryCode":"VN","Region":"Tarlac","City":"Tokyo","ISP":"Telecom Italia S.p.A."}]');
            SELECT * FROM DCS_Extra.Transaction07;
    
    */
    DECLARE lv_LastCreatedDate DATETIME;
    DECLARE lv_LastTransID DATETIME;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Transactions;
	CREATE TEMPORARY TABLE Temp_Transactions(
			TransID				BIGINT UNSIGNED PRIMARY KEY
		,	CountryCode			VARCHAR(20)
		,	RegionName			VARCHAR(128)
		,	CityName			VARCHAR(128)
		,	ISPName				VARCHAR(256) 
		,	CountryID			INT
		,	RegionID			INT
		,	CityID				INT
		,	ISPID				INT
        
		,	KEY `IX_Temp_Transactions_CountryCode` (`CountryCode`)
		,	KEY `IX_Temp_Transactions_RegionName` (`RegionName`)
		,	KEY `IX_Temp_Transactions_CityName` (`CityName`)
		,	KEY `IX_Temp_Transactions_ISPName` (`ISPName`)
    );  

    INSERT INTO Temp_Transactions(TransID, CountryCode, RegionName, CityName, ISPName)
	SELECT	TransID
		,	CountryCode
        ,	RegionName
        ,	CityName
        ,	ISPName
	FROM	JSON_TABLE(
			ip_TransJs,
			 "$[*]" COLUMNS(
								TransID				BIGINT UNSIGNED PATH "$.TransID"  
                            ,	CountryCode			VARCHAR(20) 	PATH "$.CountryCode"   
							,	RegionName			VARCHAR(128)  	PATH "$.RegionName"
							,	CityName			VARCHAR(128) 	PATH "$.CityName"
							,	ISPName				VARCHAR(256) 	PATH "$.ISPName"
				)
		   ) AS  rt;
     
	#========GET CountryID===================
    UPDATE Temp_Transactions AS tmp
		INNER JOIN DCS_Extra.Country AS c ON c.CountryCode = tmp.CountryCode
	SET tmp.CountryID = c.CountryID;
    
	#========GET RegionID===================
    UPDATE Temp_Transactions AS tmp
		INNER JOIN DCS_Extra.Region AS c ON c.RegionName = tmp.RegionName
	SET tmp.RegionID = c.RegionID;
    
	#========GET CityID===================
    UPDATE Temp_Transactions AS tmp
		INNER JOIN DCS_Extra.City AS c ON c.CityName = tmp.CityName
	SET tmp.CityID = c.CityID;
    
	#========GET ISPID===================
    UPDATE Temp_Transactions AS tmp
		INNER JOIN DCS_Extra.ISP AS c ON c.ISPName = tmp.ISPName
	SET tmp.ISPID = c.ISPID;
    
    #=============UPDATE Transaction07=================================
    UPDATE Temp_Transactions AS tmp
		INNER JOIN DCS_Extra.Transaction07 AS trans ON trans.TransID = tmp.TransID
	SET 	trans.CountryID = tmp.CountryID
		,	trans.RegionID = tmp.RegionID
		,	trans.CityID = tmp.CityID
		,	trans.ISPID = tmp.ISPID;
END$$

DELIMITER ;
