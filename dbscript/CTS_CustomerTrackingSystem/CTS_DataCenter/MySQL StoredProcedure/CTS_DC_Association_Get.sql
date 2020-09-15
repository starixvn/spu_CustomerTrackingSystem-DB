DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS CTS_DC_Association_Get $$

CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_Association_Get`(IN ip_CTSCustID BIGINT)
BEGIN
	/*
		Created:	20191217@Marcus
		Task :		Get Association (Account/ Device / IP) by CTSCustID
		DB:			CTS_DataCenter
		Original:

		Revisions:
        - 20200213@Terry: Fix bug for total accounts counter
		- 20200226@Lex: Enhance performance
		- 20200228@Lex: Exclude IP from counter
		- 20200302@Lex: Include IP from counter again
		
		Param's Explanation (filtered by):
	*/
	
	DECLARE		totalAccounts			INT		DEFAULT 0;   
	DECLARE		totalDevices			INT		DEFAULT 0;
    DECLARE		totalIPs		    	INT		DEFAULT 0;

	DROP TABLE IF EXISTS tmpAffectedAss;
    CREATE TEMPORARY TABLE tmpAffectedAss(
		CTSCustID bigint UNSIGNED
	);
    
    DROP TABLE IF EXISTS tmpAffectedDev;
    CREATE TEMPORARY TABLE tmpAffectedDev(
		DCSDeviceID bigint
	);
 
    DROP TABLE IF EXISTS tmpAffectedIP;
    CREATE TEMPORARY TABLE tmpAffectedIP(
		IPID decimal(50,0)
	);
 
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
	# Get devices list for root
	INSERT INTO tmpAffectedDev(DCSDeviceID)
	SELECT DCSDeviceID
	FROM   CTS_DataCenter.AssociationByDevice
	WHERE  CTSCustID = ip_CTSCustID;
    
	# Get ipid list for root
	INSERT INTO tmpAffectedIP(IPID)
	SELECT IPID
	FROM   CTS_DataCenter.AssociationByIP
    WHERE  CTSCustID = ip_CTSCustID;

	# Get direct associations account with devices & ipid list
	INSERT INTO tmpAffectedAss(CTSCustID)
    SELECT	ad.CTSCustID
	FROM	CTS_DataCenter.AssociationByDevice AS ad
    INNER JOIN tmpAffectedDev AS dv ON ad.DCSDeviceID = dv.DCSDeviceID
    WHERE	ad.CTSCustID <> ip_CTSCustID;

	INSERT INTO tmpAffectedAss(CTSCustID)
    SELECT	aip.CTSCustID
	FROM	CTS_DataCenter.AssociationByIP AS aip
    INNER JOIN tmpAffectedIP AS ip ON aip.IPID = ip.IPID
    WHERE	aip.CTSCustID <> ip_CTSCustID;
    
    SELECT COUNT(1) INTO totalDevices FROM tmpAffectedDev;
    SELECT COUNT(1) INTO totalIPs	 FROM tmpAffectedIP;
    SELECT COUNT(DISTINCT CTSCustID) INTO totalAccounts FROM tmpAffectedAss;
	
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
   
	SELECT	totalAccounts, totalDevices, totalIPs;    
    
END$$
DELIMITER ;
