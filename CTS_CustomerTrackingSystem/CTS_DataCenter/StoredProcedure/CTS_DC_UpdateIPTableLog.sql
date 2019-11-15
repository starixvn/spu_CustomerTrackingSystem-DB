DELIMITER $$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_UpdateIPTableLog`(IN ip_UpdatedDate DATETIME)
BEGIN
	/*
		Created: 20190620@Terry
		Task : Update IPTableLog
		DB: FPS_DataCenter
		Original:

		Revisions:
		Param's Explanation (filtered by):
	*/
    UPDATE 	CTS_DataCenter.IPTableLog
	SET		IsNewUpdate = 0
	WHERE	IsNewUpdate = 1;
    
    INSERT INTO CTS_DataCenter.IPTableLog(UpdatedDate, IsNewUpdate)
	VALUES(	ip_UpdatedDate
			, 1
			);   
            
	END$$
DELIMITER ;
