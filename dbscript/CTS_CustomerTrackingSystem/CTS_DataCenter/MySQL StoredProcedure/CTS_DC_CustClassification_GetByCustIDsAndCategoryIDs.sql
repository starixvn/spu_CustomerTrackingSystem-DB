/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_GetByCustIDsAndCategoryIDs`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_GetByCustIDsAndCategoryIDs`(
	  IN ip_CustSport      	JSON
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20200612@Casey.Huynh
		Task:  Return the auto tag customer list by ip_category
		DB: CTS_DataCenter
		Original:
		Revisions:
			- 20200701@Casey.Huynh: Chagne Flow and Store more Info [RedmineID: #135324]
            - 20200826@Casey.Huynh: Add Trace Performance [RedmineID: #137693]
            - 202012121@Irena.Vo: Enhance logic ignore Pin category & Probation List  [RedmineID: #145951]
            - 20210510@Aries.Nguyen: Remove insert log zzTracePerformance [Redmine ID: #154792]
			- 20210525@Irena.Vo: Change col name PinCustomerCategory: CustID -> CTSCustID [Redmine ID: 152965]
            - 20210608@Casey.Huynh: Return Category Group AND Hardcode RealTime CategoryGroup List [Redmine ID: 156465]
			- 20210722@Irena.Vo: Refactor SP [Redmine ID: 157203]  
            - 20220826@Long.Luu: Fix issue leaving blank for should-not-be-classified customer [Redmine ID: 176782]  
            - 20221007@Harvey.Nguyen: Return CurrentCategoryID [Redmine ID: #178022]
			- 20230120@Long.Luu: Support special case for Inactive (return CategoryID instead of CategoryGroup)  [Redmine ID: #182997]
            
		Param's Explanation (filtered by):    
			CALL CTS_DC_CustClassification_GetByCustIDsAndCategoryIDs('[{"CustId":7681925}]')
	*/  
	DECLARE	CONST_GROUP_NORMAL 			INT DEFAULT 200;
	
    DECLARE	CONST_CATEGORY_NEWMEMBER 	INT DEFAULT 201;
	DECLARE	CONST_CATEGORY_NORMALMEMBER INT DEFAULT 202;
	DECLARE	CONST_CATEGORY_GOODMEMBER	INT DEFAULT 205;
    DECLARE CONST_CATEGORY_INACTIVE		INT DEFAULT 1000;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RealtimeCustomers;
	CREATE TEMPORARY TABLE Temp_RealtimeCustomers(
			CustID				BIGINT UNSIGNED
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_NormalCustomer;
	CREATE TEMPORARY TABLE Temp_NormalCustomer(
			CustID			BIGINT UNSIGNED PRIMARY KEY
		,	SportGroupID	INT
        ,	CurrentCategoryID INT
        
	);

	INSERT INTO Temp_RealtimeCustomers(CustID)
	SELECT 	temp.CustID
	FROM JSON_TABLE(ip_CustSport,
		 "$[*]" COLUMNS(
			CustID 				BIGINT UNSIGNED		PATH "$.CustId"
		 )) AS temp;       
         
         
	INSERT IGNORE INTO Temp_NormalCustomer(CustID, SportGroupID, CurrentCategoryID)
	SELECT 		cate.CustID AS CustID
			, 	CONST_GROUP_NORMAL AS SportGroupID  
			, 	CASE 
					WHEN cc.CategoryGroup IN (CONST_CATEGORY_NEWMEMBER, CONST_CATEGORY_NORMALMEMBER, CONST_CATEGORY_GOODMEMBER)
						THEN cc.CategoryGroup
					WHEN cc.CategoryGroup IN (CONST_CATEGORY_INACTIVE)
						THEN cc.CategoryID
                    ELSE -1 
				END AS CurrentCategoryID
	FROM Temp_RealtimeCustomers AS temp
		INNER JOIN 	CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID
		INNER JOIN	CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID
	WHERE	cate.SportGroupID = CONST_GROUP_NORMAL
            AND NOT EXISTS (SELECT 1 
							 FROM  CTS_DataCenter.PinCustomerCategory AS pin 
							 WHERE pin.CTSCustID = cate.CTSCustID);   
  
	INSERT IGNORE INTO Temp_NormalCustomer(CustID, SportGroupID, CurrentCategoryID)
	SELECT 		temp.CustID AS CustID
			, 	CONST_GROUP_NORMAL AS SportGroupID  
			, 	CASE 
					WHEN tmpLr.CategoryGroup IN (CONST_CATEGORY_NEWMEMBER, CONST_CATEGORY_NORMALMEMBER, CONST_CATEGORY_GOODMEMBER)
						THEN tmpLr.CategoryGroup
					WHEN tmpLr.CategoryGroup IN (CONST_CATEGORY_INACTIVE)
						THEN tmpLr.CategoryID
                    ELSE -1 
				END AS CurrentCategoryID
	FROM Temp_RealtimeCustomers AS temp
    ,	LATERAL (	SELECT cate.CustID, cate.SportGroupID, cc.CategoryGroup, cc.CategoryID, cate.CTSCustID
					FROM CTS_DataCenter.CTSCustomerClassificationOldCategory AS cate						
						INNER JOIN	CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID
                    WHERE cate.CustID = temp.CustID
					ORDER BY cate.CreatedDate DESC) tmpLr
	WHERE	tmpLr.SportGroupID = CONST_GROUP_NORMAL
            AND NOT EXISTS (SELECT 1 
							 FROM  CTS_DataCenter.PinCustomerCategory AS pin 
							 WHERE pin.CTSCustID = tmpLr.CTSCustID); 
	
    SELECT 	tmpNc.CustID
		,	tmpNc.SportGroupID
        ,	tmpNc.CurrentCategoryID
	FROM Temp_NormalCustomer AS tmpNc;   
	
END$$
DELIMITER ;