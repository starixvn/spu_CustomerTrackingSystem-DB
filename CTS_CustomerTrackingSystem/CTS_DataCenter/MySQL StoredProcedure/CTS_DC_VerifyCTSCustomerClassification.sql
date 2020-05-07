DELIMITER $$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_VerifyCTSCustomerClassification`(
	IN ip_CTSCustID				BIGINT UNSIGNED
    ,	IN ip_SubscriberID		INT
	,	IN ip_CategoryID		SMALLINT
	, 	OUT op_ErrorMessage	 	VARCHAR(200)
)
sp: BEGIN
	/*
		Created:	20200507@Terry.Nguyen
		Task :		Verify CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 
		Revisions:			
            
		Param's Explanation:
	*/ 
    DECLARE vr_CategoryName	VARCHAR(100);
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SELECT CategoryName INTO vr_CategoryName 
		FROM CTS_DataCenter.CustomerCategory 
		WHERE CategoryID = ip_CategoryID;

    IF ip_CategoryID = 6 OR ip_CategoryID = 7 THEN 
			IF(EXISTS(SELECT 1 	FROM CTS_DataCenter.CTSCustomerClassification 
								WHERE 		CTSCustID = ip_CTSCustID
								AND 		SubscriberID = ip_SubscriberID
                                AND 		CategoryID IN (3, 5))) THEN
                                
					SET op_ErrorMessage = CONCAT("This account is already have <b> VIP & VVIP </b> in Category List. You are not allow to add <b>", vr_CategoryName, "</b> category.");	
                    LEAVE sp;
			END IF;
	ELSEIF ip_CategoryID = 3 OR ip_CategoryID = 5 THEN
		IF(EXISTS(SELECT 1 	FROM CTS_DataCenter.CTSCustomerClassification 
								WHERE 		CTSCustID = ip_CTSCustID
								AND 		SubscriberID = ip_SubscriberID
                                AND 		CategoryID IN (6, 7))) THEN
                                
					SET op_ErrorMessage = CONCAT("This account is already have <b> Smart Punter & High Risk </b> Punter in Category List. You are not allow to add <b>", vr_CategoryName, "</b> category.");		
                    LEAVE sp;
			END IF;
	END IF;
    
   SET op_ErrorMessage = "";
END$$
DELIMITER ;
