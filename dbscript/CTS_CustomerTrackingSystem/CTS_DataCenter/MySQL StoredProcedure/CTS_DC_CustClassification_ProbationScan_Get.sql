/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_ProbationScan_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE  `CTS_DataCenter`.`CTS_DC_CustClassification_ProbationScan_Get`(
	IN ip_NoOfRecord 			INT
)
    SQL SECURITY INVOKER 
sp: BEGIN
	/*
		Created:	20200918@Harvey.Nguyen
		Task:		Return the Probation list for scanning
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- [20200923@Irena.Vo][141755]: Enhance SP.
            - [20201111@Irena.Vo][145028]: Update ScanTime = 20 Last Days
			- 20201214-20201221@Irena.Vo: Ignore Pin category. Declare lv_CurrentDate & Enhance logic SP [RedmineID: #145951]
			- 20210525@Irena.Vo: Change col name PinCustomerCategory: CustID -> CTSCustID [RedmineID: #152965] 
			- 20210611@Irena.Vo: Update schedule scan [RedmineID: #156466]
            - 20210722@Irena.Vo: Refactor SP [RedmineID: #157203]
			- 202230426@Long.Luu: Adjust Probation's period from 20 to 15 [Redmine ID: #187433]
				
		Param's Explanation (filtered by):
			- CALL CTS_DC_CustClassification_ProbationScan_Get (100);
	*/
    DECLARE	CONST_GROUP_NORMAL 	INT DEFAULT 200;
    
    DECLARE lv_CurrentDate 		DATE DEFAULT CURRENT_DATE();
    DECLARE lv_FromLastDay 		DATE DEFAULT DATE_SUB(lv_CurrentDate, INTERVAL 14 DAY); /*Up to 15 Last Day*/
    DECLARE lv_ToLastDay 		DATE DEFAULT DATE_SUB(lv_CurrentDate, INTERVAL 2 DAY); /*Up to 3 Last Day*/
    
	SELECT 		pro.CustID AS CustId
			,	pro.SportGroupID AS SportGroupId
			,	(CASE WHEN pro.CreatedDate <= lv_FromLastDay THEN 1 /*Up to Smart, High Risk, VIP & Normal*/ ELSE 0 /*Up to VIP & Normal*/ END) AS IsProbationLastDay
    FROM		CTS_DataCenter.ProbationAccountMonitor AS pro
		LEFT JOIN CTS_DataCenter.PinCustomerCategory AS pin ON pin.CTSCustID = pro.CTSCustID
	WHERE	pin.CTSCustID IS NULL 
			AND pro.SportGroupID = CONST_GROUP_NORMAL
			AND (pro.LastScannedDate IS NULL OR pro.LastScannedDate < lv_CurrentDate)
			AND (pro.CreatedDate < lv_ToLastDay)
	LIMIT	ip_NoOfRecord;
END$$
DELIMITER ;