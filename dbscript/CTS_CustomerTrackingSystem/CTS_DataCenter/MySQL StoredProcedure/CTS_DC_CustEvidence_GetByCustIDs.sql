/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustEvidence_GetByCustIDs`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_GetByCustIDs`(
        IN ip_CustIDs TEXT
)
    SQL SECURITY INVOKER
BEGIN
 /*
		Created:	20201224@Irena.Vo
		Task:		Get Existed Evidence Category to Re-scan Problem Account
		DB:			CTS_DataCenter
		Original:
		Revisions:
             - 20201224-20210107@Irena.Vo: Created. Insert Error Log [RedmineID: #145951]
             - 20210622@Aries.Nguyen: Update coding convention and improve locking[Redmine ID: #157203]
             - 20220421@Irena.Vo: Rename select CustId -> CustID [Redmine ID: #170468]
             - 20220426@Casey.Huynh: Return CreatedBy [Redmine ID: #171512]
           
		Param's Explanation (filtered by):
        
        Example:
			CALL CTS_DC_CustEvidence_GetByCustIDs('1,23');
	*/   
    DECLARE lv_ErrorMessage		VARCHAR(200) DEFAULT '0';
    DECLARE	lv_No				INT			 DEFAULT 0;
    DECLARE lv_ErrorNo 			INT          DEFAULT 0;
    DECLARE lv_CodName 			VARCHAR(200) DEFAULT '0';

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN   
		GET DIAGNOSTICS lv_No 	= 	NUMBER;
		GET DIAGNOSTICS CONDITION lv_No 
            lv_ErrorMessage 	= 	MESSAGE_TEXT	
		,	lv_ErrorNo 			= 	MYSQL_ERRNO
		,	lv_CodName 			= 	RETURNED_SQLSTATE;
    
        INSERT INTO CTS_Log.CTSErrorLog(EventID, Message, Description)
        VALUES(4, lv_ErrorMessage, JSON_OBJECT('err_no',lv_ErrorNo,'cod_name',lv_CodName,'parameter',ip_CustIDs));
    END;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Customer;    
	CREATE TEMPORARY TABLE Temp_Customer (	  
			 CustID              BIGINT UNSIGNED PRIMARY KEY 
         ,   CTSCustID           BIGINT UNSIGNED
         ,	 SubscriberID        INT
         ,	 INDEX 				 IX_Temp_Customer_CTSCustID (CTSCustID)
     );

    DROP TEMPORARY TABLE IF EXISTS Temp_CustID;    
	CREATE TEMPORARY TABLE Temp_CustID (	  
			 CustID              BIGINT UNSIGNED PRIMARY KEY 
     );
     
	-- Insert CustIDs
	SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_CustID (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;    
    
    -- Update CTSCustID, SubscriberID
    INSERT INTO Temp_Customer(CustID, CTSCustID, SubscriberID)
    SELECT  temp.CustID
        ,   cust.CTSCustID
        ,   cust.SubscriberID
    FROM Temp_CustID AS temp
        INNER JOIN  CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = temp.CustID AND cust.CustSubID = 0;

     -- Return CustID, CTSCustID, SubscriberID, EvidenceID, 0 (ActionType)
    SELECT  DISTINCT 
            temp.CustID
	    ,	temp.CTSCustID
        ,	temp.SubscriberID
        ,	e.EvidenceID
        ,	ce.CreatedBy
        ,	0 AS ActionType
    FROM Temp_Customer AS temp
        INNER JOIN CTS_DataCenter.CustEvidence AS ce ON ce.CTSCustID = temp.CTSCustID AND ce.Level = 0
        INNER JOIN CTS_DataCenter.EvidenceToCategory AS e ON e.EvidenceID = ce.EvidenceID;
END$$
DELIMITER ;