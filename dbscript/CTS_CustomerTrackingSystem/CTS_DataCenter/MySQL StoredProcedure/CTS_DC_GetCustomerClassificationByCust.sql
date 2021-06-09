/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_GetCustomerClassificationByCust`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_GetCustomerClassificationByCust`(
		IN ip_CustSport    JSON
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
		Param's Explanation (filtered by):
            - lv_CategoryIDList: ex: '1,2,3'       
	*/     
    DECLARE	lv_LogTotalRecord	INT;
    DECLARE	lv_FromID			BIGINT;
    DECLARE	lv_ToID				BIGINT;    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustSportList;
	CREATE TEMPORARY TABLE Temp_CustSportList(
			CustID				BIGINT UNSIGNED
		, 	SportGroupID		SMALLINT UNSIGNED
	);
 
	INSERT INTO Temp_CustSportList(CustID, SportGroupID)
	SELECT 	tmpTable.CustID
		, 	tmpTable.SportGroupID
	FROM JSON_TABLE(ip_CustSport,
		 "$[*]" COLUMNS(
			CustID 				BIGINT UNSIGNED		PATH "$.CustId"
		, 	SportGroupID 		SMALLINT UNSIGNED	PATH "$.SportGroupId"
		 )) AS tmpTable;       
   
    SELECT		tmpCusCat.CustID
			, 	tmpCusCat.SportGroupID AS SportGroupID
			, 	tmpCusCat.CategoryID
	FROM	(   SELECT 		cus.CustID AS CustID
						,	c.CTSCustID AS CTSCustID
						, 	cus.SportGroupID AS SportGroupID  
						, 	ccl.SportGroupID AS CurrentSportGroupID
						, 	ctg.CategoryGroup AS CategoryID
				FROM Temp_CustSportList AS cus
					LEFT JOIN 	CTS_DataCenter.CTSCustomer AS c ON c.CustID = cus.CustID AND c.CustSubID = 0
					LEFT JOIN 	CTS_DataCenter.CTSCustomerClassification AS ccl ON cus.CustID = ccl.CustID AND cus.SportGroupID = ccl.SportGroupID
					INNER JOIN	CTS_DataCenter.CustomerCategory AS ctg ON ccl.CategoryID = ctg.CategoryID
					WHERE 		ctg.CategoryGroup IN (201, 202, 205, 231, 232, 233, 222, 221, 223, 212, 211, 213)
			) AS tmpCusCat
		LEFT JOIN CTS_DataCenter.PinCustomerCategory AS pin ON pin.CTSCustID = tmpCusCat.CTSCustID
		LEFT JOIN CTS_DataCenter.ProbationAccountMonitor AS pro ON pro.CustID = tmpCusCat.CustID AND pro.SportGroupID = 200
	WHERE	pin.CTSCustID IS NULL 
            AND pro.SportGroupID IS NULL
            AND (tmpCusCat.CurrentSportGroupID IS NULL OR tmpCusCat.CategoryID IS NOT NULL);

	SELECT 	COUNT(1), MIN(CustID), MAX(CustID)
    INTO	lv_LogTotalRecord, lv_FromID, lv_ToID
    FROM	Temp_CustSportList;    
END$$
DELIMITER ;