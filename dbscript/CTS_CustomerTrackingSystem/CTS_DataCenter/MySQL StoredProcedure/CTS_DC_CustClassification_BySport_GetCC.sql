/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_BySport_GetCC`;

DELIMITER $$
CREATE PROCEDURE `CTS_DC_CustClassification_BySport_GetCC`(
	IN ip_Custs JSON
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220909@Harvey.Nguyen	
		Task :		Get lastest Classification
		DB:			CTS_DataCenter  
		Original: 
		Revisions:
			- 20220909@Harvey.Nguyen: Created [RedmineID: #176992]
            - 20230725@Jonas.Huynh: Renovate BySport [Redmine ID: #189875]
            - 20240319@Thomas.Nguyen: Add logic for Special CC BySport [Redmine ID: #201360]

        Param's Explanation:     
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_BySport_GetCC('[{"CustID": "1", "SportGroup":43}]');
	*/ 

    DROP TEMPORARY TABLE IF EXISTS Temp_CustInfo;
    CREATE TEMPORARY TABLE 		Temp_CustInfo (
        	CustID		BIGINT UNSIGNED
		,	SportGroup	SMALLINT UNSIGNED	
        ,	PRIMARY KEY (CustID, SportGroup)
    );    
    
    INSERT IGNORE INTO Temp_CustInfo (CustID, SportGroup)
    SELECT DISTINCT temp.CustID
                , 	temp.SportGroup
	 FROM JSON_TABLE(ip_Custs,
		"$[*]" COLUMNS(
				CustID 				BIGINT UNSIGNED		PATH "$.CustID"	
            , 	SportGroup			SMALLINT UNSIGNED	PATH "$.SportGroup"		
		 )) AS 	temp;              

	IF EXISTS (SELECT 1 FROM Temp_CustInfo AS tmp 
							INNER JOIN SpecialCustomerClass_BySport AS sb ON sb.CustID = tmp.CustID AND sb.SportID = tmp.SportGroup)	THEN
		SELECT	sb.CustID
			,	sb.SportID
			,	sb.CustomerClass
		FROM Temp_CustInfo AS tmp 
		INNER JOIN SpecialCustomerClass_BySport AS sb ON sb.CustID = tmp.CustID AND sb.SportID = tmp.SportGroup;
	ELSE     
		SELECT	clss.CustID
			,	clss.SportID
			,	IFNULL(cate.CustomerClass, - 1) AS CustomerClass
		FROM Temp_CustInfo temp
			INNER JOIN CTSCustomerClassification_BySport AS clss ON temp.CustID = clss.CustID AND temp.SportGroup = clss.SportID
			INNER JOIN CustomerCategory AS cate ON cate.CategoryID = clss.CategoryID;
	END IF;

END$$

DELIMITER ;