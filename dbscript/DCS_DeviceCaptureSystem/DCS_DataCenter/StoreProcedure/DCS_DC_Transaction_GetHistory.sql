/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transaction_GetHistory`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transaction_GetHistory`(
		IN	ip_DateRange	INT
    ,	IN	ip_CTSCustId 	BIGINT    
    ,	IN	ip_Skip			INT
    ,	IN	ip_Take			INT
    ,	OUT	op_TotalItem	INT
    )
    SQL SECURITY INVOKER
proc_label: BEGIN
	/*
		Created:	20200311@Terry
		Task:		Get history transaction by date [Redmine ID: 130074]
		DB:			DCS_DataCenter
		Original:

		Revisions:
			- 20200518@lex.khuat: Update robot description from Green to Human [Redmine ID: #133934]
			- 20210121@John.Ngo: Enhance CTS SPs by removing ISSOLATION [Redmine ID: 148723]
			- 20210629@Casey.Huynh: Enhance SP and Return Flagged Value (Web will show type of robot) [Redmine ID: 157085]
            - 20230406@Casey.Huynh: Show trans cross subscriber [Redmine ID: 186086]
            - 20230512@Jonas.Huynh: BOTD transactions [Redmine ID: 185792]
            
		Param's Explanation (filtered by):
	*/ 
	DECLARE lv_FromRow INT;
    DECLARE lv_FromDate DATETIME;
    DECLARE lv_ToDate DATETIME;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Account;      
    CREATE TEMPORARY TABLE Temp_Account
	(
			AccountID	 	BIGINT(20)      
    );	
    
    INSERT INTO Temp_Account 
	SELECT 	cusAcc.AccountID 
	FROM	CTS_DataCenter.CustDCSAccount cusAcc 
	WHERE 	cusAcc.CTSCustID = ip_CTSCustId;
		
    SET lv_ToDate = CURRENT_DATE();
    SET lv_FromDate = CASE 
						WHEN ip_DateRange = 1 THEN DATE_ADD(lv_ToDate, INTERVAL -1 DAY)
                        WHEN ip_DateRange = 14 THEN DATE_ADD(lv_ToDate, INTERVAL -14 DAY)
                        ELSE lv_ToDate
					END;                
	
    SET @TotalRow = 0;
	
    SELECT 	tmp.TransID			AS TransID
		,	tmp.TransTime		AS TransTime
		,	tmp.FirstDeviceCode	AS FirstDeviceCode
		,	tmp.IP				AS IP
		,	tmp.IPID			AS IPID
		,	tmp.ItemName		AS Flagged
		,	tmp.Action			AS Action
		,	tmp.ActionResult	AS ActionResult
		,	tmp.OS				AS OS
		,	tmp.Browser			AS Browser
		,	tmp.URLDetails		AS URLDetails
	FROM	(
			SELECT 	@TotalRow := @TotalRow + 1
				,	trs.TransID
				,	trs.TransTime
				,	trs.FirstDeviceCode
				,	trs.IP
				,	trs.IPID
				,	s.ItemName
				,	ar.Action
				,	ar.ActionResult
				,	uag.OS
				,	uag.Browser
				,	ur.URLDetails
			FROM	DCS_DataCenter.Transaction07 trs 
				LEFT JOIN DCS_DataCenter.UserAgent AS uag ON trs.UserAgentKey = uag.UserAgentKey
				LEFT JOIN DCS_DataCenter.ActionResult AS ar ON trs.ActionResultID = ar.ActionResultID
				LEFT JOIN DCS_DataCenter.URL AS ur ON trs.URLID = ur.URLID
                LEFT JOIN DCS_DataCenter.StaticList AS s ON s.ListID = 1 AND s.ItemID = trs.Flagged AND s.Status = 1
			WHERE trs.AccountID IN (SELECT AccountID FROM Temp_Account)
				AND trs.CreatedDate BETWEEN lv_FromDate AND lv_ToDate
			) AS tmp
		ORDER BY TransTime DESC            
		LIMIT ip_Skip, ip_Take;
    
    SET op_TotalItem = @TotalRow;
    
END$$

DELIMITER ;
