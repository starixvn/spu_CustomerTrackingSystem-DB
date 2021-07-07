/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService,ctsWeb" isFunction="0" isNested="1"></info>*/ 
DROP PROCEDURE IF EXISTS `CTS_DC_RPT_AssociationDetection`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_RPT_AssociationDetection`(
		IN ip_CTSCustIDs TEXT
)
    SQL SECURITY INVOKER
sp:BEGIN
	/* 
		Created:	20210629@Casey.Huynh
		Task:		Get Report Association Detection
		DB:			CTS_DataCenter
        
		Revisions:
			- 20210629@Casey.Huynh: Created [Redmine ID: #157086]
            
		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DataCenter.CTS_DC_Association_GetGroupLevel2(200);
	*/
    
	
    CALL CTS_DC_Association_GetGroup2LevelToTemp_CustGroup2L(ip_CTSCustIDs);
	
    /**DEBUG**/
    insert into CTS_Adhoc.PerformanceCheck(Step, StartTime, Comments)
    Values(@Step:=@Step+1,CURRENT_TIMESTAMP(3),'');
     /**DEBUG**/
    
    SELECT tmpCg.GroupID
		,	tmpCg.UserName
        ,	tmpCg.CustStatus
		, 	TRIM(GROUP_CONCAT(DISTINCT ' ',evd.EvidenceCode,' ',evd.EvidenceName)) AS Evidence
        , 	TRIM(GROUP_CONCAT(DISTINCT ' ',cat.CategoryName)) AS CustomerCategory
        ,	TRIM(GROUP_CONCAT(DISTINCT cat.CategoryID)) AS CategoryIDs
        ,	TRIM(GROUP_CONCAT(DISTINCT cat.ParentID)) AS ParentIDs
        ,	tmpCg.CTSCustID
        ,	tmpCg.CustID
        ,	tmpCg.CustSubID        
    FROM Temp_CustGroup2L AS tmpCg
		LEFT JOIN CTS_DataCenter.CustEvidence AS ced ON tmpCg.CTSCustID = ced.CTSCustID
        LEFT JOIN CTS_DataCenter.Evidence AS evd ON ced.EvidenceID = evd.EvidenceID
        LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS ccl ON tmpCg.CustID = ccl.CustID AND tmpCg.CustSubID = 0
        LEFT JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = ccl.CategoryID
	GROUP BY tmpCg.GroupID, tmpCg.UserName, tmpCg.CustStatus, tmpCg.CTSCustID, tmpCg.CustID, tmpCg.CustSubID;        
   
    /**DEBUG**/
    insert into CTS_Adhoc.PerformanceCheck(Step, StartTime, Comments)
    Values(@Step:=@Step+1,CURRENT_TIMESTAMP(3),'');
     /**DEBUG**/
    
END$$

DELIMITER ;
