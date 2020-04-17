DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_AddManualAssociation`$$

CREATE PROCEDURE `CTS_DataCenter`.`CTS_DC_AddManualAssociation`(
		IN ip_FromSubscriberID 	INT
    , 	IN ip_FromCustID 		BIGINT
    ,	IN ip_ToSubscriberID 	INT
    , 	IN ip_ToCustID 			BIGINT
    , 	IN ip_Remark 			VARCHAR(500)
    , 	IN ip_CreatedBy 		BIGINT
    
    , 	OUT op_ErrorMessage 	VARCHAR(200)
)
BEGIN
	/*
		Created:	20200416@Long.Luu	
		Task :		Add Association Manually
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200416@Long.Luu: Created [Redmine ID: #131506]
            
		Param's Explanation:
	*/ 
 
    DECLARE lv_FromSubscriberID 	INT;
	DECLARE lv_FromCustID 			BIGINT;
    DECLARE lv_ToSubscriberID 		INT;
    DECLARE lv_ToCustID 			BIGINT;
 
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;

	IF ip_FromCustID > ip_ToCustID
		THEN
			SET 	lv_FromSubscriberID = ip_ToSubscriberID
				,	lv_FromCustID = ip_ToCustID
                ,	lv_ToSubscriberID = ip_FromSubscriberID
                ,	lv_ToCustID = ip_FromCustID;
        ELSE
			SET 	lv_FromSubscriberID = ip_FromSubscriberID
				,	lv_FromCustID = ip_FromCustID
                ,	lv_ToSubscriberID = ip_ToSubscriberID
                ,	lv_ToCustID = ip_ToCustID;
	END IF;

    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
    
	INSERT INTO CTS_DataCenter.AssociationByManual(FromSubscriberID, FromCustID, ToSubscriberID, ToCustID, Remark, CreatedDate, CreatedBy)
	VALUES(lv_FromSubscriberID, lv_FromCustID, lv_ToSubscriberID, lv_ToCustID, ip_Remark, CURRENT_TIME(), ip_CreatedBy);
   
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$	
DELIMITER ;