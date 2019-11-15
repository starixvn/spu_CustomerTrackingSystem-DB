DELIMITER $$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_GetLatestUpdatedDate_IPRange`()
BEGIN
	/*
		Created: 20190620@Terry
		Task : Update IPTableLog
		DB: FPS_DataCenter
		Original:

		Revisions:
		Param's Explanation (filtered by):
	*/
    
	SELECT	il.UpdatedDate
	FROM	CTS_DataCenter.IPTableLog AS il
	WHERE	il.IsNewUpdate = 1
    ORDER BY	il.UpdatedDate  DESC
	LIMIT	1;
       
	END$$
DELIMITER ;
