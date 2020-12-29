/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_InsertNewCustomerCategory`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_InsertNewCustomerCategory`(IN ip_CustIDs TEXT, OUT op_ErrorMessage VARCHAR(200))
    SQL SECURITY INVOKER
BEGIN
/**
		Created:	20200703@Long.Luu
		Task:		Insert New-Member category for new accounts [Redmine ID: 136903]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- [20200703@Long.Luu][136903]: created
            - [20200908@Irena.Vo][141020]: Enhance ignore VVIP & Pin category 
            - [20200923@Irena.Vo][141755]: Enhance SP
            - [20200930@Irena.Vo][141755]: Covered get Existed Category before. Updated temp table. Updated primary key.
            - [20201001@Irena.Vo][141755]: Fix issue duplicate category & enhance logic
			- [20201116@Irena.Vo][145028]: Enhance logic remove existed customers
            - 20201202@Lex.Khuat: Disable detail categories & clean up wrong syntax [Redmine ID: #145954]
            - 20201224-20201229@Irena.Vo: Insert log History. Insert Error Log. Return All List CustID [RedmineID: #145951]
            
		Param's Explanation (filtered by):
             call CTS_DC_InsertNewCustomerCategory('1,2,3');
	*/
    DECLARE lv_SPName 			VARCHAR(200) DEFAULT 'CTS_DC_InsertNewCustomerCategory';
    DECLARE lv_CreatedBy 		INT DEFAULT 10278938;
    DECLARE lv_CurrentDateTime 	DATETIME DEFAULT CURRENT_TIME();
    
	DECLARE op_ErrorNo 			INT DEFAULT 0;
    DECLARE op_CodName 			VARCHAR(200) DEFAULT '0';

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN   
		GET DIAGNOSTICS @op_No = NUMBER;
		GET DIAGNOSTICS CONDITION @op_No 
         	op_ErrorMessage 	= 	MESSAGE_TEXT	
		,	op_ErrorNo 			= 	MYSQL_ERRNO
		,	op_CodName 			= 	RETURNED_SQLSTATE;
    
        INSERT INTO CTS_Log.ErrorLog(EventName, InsertedTime, Message, Err_No, Description)
        VALUES(lv_SPName, lv_CurrentDateTime, op_ErrorMessage, op_ErrorNo, 	JSON_OBJECT('err_no',op_ErrorNo,'cod_name',op_CodName,'parameter',ip_CustIDs));
    END;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_NewCustomers;
	CREATE TEMPORARY TABLE Temp_NewCustomers
	(		
            CustID			    BIGINT UNSIGNED PRIMARY KEY
		, 	CTSCustID			BIGINT UNSIGNED DEFAULT 0
        , 	SubscriberID		INT DEFAULT 0 
        ,	ActionType			SMALLINT DEFAULT 0 -- 0: Insert, 3: Ignore
	);

	 DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
	 CREATE TEMPORARY TABLE Temp_ExistedClassification 
     (	  
            CustID			BIGINT UNSIGNED
     );
     
	SET @sql = CONCAT("INSERT INTO Temp_NewCustomers(CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;

   /*	IGNORE PIN CATEGORY	*/
    UPDATE Temp_NewCustomers AS temp
	INNER JOIN CTS_DataCenter.PinCustomerCategory AS pin on pin.CustID = temp.CustID
    SET         temp.ActionType = 3; 
    
	/*	IGNORE CUSTOMER HAS CATEGORY BEFORE	*/
	UPDATE 		Temp_NewCustomers AS temp
	INNER JOIN 	CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID
    SET 		temp.ActionType = 3;	
    
    /*	UPDATE CUST INFO	*/
    UPDATE 	    Temp_NewCustomers AS temp 
	INNER JOIN	CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID AND cust.CustSubID = 0
	SET		    temp.CTSCustID = cust.CTSCustID, temp.SubscriberID = cust.SubscriberID
    WHERE       temp.ActionType = 0;  
     
	/*	INSERT NEW MEMBER CATEGORY	*/
    INSERT INTO CTS_DataCenter.CTSCustomerClassification(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, 
			CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT 	temp.CustID
		, 	temp.CTSCustID
		, 	temp.SubscriberID
		, 	201
		, 	200
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	DATE(lv_CurrentDateTime)
	FROM  Temp_NewCustomers AS temp
    WHERE temp.ActionType = 0;  
            
	/*	INSERT LOG	*/
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
    (CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
    SELECT 	temp.CustID
		, 	temp.CTSCustID
		, 	201 
		, 	200 
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	temp.ActionType
		, 	1 -- auto
		, 	DATE(lv_CurrentDateTime)
        ,   CASE WHEN sp.CustID IS NOT NULL THEN sp.CustomerClass 
                 ELSE 3 -- Is New Member
			END
        ,   1 -- item name = Less than 10 bets
        ,	1 -- View History
	FROM Temp_NewCustomers AS temp
	LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = temp.CustID
	WHERE temp.ActionType = 0;  
   
    /*	GET LASTEST CUSTID LIST	-> GET LATEST CLASSICATION -> SYNC CC IN MAINDB */
    SELECT DISTINCT temp.CustId FROM Temp_NewCustomers AS temp;
END$$

DELIMITER ;