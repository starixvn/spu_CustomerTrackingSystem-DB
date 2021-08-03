/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_DailyScan_UpdateStatus`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_DailyScan_UpdateStatus`(
        IN ip_CustSport JSON
)
	SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20200625@Casey.Huynh
		Task: Update Last Scanned If completed
		DB: CTS_DataCenter
		Original:
		Revisions:
			- 20200701@Casey.Huynh: Chagne Flow and Store more Info [RedmineID: #135324]
			- 20201229@Irena.Vo: Ignore select data by ParentID. Remove logic update LastScannedDate [RedmineID: #145951]
            - 20210510@Aries.Nguyen: Remove insert log zzTracePerformance [Redmine ID: #154792]
            - 20210622@Aries.Nguyen: Update coding convention [Redmine ID: #157203]
		Param's Explanation (filtered by):
            - ip_CategoryIDList: ex: '1,2,3'       
	*/
    DECLARE lv_ScanTime         DATETIME;
    DECLARE lv_LgTotalRecord	INT;
    DECLARE lv_FromID		    BIGINT;
    DECLARE lv_ToID			    BIGINT;

	SET lv_ScanTime = (SELECT MAX(ScanTime) FROM CTS_DataCenter.CTSCustomerClassification_ScanStatus);

    DROP TEMPORARY TABLE IF EXISTS Temp_CustSport;    
	CREATE TEMPORARY TABLE Temp_CustSport(	  
		    CustID			BIGINT UNSIGNED        
        ,   SportGroupID		SMALLINT UNSIGNED        
        ,   PRIMARY KEY	PK_Temp_CustSport_CTSCustID(CustID, SportGroupID)    
    );     
    
    INSERT INTO Temp_CustSport(CustID, SportGroupID)
	SELECT 		tmpTable.CustID
				, tmpTable.SportGroupID
	FROM JSON_TABLE(ip_CustSport,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, SportGroupID 		SMALLINT UNSIGNED	PATH "$.SportGroupId"
		 )) as tmpTable;
    
    UPDATE 		CTS_DataCenter.CTSCustomerClassification_ScanStatus
    SET			LastCustID = (SELECT MAX(CustID) FROM Temp_CustSport)
    WHERE		ScanTime = lv_ScanTime;
END$$
DELIMITER ;