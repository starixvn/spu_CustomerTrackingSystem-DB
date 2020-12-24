/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustEvidence_GetExistedEvidencesToSync`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_GetExistedEvidencesToSync`(IN ip_CustIDs TEXT)
    SQL SECURITY INVOKER
BEGIN
 /*
		Created:	20201224@Irena.Vo
		Task:		Get Existed Evidence Category to Re-scan Problem Account
		DB:			CTS_DataCenter
		Original:
		Revisions:
            - 20201224@Irena.Vo: Created [RedmineID: #145951]
           
		Param's Explanation (filtered by):		 	
	*/   
	DECLARE	lv_SPName 			VARCHAR(100) 	DEFAULT 'CTS_DC_CustEvidence_GetExistedEvidencesToSync';   
    DECLARE	lv_CurrentDateTime 	DATETIME 		DEFAULT CURRENT_TIME();
	
    DECLARE op_ErrorMessage 	VARCHAR(200) DEFAULT '0';
    DECLARE op_ErrorNo 			INT DEFAULT 0;
    DECLARE op_CodName 			VARCHAR(200) DEFAULT '0';

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN   
		GET DIAGNOSTICS CONDITION 1 
         	op_ErrorMessage 	= 	MESSAGE_TEXT	
		,	op_ErrorNo 			= 	MYSQL_ERRNO
		,	op_CodName 			= 	RETURNED_SQLSTATE;
    
        INSERT INTO CTS_Log.ErrorLog(EventName, InsertedTime, Message, Err_No, Description)
        VALUES(lv_SPName, lv_CurrentDateTime, op_ErrorMessage, op_ErrorNo, 	JSON_OBJECT('err_no',op_ErrorNo,'cod_name',op_CodName,'parameter',ip_CustIDs));
    END;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Customers;    
	CREATE TEMPORARY TABLE Temp_Customers 
    (	  
			 CustID              BIGINT UNSIGNED PRIMARY KEY 
         ,   CTSCustID           BIGINT UNSIGNED
         ,	 SubscriberID        INT
         ,	 INDEX 				 IX_Temp_Customers_CTSCustID (CTSCustID)
     );
     
	-- Insert CustIDs
	SET @sql = 	CONCAT("INSERT INTO Temp_Customers (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;    
    
    -- Update CTSCustID, SubscriberID
    UPDATE      Temp_Customers AS temp
    INNER JOIN  CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = temp.CustID AND cust.CustSubID = 0
    SET         temp.CTSCustID = cust.CTSCustID,	temp.SubscriberID = cust.SubscriberID;
    
     -- Return CTSCustID, CustID, SubscriberID, EvidenceID, 0 (ActionType)
    SELECT DISTINCT temp.CustId
				,	temp.CTSCustId
                ,	temp.SubscriberId
                ,	e.EvidenceId
                ,	0 AS ActionType
    FROM Temp_Customers AS temp
    INNER JOIN CTS_DataCenter.CustEvidence AS ce ON ce.CTSCustID = temp.CTSCustID AND ce.Level = 0
    INNER JOIN CTS_DataCenter.EvidenceToCategory AS e ON e.EvidenceID = ce.EvidenceID;
END$$

DELIMITER ;