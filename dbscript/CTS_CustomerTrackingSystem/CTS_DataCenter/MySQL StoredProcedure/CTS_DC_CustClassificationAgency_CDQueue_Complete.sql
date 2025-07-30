/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassificationAgency_CDQueue_Complete`;
DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassificationAgency_CDQueue_Complete`(		
		IN ip_LastID BIGINT
)
SQL SECURITY INVOKER
BEGIN
	/*
		Creator:	20250725@Winfred.Pham
		Task:	 	Get Agent cust List and Clear Customer Considerable Danger Queue    
		Server:  	CTSMain
		DBName:		CTS_DataCenter

		Revisions: 
				- 20250725@Winfred.Pham: 	Created [Redmine ID: #219679]
                
		Param's Explanation :
        
		Example:
			CALL CTS_DC_CustClassificationAgency_CDQueue_Complete(@op_LastID:=100);
	*/

	DECLARE lv_MaxScanQueueID	BIGINT UNSIGNED DEFAULT 0;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_AgentComplete;
    CREATE TEMPORARY TABLE Temp_AgentComplete(
			ID 			BIGINT 
		,	CustID		BIGINT
		,	ScanType	TINYINT 
    ); 

    SELECT sys.ParameterValue
    INTO lv_MaxScanQueueID
    FROM CTS_DataCenter.SystemParameter AS sys
    WHERE ParameterID = 192;  

	INSERT INTO Temp_AgentComplete (ID, CustID, ScanType)	
	SELECT ccdq.ID, ccdq.CustID, ccdq.ScanType
	FROM CTS_DataCenter.CustomerConsiderableDangerQueue AS ccdq
	WHERE ccdq.ID <= ip_LastID   
    UNION
	SELECT ccdq.ID, ccdq.CustID, ccdq.ScanType 
	FROM CTS_DataCenter.CustomerConsiderableDangerQueue AS ccdq
	WHERE ccdq.ID > ip_LastID AND ccdq.ID <= lv_MaxScanQueueID AND
	EXISTS (SELECT 1 FROM CTS_DataCenter.CustomerConsiderableDangerQueue AS cls WHERE  ccdq.ID <= ip_LastID 
    AND cls.CustID = ccdq.CustID AND cls.ScanType = ccdq.ScanType);   

	DELETE ccdq
	FROM CTS_DataCenter.CustomerConsiderableDangerQueue AS ccdq
	WHERE  EXISTS (SELECT 1 FROM Temp_AgentComplete AS cln WHERE cln.ID = ccdq.ID);

END$$
DELIMITER ;