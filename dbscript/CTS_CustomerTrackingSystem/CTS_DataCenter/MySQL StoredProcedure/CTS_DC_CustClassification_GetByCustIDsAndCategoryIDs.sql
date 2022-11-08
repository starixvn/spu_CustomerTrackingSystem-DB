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
            
		Param's Explanation (filtered by):    
	*/  
	DECLARE	CONST_GROUP_NORMAL 			INT DEFAULT 200;
	
    DECLARE	CONST_CATEGORY_NEWMEMBER 	INT DEFAULT 201;
	DECLARE	CONST_CATEGORY_NORMALMEMBER INT DEFAULT 202;
	DECLARE	CONST_CATEGORY_VIP 			INT DEFAULT 205;
    DECLARE CONST_CATEGORY_INACTIVE		INT DEFAULT 1000;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RealtimeCustomers;
	CREATE TEMPORARY TABLE Temp_RealtimeCustomers(
			CustID				BIGINT UNSIGNED
	);

	INSERT INTO Temp_RealtimeCustomers(CustID)
	SELECT 	temp.CustID
	FROM JSON_TABLE(ip_CustSport,
		 "$[*]" COLUMNS(
			CustID 				BIGINT UNSIGNED		PATH "$.CustId"
		 )) AS temp;       
         
	SELECT 		cate.CustID AS CustID
			, 	CONST_GROUP_NORMAL AS SportGroupID  
			, 	CASE 
					WHEN cc.CategoryGroup IN (CONST_CATEGORY_NEWMEMBER, CONST_CATEGORY_NORMALMEMBER, CONST_CATEGORY_VIP, CONST_CATEGORY_INACTIVE)
						THEN cc.CategoryGroup
                    ELSE -1 
				END AS CategoryID
	FROM Temp_RealtimeCustomers AS temp
		INNER JOIN 	CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID
		INNER JOIN	CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID
	WHERE	cate.SportGroupID = CONST_GROUP_NORMAL
            AND NOT EXISTS (SELECT 1 
							 FROM  CTS_DataCenter.PinCustomerCategory AS pin 
							 WHERE pin.CTSCustID = cate.CTSCustID);
END$$
DELIMITER ;