/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_SpecialCustClass_InsertRobotUsers`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_SpecialCustClass_InsertRobotUsers`(
		IN ip_CustIDs           TEXT

	,	OUT op_ErrorMessage     VARCHAR(200)
)
    SQL SECURITY INVOKER
BEGIN
  /*
		Created:	Irena.Vo@20200911
		Task:		Insert Robot Customer Class 
		DB:			CTS_DataCenter
		Original:
        
        Revision:
			- 20200911@Irena.Vo: Created. Support for Licensee & 611111 sites  [Redmine ID: #141416]
            - 20200921@Irena.Vo: Enhance SP & insert Probation Management flow.  [Redmine ID: #141755]  
			- 20210107@Irena.Vo: Remove logic delete Probation List. Enhance logic get VVIP & Insert History Log. Insert Error Log. Remove User Log [RedmineID: #145951]
            - 20210226@Irena.Vo: Update CategoryID from VVIP [RedmineID: #150454]
            - 20210316@Irena.Vo: Remove log. Get Robot User category more. [RedmineID: #151374]
            - 20210622@Aries.Nguyen: Update coding convention [Redmine ID: #157203]

		Param's Explanation (filtered by):
            - ip_CustIDs = 1,2,3
                
	*/
    DECLARE	CONST_CATEGORYID_VVIP 	        INT DEFAULT 210;
    DECLARE	CONST_GROUP_NORMAL		        INT DEFAULT 200;
    DECLARE	CONST_CATEGORYID_ROBOTUSERS 	INT DEFAULT 61;

    DECLARE lv_CurrentDateTime 	DATETIME DEFAULT CURRENT_TIME();
    DECLARE lv_CreatedBy 		INT DEFAULT 10278938;
    
    DECLARE	lv_No				INT			 DEFAULT 0;
    DECLARE lv_ErrorNo 			INT          DEFAULT 0;
    DECLARE lv_CodName 			VARCHAR(200) DEFAULT '0';

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN   
		GET DIAGNOSTICS lv_No 	= 	NUMBER;
		GET DIAGNOSTICS CONDITION lv_No 
            op_ErrorMessage 	= 	MESSAGE_TEXT	
		,	lv_ErrorNo 			= 	MYSQL_ERRNO
		,	lv_CodName 			= 	RETURNED_SQLSTATE;
    
        INSERT INTO CTS_Log.CTSErrorLog(EventID, Message, Description)
        VALUES(12, op_ErrorMessage, JSON_OBJECT('err_no',lv_ErrorNo,'cod_name',lv_CodName,'parameter',ip_CustIDs));
    END;

    DROP TEMPORARY TABLE IF EXISTS Temp_VVIP;
    CREATE TEMPORARY TABLE Temp_VVIP(
			CustID	BIGINT UNSIGNED PRIMARY KEY
    );

    DROP TEMPORARY TABLE IF EXISTS Temp_CustInfo;
    CREATE TEMPORARY TABLE Temp_CustInfo(
			CustID	BIGINT UNSIGNED PRIMARY KEY
        ,	CTSCustID	BIGINT UNSIGNED
        ,	SubscriberID INT
    );

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
    INSERT IGNORE INTO Temp_VVIP(CustID)
    SELECT temp.CustID
    FROM Temp_RobotUsers AS temp
        INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID AND cate.SportGroupID = CONST_GROUP_NORMAL AND cate.CategoryID = CONST_CATEGORYID_VVIP;

    DELETE temp
    FROM Temp_RobotUsers AS temp 
        INNER JOIN Temp_VVIP AS vv ON vv.CustID = temp.CustID;

	/*	DELETE SPECIAL CUSTOMER CLASS BEFORE (INCLUDE ROBOT) */
    DELETE sc
    FROM CTS_DataCenter.SpecialCustomerClass AS sc
        INNER JOIN Temp_RobotUsers AS temp ON temp.CustID = sc.CustID;
    
	/*	UPDATE CUST INFO	*/
    INSERT IGNORE INTO Temp_CustInfo(CustID, CTSCustID, SubscriberID)
    SELECT temp.CustID
        ,   cust.CTSCustID
        ,   cust.SubscriberID
    FROM Temp_RobotUsers AS temp
        INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID AND cust.CustSubID = 0;


    UPDATE Temp_RobotUsers AS temp
        INNER JOIN Temp_CustInfo AS cust ON temp.CustID = cust.CustID
    SET   temp.CTSCustID = cust.CTSCustID
        , temp.SubscriberID = cust.SubscriberID;
    
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
  
    /* GET Robot User Category*/
    SELECT 	DISTINCT 
            CustId
        ,   CONST_CATEGORYID_ROBOTUSERS AS CategoryId 
    FROM Temp_RobotUsers; 
END$$

DELIMITER ;