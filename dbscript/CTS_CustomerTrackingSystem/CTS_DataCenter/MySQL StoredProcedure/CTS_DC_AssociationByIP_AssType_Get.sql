
DROP PROCEDURE IF EXISTS `CTS_DC_AssociationByIP_AssType_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociationByIP_AssType_Get`(
		IN 	ip_CustID	BIGINT    
)
    SQL SECURITY INVOKER
BEGIN  
	/*  
		Created:	20230420@Casey.Huynh
		Task:		Get Association IP Type Bu CustID
		DB:			CTS_DataCenter
        
		Revisions:
			- 20230420@Casey.Huynh: Created [Redmine ID: #185783]

		Param's Explanation (filtered by): 
        
        Example:
			CALL CTS_DC_AssociationByIP_AssType_Get(@ip_CustID:=55013011);
	*/   

    SELECT	ai.AssType		
    FROM CTS_DataCenter.AssociationByIP AS ai
    WHERE ai.FromCustID = ip_CustID
    UNION
    SELECT	ai.AssType		
    FROM CTS_DataCenter.AssociationByIP AS ai
    WHERE ai.ToCustID = ip_CustID;
    
END$$

DELIMITER ;
