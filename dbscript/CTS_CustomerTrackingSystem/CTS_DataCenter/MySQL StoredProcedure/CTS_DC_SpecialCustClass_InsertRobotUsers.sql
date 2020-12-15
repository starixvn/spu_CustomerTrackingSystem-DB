/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_SpecialCustClass_InsertRobotUsers`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_SpecialCustClass_InsertRobotUsers`(IN ip_CustIDs text)
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
			- 20201214@Irena.Vo: Remove logic delete Probation List. Enhance logic get VVIP & Update History Log. Return ScannedTime [RedmineID: #145951]
            
		Param's Explanation (filtered by):
        ip_CustIDs = 1,2,3
                
	*/
    DECLARE lv_CurrentDateTime 	DATETIME DEFAULT NOW();
    DECLARE lv_CreatedBy INT DEFAULT 10278938;
    DECLARE lv_SPName VARCHAR(200) DEFAULT 'CTS_DC_SpecialCustClass_InsertRobotUsers';
    
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
    INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID 
    WHERE cate.CategoryID = 213;

    /*	IGNORE ROBOT BEFORE	*/
    DELETE temp
    FROM Temp_RobotUsers AS temp 
    INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sc ON sc.CustID = temp.CustID
    WHERE sc.CreatedFromFunction = 1 AND sc.CustomerClass = 13;
   
	/*	DELETE SPECIAL CUSTOMER CLASS BEFORE	*/
    DELETE sc
    FROM CTS_DataCenter.SpecialCustomerClass AS sc
    INNER JOIN Temp_RobotUsers AS temp ON temp.CustID = sc.CustID
    WHERE sc.CreatedFromFunction = 1;
    
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
    SELECT 19, lv_SPName, CONCAT('Insert SpecialCustomerClass: ip_CTSCustID = ', temp.CTSCustID, ';ip_CustomerClass = ', 13), lv_CurrentDateTime, lv_CreatedBy
    FROM Temp_RobotUsers AS temp;
    
    /*	INSERT LOG	*/
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
    (CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType,  IsAuto, InsertDate, TargetCC, SourceTypeID)
    SELECT    temp.CustID
			, temp.CTSCustID
			, CASE WHEN cate.CategoryID IS NULL THEN 201
                   ELSE cate.CategoryID
			  END 
            , CASE WHEN cate.CategoryID IS NULL THEN 200
                   ELSE cate.SportGroupID
			  END
            , lv_CurrentDateTime
            , lv_CreatedBy
			, 0 -- insert
            , 1 -- auto
            , DATE(lv_CurrentDateTime)
            , 13 -- is Robot
            , 11 -- item name = Change by Robot icon
	FROM Temp_RobotUsers AS temp
    LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID;
    
    SELECT 	DISTINCT CustId
		,	13 AS CustomerClass
        ,   lv_CurrentDateTime AS ScannedTime
	FROM Temp_RobotUsers;
    
END$$

DELIMITER ;