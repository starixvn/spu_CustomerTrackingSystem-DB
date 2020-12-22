/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustClassification_Get`;

DELIMITER $$
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
            - 20201014-20201023@Irena.Vo [Redmine ID: #141756]: Enhance logic show Evidence Category & Normal Category. Add New General  
			- 20201202@Lex.Khuat: Disable detail categories & clean up wrong syntax [Redmine ID: #145954]
               - 20201222@Irena.Vo: Update logic SP for Get Category List & PIN [RedmineID: #145951]
            
		Param's Explanation:
	*/ 
	DROP TEMPORARY TABLE IF EXISTS Temp_LatestRecordOfCategory;
    CREATE TEMPORARY TABLE Temp_LatestRecordOfCategory (
    	CategoryID			SMALLINT UNSIGNED
	,   DisplayCategoryID   SMALLINT UNSIGNED 
    , 	LastModifiedDate	DATETIME
	,   CategoryType        SMALLINT UNSIGNED -- 1: ParentID = 200, 2: ParentID = 50
    );
   
    DROP TEMPORARY TABLE IF EXISTS Temp_RangeDateCategory;
    CREATE TEMPORARY TABLE Temp_RangeDateCategory (
		DisplayCategoryID   	SMALLINT UNSIGNED 
	 , 	MinLastModifiedDate   	DATETIME
     , 	MaxLastModifiedDate   	DATETIME        
    );
     
    -- Get Lastest category list
	 INSERT INTO Temp_LatestRecordOfCategory (CategoryID, CategoryType)
     SELECT   cc.CategoryID
            ,	CASE	WHEN cate.ParentID = 50 THEN 2 -- red
						WHEN cate.ParentID = 200  THEN 1 -- any color 
				END
	FROM	CTS_DataCenter.CTSCustomerClassification AS cc
    INNER JOIN 	CTS_DataCenter.CustomerCategory AS cate ON cc.CategoryID = cate.CategoryID
    WHERE	cc.CustID = ip_CustID AND cate.ParentID IN (50, 200);
    
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
    
    -- Choose Lastest Display Category with scan date
    INSERT INTO Temp_RangeDateCategory
    SELECT  DisplayCategoryID,	MIN(LastModifiedDate),   MAX(LastModifiedDate)
    FROM Temp_LatestRecordOfCategory
    GROUP BY DisplayCategoryID;

    DELETE temp
    FROM Temp_LatestRecordOfCategory  AS temp 
	INNER JOIN Temp_RangeDateCategory AS u ON u.DisplayCategoryID = temp.DisplayCategoryID
    WHERE temp.LastModifiedDate = u.MinLastModifiedDate AND u.MinLastModifiedDate <> u.MaxLastModifiedDate; 

    -- Show results
     IF EXISTS (SELECT 1 FROM CTS_DataCenter.PinCustomerCategory WHERE CustID = ip_CustID) THEN
			SELECT 1 AS IsPinCategory;
	 ELSE 
            SELECT 0 AS IsPinCategory;
	 END IF;
        
	 SELECT  temp.CategoryType,   cc.CategoryName
     FROM Temp_LatestRecordOfCategory AS temp
	 INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = temp.DisplayCategoryID
	 GROUP BY temp.CategoryType,   cc.CategoryName;
END$$

DELIMITER ;