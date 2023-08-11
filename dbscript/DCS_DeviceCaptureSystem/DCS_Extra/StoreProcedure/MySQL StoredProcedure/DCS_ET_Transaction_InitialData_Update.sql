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
			CALL DCS_ET_Transaction_InitialData_Update('[{"TransID":193915604,"IPInfoCode":8609138301568091049},{"TransID":193915605,"IPInfoCode":8467444344281531902}]');
            SELECT * FROM DCS_Extra.Transaction07;
    
    */
    DECLARE lv_LastCreatedDate DATETIME;
    DECLARE lv_LastTransID DATETIME;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Transactions;
	CREATE TEMPORARY TABLE Temp_Transactions(
			TransID				BIGINT UNSIGNED PRIMARY KEY
		,	IPInfoCode			BIGINT
		,	IPInfoID			INT
        
		,	KEY `IX_Temp_Transactions_IPInfoCode` (`IPInfoCode`)
    );  

    INSERT INTO Temp_Transactions(TransID, IPInfoCode)
	SELECT	TransID
		,	IPInfoCode
	FROM	JSON_TABLE(
			ip_TransJs,
			 "$[*]" COLUMNS(
							TransID				BIGINT UNSIGNED PATH "$.TransID"  
						,	IPInfoCode			BIGINT			PATH "$.IPInfoCode" 
				)
		   ) AS  rt;
     
	#========GET IPInfo===================
    UPDATE Temp_Transactions AS tmp
		INNER JOIN DCS_Extra.IPInfo AS ipi ON ipi.IPInfoCode = tmp.IPInfoCode
	SET tmp.IPInfoID = ipi.IPInfoID;
    
    select * from Temp_Transactions AS tmp
 		INNER JOIN DCS_Extra.Transaction07 AS trans ON trans.TransID = tmp.TransID;
    #=============UPDATE Transaction07=================================
    UPDATE Temp_Transactions AS tmp
		INNER JOIN DCS_Extra.Transaction07 AS trans ON trans.TransID = tmp.TransID
	SET trans.IPInfoID = tmp.IPInfoID;
END$$

DELIMITER ;
