DELIMITER $$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_GetAssociationByCTSCustID`(IN ip_CTSCustID INT)
BEGIN
	/*
		Created:	20191217@Marcus
		Task :		Get Association (Account/ Device / IP) by CTSCustID
		DB:			CTS_DataCenter
		Original:

		Revisions:
        - 20200213@Terry: Fix bug for total accounts counter
		Param's Explanation (filtered by):
	*/
	DECLARE		totalAccounts			INT		DEFAULT 0;   
	DECLARE		totalDevices			INT		DEFAULT 0;
    DECLARE		totalIPs		    	INT		DEFAULT 0;
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
            
    SELECT	COUNT(1) INTO totalDevices	
	FROM    AssociationByDevice AS ass
	WHERE   ass.CTSCustID = ip_CTSCustID;
	
    SELECT	COUNT(1) INTO totalIPs	
	FROM    AssociationByIP AS ass
	WHERE   ass.CTSCustID = ip_CTSCustID;

	SELECT COUNT(tmp.CTSCustID) INTO totalAccounts FROM (
	SELECT  CTSCustID
	FROM    AssociationByDevice 
	WHERE   DCSDeviceID IN (SELECT DCSDeviceID 
						    FROM   AssociationByDevice 
						    WHERE  CTSCustID = ip_CTSCustID)
					    AND CTSCustID <> ip_CTSCustID
    UNION                         
	SELECT  CTSCustID
	FROM    AssociationByIP 
	WHERE   IPID IN (SELECT IPID 
						    FROM   AssociationByIP 
						    WHERE  CTSCustID = ip_CTSCustID)
					    AND CTSCustID <> ip_CTSCustID) AS tmp;
	
   SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
   
   SELECT	totalAccounts, totalDevices, totalIPs;    
    
END$$
DELIMITER ;
