USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_CustClassification_Get`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Get`(IN ip_CustID 	INT UNSIGNED)
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
            - [20200701@Casey.Huynh][135324]: Chagne Flow and Store more Info
					+ Remove rule "hide VIP IF has SmartPunter/Highrisk
            - 20200820@Roger.Le [Redmine ID: #139969]: New Column "Next Scan Date" for Customer Category
            - 20200903@Long.Luu [Redmine ID: #137550]: Get for both General & Detailed Categories
            - 20200908@Irena.Vo [Redmine ID: #141020]: Get for VVIP. VVIP -> PA -> Detailed & General. Add VVIP (General)
            - 20201006@Irena.Vo [Redmine ID: #141930]: Rollback logic get IsUsedManually for lastest category & enhance logic get.
            - 20201014-20201023@Irena.Vo [Redmine ID: #141756]: Enhance logic show Evidence Category & Normal Category
            
		Param's Explanation:
	*/ 
	DECLARE lv_Remark VARCHAR(200) DEFAULT 'Auto tag customer classification';
    DECLARE lv_IsPinCategory BIT DEFAULT 0;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_LatestRecordOfCategory;
    CREATE TEMPORARY TABLE Temp_LatestRecordOfCategory (
    	CategoryID			SMALLINT UNSIGNED
	,   DisplayCategoryID   SMALLINT UNSIGNED 
    ,   SportGroupID		SMALLINT UNSIGNED
	, 	Remark				VARCHAR(500) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
    , 	LastModifiedDate	DATETIME
    ,	LastModifiedBy		INT UNSIGNED
    , 	LastScannedDate		DATETIME
	,   CategoryType        SMALLINT UNSIGNED -- 0: ParentID = 1, 1: ParentID = 200, 2: ParentID = 50, 3: CategoryID = 2
    );
   
    DROP TEMPORARY TABLE IF EXISTS Temp_GeneralCategory;
    CREATE TEMPORARY TABLE Temp_GeneralCategory (
    	CategoryID			SMALLINT UNSIGNED
     );
   
     SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
     SET SQL_SAFE_UPDATES = 0;
     
     IF EXISTS (SELECT 1 FROM CTS_DataCenter.SpecialCustomerClass WHERE CustID = ip_CustID AND CreatedFromFunction = 21) THEN
		SET lv_IsPinCategory = 1;
     END IF;
   
    -- Get Lastest category list
	 INSERT INTO Temp_LatestRecordOfCategory (CategoryID, SportGroupID, LastModifiedBy, LastModifiedDate, Remark, LastScannedDate)
     SELECT   cate.CategoryID
			, cate.SportGroupID
			, cate.LastModifiedBy
			, cate.LastModifiedDate
			, cate.Remark
			, cate.LastScannedDate
	FROM		CTS_DataCenter.CTSCustomerClassification AS cate
    WHERE		cate.CustID = ip_CustID;
    
    -- Get General Category
    INSERT INTO Temp_GeneralCategory
    SELECT DISTINCT temp.CategoryID 
    FROM Temp_LatestRecordOfCategory AS temp 
    INNER JOIN 	CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = temp.CategoryID
    WHERE cc.ParentID = 200;
     
    -- Insert new General New Member
    IF NOT EXISTS (SELECT 1 FROM Temp_GeneralCategory) THEN
		INSERT INTO Temp_LatestRecordOfCategory (CategoryID, SportGroupID, LastModifiedBy, LastModifiedDate, Remark, LastScannedDate)
		SELECT   201, 0, cate.LastModifiedBy, cate.LastModifiedDate, cate.Remark, NULL
        FROM	CTS_DataCenter.CTSCustomerClassification AS cate
        WHERE   cate.CategoryID = 2 AND cate.CustID = ip_CustID; 
    END IF;
    
    -- Update Display Category ID
    UPDATE  Temp_LatestRecordOfCategory
    SET   DisplayCategoryID = (CASE WHEN CategoryID = 151 THEN 51
                                    WHEN CategoryID IN (72, 152) THEN 52
									WHEN CategoryID IN (73, 153) THEN 53
                                    WHEN CategoryID IN (74, 154) THEN 54 
                                    WHEN CategoryID IN (75, 155) THEN 55
                                    WHEN CategoryID IN (76, 156) THEN 56
									WHEN CategoryID IN (77, 157) THEN 57
									WHEN CategoryID IN (78, 158) THEN 58
									WHEN CategoryID IN (79, 159) THEN 59
									WHEN CategoryID = 80 THEN 60
                                    ELSE CategoryID
								END);
    
	UPDATE Temp_LatestRecordOfCategory AS temp
    INNER JOIN 	CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = temp.DisplayCategoryID
    SET temp.CategoryType =	( CASE
								  WHEN cc.ParentID = 50 THEN 2 -- parse 2 row (detail&general) & red
								  WHEN cc.ParentID = 200  THEN 1 -- parse 1 row (general)  & any color 
								  WHEN cc.ParentID = 1 THEN 0 -- parse 1 row (detail) & any color
					         END)
	WHERE temp.CategoryType IS NULL;

-- Show results
       SELECT  cc.ParentID
		,   temp.CategoryType
        ,   temp.DisplayCategoryID AS CategoryID
		,	cc.CategoryName
        , 	LEFT(GROUP_CONCAT(s.SportGroupID ORDER BY s.SportGroupID ASC SEPARATOR ', '),255) AS SportGroupIDList
        , 	LEFT(GROUP_CONCAT(s.SportGroupName ORDER BY s.SportGroupID ASC SEPARATOR ', '),255) AS SportGroupNameList
        ,	CASE  WHEN cc.CategoryID IN (3, 213) THEN temp.Remark
                  WHEN cc.IsUsedManually = 0 THEN lv_Remark
			END AS Remark
        ,	u.UserName AS LastModifiedBy
        ,	MAX(temp.LastModifiedDate) AS LastModifiedDate
        ,   CASE WHEN lv_IsPinCategory = 1  THEN NULL
				 ELSE DATE_ADD(MIN(temp.LastScannedDate), INTERVAL cc.ScanIntervalInSecond SECOND) 
			END AS NextScanFromDate
        , 	 CASE WHEN lv_IsPinCategory = 1  THEN NULL
				 ELSE DATE_ADD(MAX(temp.LastScannedDate), INTERVAL cc.ScanIntervalInSecond SECOND) 
			END AS NextScanToDate
        ,	cc.IsUsedManually AS IsEnabledDelete -- only VVIP can delete
        FROM ( SELECT CategoryType, SportGroupId, DisplayCategoryID, LastScannedDate, LastModifiedBy, Remark, MAX(LastModifiedDate) AS LastModifiedDate
               FROM Temp_LatestRecordOfCategory 
               GROUP BY CategoryType, SportGroupId, DisplayCategoryID, LastScannedDate, LastModifiedBy, Remark
		      ) AS temp
        INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = temp.DisplayCategoryID
		LEFT JOIN CTS_DataCenter.SportGroup AS s ON s.SportGroupID = temp.SportGroupID
        LEFT JOIN CTS_Admin.CTSUser AS u ON u.UserID = temp.LastModifiedBy
		 GROUP BY cc.ParentID
			,   temp.CategoryType
			,   temp.DisplayCategoryID
			,	cc.CategoryName
			,   temp.Remark
			,	temp.LastModifiedBy
			, 	u.Username
			,	cc.IsUsedManually
			,	cc.ScanIntervalInSecond
		ORDER BY LastModifiedDate DESC;
    
	# Begin: Cleanup
	DROP TEMPORARY TABLE IF EXISTS Temp_GeneralCategory;
    DROP TEMPORARY TABLE IF EXISTS Temp_LatestRecordOfCategory;  
	# End: Cleanup
    
    -- Return isPinCategory for customer
	SELECT lv_IsPinCategory AS isPinCategory;    
    
	SET SQL_SAFE_UPDATES = 1;
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ; 
    
END$$

DELIMITER ;