/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustomerClassLicSubAPI_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustomerClassLicSubAPI_Insert`(
		IN ip_Username VARCHAR(50)
    ,	IN ip_CustomerClass INT 
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Creator:	20250514@Casey.Huynh
		Task:	 	Validate Cust
		Server:  	CTSMain
		DBName:		CTS_DataCenter

		Revisions: 
				- 20250514@Casey.Huynh: 	Created [Redmine ID: #226847]

		Param's Explanation (filtered by): 

		Example:
			CALL CTS_DC_CustomerClassLicSub_Validate (1000);
	*/   
    
    DECLARE CONST_SUBSCRIBERID_HAIFA					INT DEFAULT 104;
    DECLARE CONST_ROLEID_MEMBER							TINYINT DEFAULT 1;   	
    DECLARE CONST_STATICLIST_LICSUBCUSTOMERCLASS		TINYINT DEFAULT 25;   
    DECLARE CONST_STATICLIST_LICSUBSTATUSCODE			TINYINT DEFAULT 26; 
	DECLARE CONST_STATICLIST_LICSUBSTATUSCODE_INVALID	SMALLINT DEFAULT 400;
    DECLARE CONST_STATICLIST_LICSUBSTATUSCODE_VALID		SMALLINT DEFAULT 300;
    
	DECLARE lv_CustID INT;
    DECLARE lv_StatusCode INT;
    DECLARE lv_ErrorMessage VARCHAR(200);
	
    SELECT	cus.CustID 
    INTO 	lv_CustID 
    FROM CTS_DataCenter.CTSCustomer AS cus
    WHERE cus.UserName = ip_UserName
		AND cus.SubscriberID = CONST_SUBSCRIBERID_HAIFA
        AND cus.RoleID = CONST_ROLEID_MEMBER
        AND ip_CustomerClass IN (	SELECT stl.ItemValue 
									FROM CTS_DataCenter.StaticList AS stl 
                                    WHERE stl.ListID = CONST_STATICLIST_LICSUBCUSTOMERCLASS);    

    IF (lv_CustID IS NOT NULL) THEN

		INSERT INTO Customer_LicSubCustomerClass(Username, CustomerClass, CustID, CreatedTime)
		SELECT cus.UserName, ip_CustomerClass, lv_CustID, ip_CreatedTime
		FROM CTS_DataCenter.CTSCustomer AS cus
		WHERE cus.CustID = lv_CustID;
        
        SELECT stl.ItemNameDisplay, stl.ItemValue
        INTO lv_ErrorMessage, lv_StatusCode  
        FROM CTS_DataCenter.StaticList AS stl 
        WHERE stl.ListID = CONST_STATICLIST_LICSUBSTATUSCODE 
			AND stl.ItemValue = CONST_STATICLIST_LICSUBSTATUSCODE_VALID;
            
	ELSE 
		SELECT stl.ItemNameDisplay, stl.ItemValue
        INTO lv_ErrorMessage
			, lv_StatusCode  
        FROM CTS_DataCenter.StaticList AS stl 
        WHERE stl.ListID = CONST_STATICLIST_LICSUBSTATUSCODE 
			AND stl.ItemValue = CONST_STATICLIST_LICSUBSTATUSCODE_INVALID;
            
	END IF;
    
    SELECT 	ID					AS SourceID
		,	ip_UserName 		AS UserName
		,	ip_CustomerClass 	AS CustomerClass
        ,	lv_ErrorMessage 	AS ErrorMessage
        ,	lv_StatusCode 		AS StatusCode
	;    
END$$
DELIMITER ;
