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
			CALL DCS_ET_Transaction_InitialData_Update();
    
    */
    DECLARE lv_LastCreatedDate DATETIME;
    DECLARE lv_LastTransID DATETIME;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Transactions;
	CREATE TEMPORARY TABLE Temp_Transactions(
		TransID				BIGINT UNSIGNED PRIMARY KEY
		,	Region				VARCHAR(128)
		,	City				VARCHAR(128)
		,	ServiceProvider		VARCHAR(50) 
    );  

    INSERT INTO Temp_Transactions(TransID, Country, Region, City, ServiceProvider)
	SELECT	TransID, Country, Region, City, ServiceProvider
	FROM	JSON_TABLE(
			ip_TransJs,
			 "$[*]" COLUMNS(
								TransID				BIGINT UNSIGNED PATH "$.TransID" 
							,	Country				VARCHAR(50) 	PATH "$.Country"   
                            ,	CountryCode			VARCHAR(50) 	PATH "$.CountryCode"   
							,	Region				VARCHAR(50)  	PATH "$.Region"
							,	City				VARCHAR(50) 	PATH "$.City"
							,	ServiceProvider		VARCHAR(50) 	PATH "$.ServiceProvider"
				)
		   ) AS  rt
     
	#========Insert Country===================
	#========Insert Region===================
	#========Insert City===================
    #========Insert ServiceProvider===================
    #=============UPDATE Transaction07=================================
END$$

DELIMITER ;
