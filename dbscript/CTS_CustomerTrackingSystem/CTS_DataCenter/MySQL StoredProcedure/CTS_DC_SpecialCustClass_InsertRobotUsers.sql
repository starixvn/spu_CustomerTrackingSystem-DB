/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_SpecialCustClass_InsertRobotUsers`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_SpecialCustClass_InsertRobotUsers`(IN ip_CustIDs TEXT,OUT op_ErrorMessage varchar(200))
    SQL SECURITY INVOKER
BEGIN
  /*
		Created:	Irena.Vo@20200911
		Task:		Insert Robot Customer Class 
		DB:			CTS_DataCenter
		Original:
        
        Revision:
			- [20200911@Irena.Vo][141416]: Created. Support for Licensee & 611111 sites 
            - [20200921@Irena.Vo][141755]: Enhance SP & insert Probation Management flow.    
			- [20200923@Irena.Vo][141755]: Enhance SP
			- 20201214-20201229@Irena.Vo: Remove logic delete Probation List. Enhance logic get VVIP & Insert History Log. Insert Error Log [RedmineID: #145951]
            
		Param's Explanation (filtered by):
        ip_CustIDs = 1,2,3
                
	*/
    DECLARE lv_CurrentDateTime 	DATETIME DEFAULT CURRENT_TIME();
    DECLARE lv_CreatedBy 		INT DEFAULT 10278938;
    DECLARE lv_SPName 			VARCHAR(200) DEFAULT 'CTS_DC_SpecialCustClass_InsertRobotUsers';
    
    DECLARE op_ErrorNo 			INT DEFAULT 0;
    DECLARE op_CodName 			TEXT DEFAULT '0';

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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RobotUsers;
    CREATE TEMPORARY TABLE Temp_RobotUsers(
			CustID	BIGINT UNSIGNED PRIMARY KEY
		,	CTSCustID	BIGINT UNSIGNED
        ,	SubscriberID INT
    );
    
    SET @sql = CONCAT("INSERT INTO Temp_RobotUsers(CustID) VALUES ('", REPLACE(ip_CustIDs,",","'),('"),"');");
	PREPARE stm1 FROM @sql;
	EXECUTE stm1;

    /*	IGNORE VVIP BEFORE	*/
    DELETE temp
    FROM Temp_RobotUsers AS temp 
    INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID AND cate.SportGroupID = 200 AND cate.CategoryID = 213;

	/*	DELETE SPECIAL CUSTOMER CLASS BEFORE (INCLUDE ROBOT) */
    DELETE sc
    FROM CTS_DataCenter.SpecialCustomerClass AS sc
    INNER JOIN Temp_RobotUsers AS temp ON temp.CustID = sc.CustID;
    
	/*	UPDATE CUST INFO	*/
    UPDATE Temp_RobotUsers AS temp
    INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID AND cust.CustSubID = 0
    SET   temp.CTSCustID = cust.CTSCustID, temp.SubscriberID = cust.SubscriberID;
    
    /*	INSERT ROBOT CUSTOMER CLASS	*/
    INSERT INTO CTS_DataCenter.SpecialCustomerClass(CTSCustID, CustID, RootCTSCustID, SubscriberID, CustomerClass, CreatedBy, CreatedDate, LastModifiedBy, LastModifiedDate, CreatedFromFunction)
	SELECT 	temp.CTSCustID
		,	temp.CustID
		,	temp.CTSCustID
		,	temp.SubscriberID
		,	13
		,	lv_CreatedBy
		,	lv_CurrentDateTime
		,	lv_CreatedBy
		,	lv_CurrentDateTime
		,   1 -- For Special Customer
	FROM Temp_RobotUsers AS temp;
  
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
    SELECT 19, lv_SPName, CONCAT('Insert Robot User: ip_CustID = ', temp.CustID, ';ip_CustomerClass = ', 13), lv_CurrentDateTime, lv_CreatedBy
    FROM Temp_RobotUsers AS temp;
    
    /*	INSERT LOG	*/
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
    (CustID, CTSCustID, LastModifiedDate, LastModifiedBy, ActionType,  IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
    SELECT    temp.CustID
			, temp.CTSCustID
            , lv_CurrentDateTime
            , lv_CreatedBy
			, 0 -- insert
            , 1 -- auto
            , DATE(lv_CurrentDateTime)
            , 13 -- is Robot
            , 11 -- item name = Change by Robot icon
            , 1 -- View History
	FROM Temp_RobotUsers AS temp;
    
    /* GET LATEST CC*/
    SELECT 	DISTINCT CustId,	13 AS CustomerClass,   lv_CurrentDateTime AS ScannedTime FROM Temp_RobotUsers; 
END$$

DELIMITER ;