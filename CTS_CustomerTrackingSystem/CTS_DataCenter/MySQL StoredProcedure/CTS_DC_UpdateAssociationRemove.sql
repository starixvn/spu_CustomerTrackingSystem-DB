DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_UpdateAssociationRemove`$$

CREATE PROCEDURE `CTS_DataCenter`.`CTS_DC_UpdateAssociationRemove`(
		IN ip_FromSubscriberID 	INT
    , 	IN ip_FromCTSCustID 	BIGINT
    ,	IN ip_ToSubscriberID 	INT
    , 	IN ip_ToCTSCustID 		BIGINT
    , 	IN ip_Remark 			VARCHAR(500)
    , 	IN ip_CreatedBy 		BIGINT
    
    , 	OUT op_ErrorMessage 	VARCHAR(200)
)
BEGIN
	/*
		Created:	20200416@Long.Luu	
		Task :		Update Association Remove table
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200416@Long.Luu: Created [Redmine ID: #131506]
            
		Param's Explanation:
	*/ 
 
    DECLARE lv_FromSubscriberID 	INT;
	DECLARE lv_FromCTSCustID 		BIGINT;
    DECLARE lv_ToSubscriberID 		INT;
    DECLARE lv_ToCTSCustID 			BIGINT;
 
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;

	IF ip_FromCTSCustID = ip_ToCTSCustID
		THEN
			SET op_ErrorMessage = 'The Source & Target nodes are the same!';
		ELSE
			IF ip_FromCTSCustID > ip_ToCTSCustID
				THEN
					SET 	lv_FromSubscriberID = ip_ToSubscriberID
						,	lv_FromCTSCustID = ip_ToCTSCustID
						,	lv_ToSubscriberID = ip_FromSubscriberID
						,	lv_ToCTSCustID = ip_FromCTSCustID;
				ELSE
					SET 	lv_FromSubscriberID = ip_FromSubscriberID
						,	lv_FromCTSCustID = ip_FromCTSCustID
						,	lv_ToSubscriberID = ip_ToSubscriberID
						,	lv_ToCTSCustID = ip_ToCTSCustID;
			END IF;

			IF EXISTS(SELECT 1 FROM CTS_DataCenter.AssociationRemove WHERE FromCTSCustID = lv_FromCustID AND ToCTSCustID = lv_ToCustID)
				THEN
					DELETE FROM CTS_DataCenter.AssociationRemove
					WHERE FromCTSCustID = lv_FromCustID AND ToCTSCustID = lv_ToCustID;
				ELSE
					SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
			
					INSERT INTO CTS_DataCenter.AssociationRemove(FromSubscriberID, FromCTSCustID, ToSubscriberID, ToCTSCustID, Remark, CreatedDate, CreatedBy)
					VALUES(lv_FromSubscriberID, lv_FromCTSCustID, lv_ToSubscriberID, lv_ToCTSCustID, ip_Remark, CURRENT_TIME(), ip_CreatedBy);
				   
					SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
			END IF;    
    END IF;
END$$	
DELIMITER ;