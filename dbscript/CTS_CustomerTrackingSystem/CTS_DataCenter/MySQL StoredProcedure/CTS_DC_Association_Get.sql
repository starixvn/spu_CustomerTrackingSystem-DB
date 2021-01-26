/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Association_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Association_Get`(IN ip_CTSCustID bigint)
    SQL SECURITY INVOKER
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
		- 20210121@John.Ngo: Enhance CTS SPs by removing ISSOLATION [Redmine ID: 148723]
		
		Param's Explanation (filtered by):
	*/
	
	DECLARE		totalAccounts			INT		DEFAULT 0;   
	DECLARE		totalDevices			INT		DEFAULT 0;
    DECLARE		totalIPs		    	INT		DEFAULT 0;

	DROP TEMPORARY TABLE IF EXISTS tmpAffectedAss;
    CREATE TEMPORARY TABLE tmpAffectedAss(
		CTSCustID bigint UNSIGNED
	);
    
    DROP TEMPORARY TABLE IF EXISTS tmpAffectedDev;
    CREATE TEMPORARY TABLE tmpAffectedDev(
		DCSDeviceID bigint
	);
 
    DROP TEMPORARY TABLE IF EXISTS tmpAffectedIP;
    CREATE TEMPORARY TABLE tmpAffectedIP(
		IPID decimal(50,0)
	);
 
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
   
	SELECT	totalAccounts, totalDevices, totalIPs;    
    
END$$
DELIMITER ;
