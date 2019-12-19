DELIMITER $$
USE CTS_DataCenter$$
DROP PROCEDURE IF EXISTS CTS_DC_GetAssociationByCTSCustID $$

CREATE PROCEDURE CTS_DC_GetAssociationByCTSCustID(IN ip_CTSCustID INT)
BEGIN
	/*
		Created:	20191217@Marcus
		Task :		Get Association (Account/ Device / IP) by CTSCustID
		DB:			CTS_DataCenter
		Original:

		Revisions:
		Param's Explanation (filtered by):
	*/
	
    DECLARE		totalAccountByDevices		INT		DEFAULT 0;
    DECLARE		totalAccountByIPs		INT		DEFAULT 0;
	DECLARE		totalDevices		INT		DEFAULT 0;
    DECLARE		totalIPs		    INT		DEFAULT 0;
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	
    SELECT	COUNT(1) INTO totalDevices	
	FROM    AssociationByDevice AS ass
	WHERE   ass.CTSCustID = ip_CTSCustID;
	
    SELECT	COUNT(1) INTO totalIPs	
	FROM    AssociationByIP AS ass
	WHERE   ass.CTSCustID = ip_CTSCustID;
    
	SELECT  COUNT(1) INTO totalAccountByDevices
	FROM    AssociationByDevice AS ass 
	WHERE   DCSDeviceID IN (SELECT DCSDeviceID 
						    FROM   AssociationByDevice 
						    WHERE  CTSCustID = ip_CTSCustID)
					    AND ass.CTSCustID <> ip_CTSCustID;
                        
	SELECT  COUNT(1) INTO totalAccountByIPs
	FROM    AssociationByIP AS ass 
	WHERE   IPID IN (SELECT IPID 
						    FROM   AssociationByIP 
						    WHERE  CTSCustID = ip_CTSCustID)
					    AND ass.CTSCustID <> ip_CTSCustID;
	
   SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
   SELECT	(totalAccountByDevices + totalAccountByIPs) as totalAccounts, totalDevices, totalIPs; 
    
END$$
DELIMITER ;