/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Association_UpdateAssociationRemove`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Association_UpdateAssociationRemove`(OUT op_ErrorMessage varchar(200),IN ip_FromSubscriberID int,IN ip_FromCTSCustID bigint,IN ip_ToSubscriberID int,IN ip_ToCTSCustID bigint,IN ip_Remark varchar(500),IN ip_CreatedBy bigint,IN ip_IsActionRemove bit)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200416@Long.Luu	
		Task :		Update Association Remove table
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200416@Long.Luu: Created [Redmine ID: #131506]
			- 20210121@John.Ngo: Enhance CTS SPs by removing ISSOLATION [Redmine ID: 148723]
            
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

			IF (ip_IsActionRemove = 1)
				THEN
					DELETE FROM CTS_DataCenter.AssociationRemove
					WHERE FromCTSCustID = lv_FromCTSCustID AND ToCTSCustID = lv_ToCTSCustID;
                    
                    INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
					VALUES(9, 'CTS_DC_Association_UpdateAssociationRemove', CONCAT('Delete Association Remove: ip_FromCTSCustID_', lv_FromCTSCustID, ';ip_ToCTSCustID_', lv_ToCTSCustID,')'), CURRENT_TIME(), ip_CreatedBy);    
                ELSE
					
					INSERT INTO CTS_DataCenter.AssociationRemove(FromSubscriberID, FromCTSCustID, ToSubscriberID, ToCTSCustID, Remark, CreatedDate, CreatedBy)
					VALUES(lv_FromSubscriberID, lv_FromCTSCustID, lv_ToSubscriberID, lv_ToCTSCustID, ip_Remark, CURRENT_TIME(), ip_CreatedBy);
				   
					INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
					VALUES(8, 'CTS_DC_Association_UpdateAssociationRemove', CONCAT('Insert Association Remove: ip_FromCTSCustID_', lv_FromCTSCustID, ';ip_ToCTSCustID_', lv_ToCTSCustID,')'), CURRENT_TIME(), ip_CreatedBy);

			END IF;
    END IF;
END$$

DELIMITER ;