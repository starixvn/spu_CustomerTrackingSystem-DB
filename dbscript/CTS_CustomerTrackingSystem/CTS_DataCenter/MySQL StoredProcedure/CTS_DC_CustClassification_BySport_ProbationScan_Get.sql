/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_BySport_ProbationScan_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE  `CTS_DataCenter`.`CTS_DC_CustClassification_BySport_ProbationScan_Get`(
	IN ip_NoOfRecord 			INT
)
    SQL SECURITY INVOKER 
sp: BEGIN
	/*
		Created:	20220907@Harvey.Nguyen
		Task:		Return the Probation list for scanning
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- [20200923@Irena.Vo][141755]: Enhance SP.

		Param's Explanation (filtered by):
			- CALL CTS_DC_CustClassification_BySport_ProbationScan_Get (100);
	*/
    
    DECLARE lv_CurrentDate 		DATE DEFAULT CURRENT_DATE();
    DECLARE lv_FromLastDay 		DATE DEFAULT DATE_SUB(lv_CurrentDate, INTERVAL 19 DAY); /*Up to 20 Last Day*/
    DECLARE lv_ToLastDay 		DATE DEFAULT DATE_SUB(lv_CurrentDate, INTERVAL 2 DAY); /*Up to 3 Last Day*/
    
	SELECT 		pro.CustID
			,	pro.SportID
            ,	clss.CategoryID
			,	(CASE WHEN pro.CreatedDate <= lv_FromLastDay THEN 1 /*Up to Smart, High Risk, VIP & Normal*/ ELSE 0 /*Up to VIP & Normal*/ END) AS IsProbationLastDay
    FROM		CTS_DataCenter.ProbationAccountMonitor_BySport AS pro
		INNER JOIN CTS_DataCenter.CTSCustomerClassification_BySport AS clss ON pro.CustID = clss.CustID AND pro.SportID = clss.SportID
	WHERE	(pro.LastScannedDate IS NULL OR pro.LastScannedDate < lv_CurrentDate)
			AND (pro.CreatedDate < lv_ToLastDay)
	LIMIT	ip_NoOfRecord;
END$$
DELIMITER ;