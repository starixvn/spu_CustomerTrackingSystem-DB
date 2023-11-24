/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Identity_Evolution_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Identity_Evolution_Insert`(
    IN ip_TransJson	LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20231124@Jonathan.Doan
	    Task : Evolution Insert
	    DB: DCS_DataCenter
	    Original:
		 
	    Revisions:
			- 20231123@Jonathan.Doan: Integrate FPSjs Phrase 2 [Redmine: 196656]
	    Param's Explanation (filtered by):
        
        Example:
			CALL DCS_DC_Identity_Evolution_Insert('[{"TransID":10,"RawFingerPrintID":10,"RecoverFingerPrintID":1}]');
	*/
    
	DROP TEMPORARY TABLE IF EXISTS Temp_InputTrans;    
	CREATE TEMPORARY TABLE Temp_InputTrans(
			TransID						BIGINT UNSIGNED PRIMARY KEY
        ,	RawFingerPrintID			BIGINT UNSIGNED
        ,	RecoverRawFingerPrintID		BIGINT UNSIGNED
	);
    
	INSERT INTO Temp_InputTrans(TransID, RawFingerPrintID, RecoverRawFingerPrintID)
	SELECT	tmp.TransID
		,	tmp.RawFingerPrintID
		,	tmp.RecoverFingerPrintID
	FROM	JSON_TABLE(
			ip_TransJson,
			 "$[*]" COLUMNS(
						TransID					BIGINT UNSIGNED			PATH "$.TransID",
						RawFingerPrintID		BIGINT UNSIGNED			PATH "$.RawFingerPrintID",
						RecoverFingerPrintID	BIGINT UNSIGNED			PATH "$.RecoverFingerPrintID"
				)
		   ) AS tmp;
END$$

DELIMITER ;
