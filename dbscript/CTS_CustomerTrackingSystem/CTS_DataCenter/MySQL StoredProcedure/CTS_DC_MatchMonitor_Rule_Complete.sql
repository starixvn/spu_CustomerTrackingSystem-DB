/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Rule_Complete`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Rule_Complete`(
	IN ip_LastTransID INT
)
  SQL SECURITY INVOKER
BEGIN
		/*Created:	20210526@Casey.Huynh
		Task :		Match Monitor Insert trans ticket to Staging table
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20210526@Casey.Huynh: Created [Redmine ID: 152883]
		
		Param's Explanation (filtered by):
		CALL CTS_DataCenter.CTS_DC_MatchMonitor_Staging_Insert(
			'[
				{"TransID":111928688806,"TransDate":"2021-05-17 07:48:52.527","MatchID":43606436,"LiveIndicator":1,"LiveHomeScore":1,"LiveAwayScore":0,"BettypeID":8,"CustID":38290463,"Stake":50}
			]');

		Example:
			
	*/
    /*DECLARE lv_CustList LONGTEXT;
        
	SELECT 	lv_CustList = GROUP_CONCAT(CustID)
    FROM	CTS_DataCenter.MatchMonitorStaging
    WHERE	OriginalGroup = ip_TempGroupID;
    
    CALL CTS_DC_Association_GetGroup(lv_CustList);
    
    UPDATE CTS_DataCenter.MatchMonitorStaging AS mns
		LEFT JOIN Temp_Group AS tmpGp ON mns.CustID =  tmpGp.CustID
	SET	  mns.OriginalGroup = tmpGp.GroupID
		, mns.IsHedging = tmpGp.IsHedging
    WHERE  OriginalGroup = ip_TempGroupID;*/
    
    UPDATE 	CTS_DataCenter.SystemParameter
    SET 	ParameterValue = ip_LastTransID
    WHERE 	ID = 20;
    
END$$
DELIMITER ;
