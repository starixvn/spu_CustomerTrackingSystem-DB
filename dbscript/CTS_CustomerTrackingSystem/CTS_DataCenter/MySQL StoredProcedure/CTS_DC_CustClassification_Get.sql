/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Get`(
		IN ip_ListID 			TEXT
    ,	IN ip_IsCTSCustID		BIT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200423@Long.Luu	
		Task :		Get CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200423@Long.Luu [Redmine ID: #132623]: Created 
            - 20200608@Casey.Huynh: Enhance SP
            - 20200701@Casey.Huynh[135324]: Chagne Flow and Store more Info
					+ Remove rule "hide VIP IF has SmartPunter/Highrisk
            - 20200820@Roger.Le [Redmine ID: #139969]: New Column "Next Scan Date" for Customer Category
            - 20200903@Long.Luu [Redmine ID: #137550]: Get for both General & Detailed Categories
            - 20200908@Irena.Vo [Redmine ID: #141020]: Get for VVIP. VVIP -> PA -> Detailed & General. Add VVIP (General)
            - 20201006@Irena.Vo [Redmine ID: #141930]: Rollback logic get IsUsedManually for lastest category & enhance logic get.
            - 20201014-20201023@Irena.Vo [Redmine ID: #141756]: Enhance logic show Evidence Category & Normal Category. Add New General  
			- 20201202@Lex.Khuat: Disable detail categories & clean up wrong syntax [Redmine ID: #145954]
            - 20210114@Irena.Vo: Update logic SP for Get Category List & PIN. Return CategoryID [RedmineID: #145951]
            - 20210226@Jonas.Huynh: Update for Get status for tagging by association with PA [RedmineID: #150454]
			- 20210318@Irena.Vo: Update get CategoryID for color [RedmineID: #150457]
            - 20210525@Irena.Vo: Change col name PinCustomerCategory, TaggingExclusion: CustID -> CTSCustID [RedmineID: #152965] 
			- 20210622@Aries.Nguyen: Update coding convention  [Redmine ID: #157203]
			- 20211115@Irena.Vo: Re-priortize Robot and other PA categories  [Redmine ID: #164344]
			- 20220328@Aries.Nguyen: Add new category/class for PA Probation [Redmine ID: #170468]
			- 20220531@Aries.Nguyen: Renovate process PA [Redmine ID: #172561]
            
		Param's Explanation:
        
		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_Get('1',1);
	 */ 	
    DECLARE	CONST_GROUP_NORMAL 		INT DEFAULT 200;
    DECLARE	CONST_GROUP_PA 			INT DEFAULT 50;
    
    DECLARE	CONST_CATEGORYGROUP_ROBOT 		INT DEFAULT 61;
    DECLARE	CONST_CATEGORYGROUP_BADROBOT 	INT DEFAULT 163;
    DECLARE	CONST_CATEGORYGROUP_GOODROBOT	INT DEFAULT 164;
    
    DROP TEMPORARY TABLE IF EXISTS TempCusts;
    CREATE TEMPORARY TABLE TempCusts (
			ID				BIGINT UNSIGNED PRIMARY KEY
		,	CTSCustID 		BIGINT UNSIGNED
        ,	CustID 			BIGINT UNSIGNED
    );
    
	DROP TEMPORARY TABLE IF EXISTS Temp_LatestRecordOfCategory;
    CREATE TEMPORARY TABLE Temp_LatestRecordOfCategory(
			CustID	 		BIGINT UNSIGNED
        ,   CTSCustID		BIGINT UNSIGNED 
		,	CategoryID		SMALLINT UNSIGNED
		,   CategoryName   	VARCHAR(200) 
        ,	CategoryGroup   SMALLINT UNSIGNED
		,   CategoryType    SMALLINT UNSIGNED /*1: ParentID = 200, 2: ParentID = 50*/
		,	ParentID		SMALLINT UNSIGNED
		,	IsProbation		BIT DEFAULT 0
    );
    
    SET @sql = CONCAT("INSERT INTO TempCusts (ID) VALUES ('", REPLACE(ip_ListID, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    IF ip_IsCTSCustID = 1 
    THEN 
		UPDATE TempCusts AS temp
		INNER JOIN CTSCustomer AS cus ON temp.ID = cus.CTSCustID
		SET 	temp.CTSCustID = cus.CTSCustID
			,	temp.CustID = cus.CustID;
    ELSE 
		UPDATE TempCusts AS temp
		INNER JOIN CTSCustomer AS cus ON temp.ID = cus.CustID AND cus.CustSubID = 0
		SET 	temp.CTSCustID = cus.CTSCustID
			,	temp.CustID = cus.CustID;
    END IF;
       
	INSERT INTO Temp_LatestRecordOfCategory(CustID, CTSCustID, CategoryID, CategoryName, CategoryGroup, CategoryType, ParentID, IsProbation)
	SELECT DISTINCT temp.CustID
				,	temp.CTSCustID
				,	(CASE 
                        WHEN cc.ParentID = CONST_GROUP_PA THEN cc.CategoryGroup
                        ELSE cate.CategoryID 
					END)
				,	cc.CategoryName
                ,	cc.CategoryGroup
				,	(CASE WHEN cc.ParentID = CONST_GROUP_PA THEN 2 WHEN cc.ParentID = CONST_GROUP_NORMAL  THEN 1 END) 
				,	cc.ParentID
				,	IsPAProbation AS IsProbation
	FROM	CTS_DataCenter.CTSCustomerClassification AS cate
		INNER JOIN TempCusts AS temp ON temp.CTSCustID = cate.CTSCustID
		INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID
    WHERE cc.ParentID IN (CONST_GROUP_PA, CONST_GROUP_NORMAL)
        AND cc.IsActive = 1;
    
    IF (SELECT COUNT(DISTINCT ParentID) FROM Temp_LatestRecordOfCategory) > 1 THEN
		DELETE FROM Temp_LatestRecordOfCategory WHERE ParentID = CONST_GROUP_NORMAL;
    END IF;
    
    IF EXISTS (SELECT 1 FROM CTS_DataCenter.PinCustomerCategory AS pinCate
					INNER JOIN TempCusts AS temp ON temp.CTSCustID = pinCate.CTSCustID) THEN 
		SELECT 1 AS IsPinCategory;
	ELSE 
		SELECT 0 AS IsPinCategory;
	END IF;
        
	IF EXISTS (SELECT 1 FROM CTS_DataCenter.TaggingExclusion AS tagExclusion
					INNER JOIN TempCusts AS temp ON temp.CTSCustID = tagExclusion.CTSCustID) THEN 
		SELECT 1 AS IsExcludedTagAssPA;
	ELSE 
		SELECT 0 AS IsExcludedTagAssPA;
	END IF; 

	SELECT	CTSCustID
		,	CustID
		,	CategoryType 
		,	CategoryID
		,	CategoryName
        ,	CategoryGroup
		,	ParentID
		,	IsProbation 
	FROM Temp_LatestRecordOfCategory;
END$$
DELIMITER ;