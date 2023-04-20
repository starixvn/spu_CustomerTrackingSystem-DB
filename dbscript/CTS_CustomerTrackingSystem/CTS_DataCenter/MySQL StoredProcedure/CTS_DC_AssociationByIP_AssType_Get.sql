/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_AssociationByIP_AssType_Get`;

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
			- 20230421@Casey.Huynh: Created [Redmine ID: #185783]

		Param's Explanation (filtered by): 
        
        Example:
			CALL CTS_DC_AssociationByIP_AssType_Get(@ip_CustID:=55013011);
	*/   

    SELECT	ap.AssType		
    FROM CTS_DataCenter.AssociationByIP AS ap
    WHERE ap.FromCustID = ip_CustID
    UNION
    SELECT	ap.AssType		
    FROM CTS_DataCenter.AssociationByIP AS ap
    WHERE ap.ToCustID = ip_CustID;
    
END$$

DELIMITER ;
