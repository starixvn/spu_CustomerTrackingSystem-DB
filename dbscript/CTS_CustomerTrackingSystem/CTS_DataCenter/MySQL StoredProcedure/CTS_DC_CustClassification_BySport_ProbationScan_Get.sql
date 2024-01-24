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
			- 202230426@Long.Luu: Adjust Probation's period from 20 to 15 [Redmine ID: #187433]
            - 20230707@Jonas.Huynh: Normal Renovation [Redmine ID: #189875]
            - 20240124@Jonas.Huynh: Exclude inactive customer within 30days [Redmine ID: #199632]
            
		Param's Explanation (filtered by):
			- CALL CTS_DC_CustClassification_BySport_ProbationScan_Get (100);
	*/
    
    DECLARE lv_CurrentDate 		DATE DEFAULT CURRENT_DATE();
    DECLARE lv_ToLastDay 		DATE DEFAULT DATE_SUB(lv_CurrentDate, INTERVAL 2 DAY); /*Up to 3 Last Day*/
    DECLARE lv_From30Date 		DATE DEFAULT DATE_SUB(lv_CurrentDate, INTERVAL 29 DAY);
        
	SELECT 		pro.CustID 	AS CustId
			,	pro.SportID AS SportGroup
    FROM		CTS_DataCenter.ProbationAccountMonitor_BySport AS pro
	WHERE	(pro.LastScannedDate IS NULL OR pro.LastScannedDate < lv_CurrentDate)
			AND (pro.CreatedDate < lv_ToLastDay) -- and pro.CustID = -1
            AND	EXISTS (SELECT 1
						FROM CTS_Archive.CTSCustomerAssociationStatus AS arc
                        WHERE arc.CTSCustID = pro.CTSCustID AND arc.LastTicketDate >= lv_From30Date)
	LIMIT	ip_NoOfRecord;
END$$
DELIMITER ;