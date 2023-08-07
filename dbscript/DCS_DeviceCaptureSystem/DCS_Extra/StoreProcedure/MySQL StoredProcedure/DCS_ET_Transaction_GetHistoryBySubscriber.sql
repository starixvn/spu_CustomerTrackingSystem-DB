/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_ET_Transaction_GetHistoryBySubscriber`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_ET_Transaction_GetHistoryBySubscriber`(
		IN	ip_SubscriberID	INT	
    ,	IN	ip_FromDate		DATETIME
    ,	IN	ip_ToDate 		DATETIME
    ,	IN  ip_LoginName	VARCHAR(50)
    ,	IN	ip_IsPartial	BOOLEAN
    ,	IN	ip_Skip			INT
    ,	IN	ip_Take			INT
    ,	OUT	op_TotalItem	INT
    )
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20230720@Casey.Huynh
		Task :		Get Association Account List
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20230720@Casey.Huynh: Created [Redmine ID: 189873]
			
		Param's Explanation (filtered by):

		Example:
			CALL DCS_ET_Transaction_GetHistoryBySubscriber(@ip_SubscriberID:=8000001,@ip_FromDate:='2023-04-01',@ip_ip_ToDate:='2023-07-15',@ip_LoginName:='DenVau', @ip_IsPartial:= 0, @ip_Skip:=0, @ip_Take:=2000, @op_TotalItem); SELECT @op_TotalItem;    
			CALL DCS_ET_Transaction_GetHistoryBySubscriber(@ip_SubscriberID:=8000001,@ip_FromDate:='2023-04-01',@ip_ip_ToDate:='2023-07-15',@ip_LoginName:='Den', @ip_IsPartial:= 1, @ip_Skip:=0, @ip_Take:=2000, @op_TotalItem); SELECT @op_TotalItem;    
			CALL DCS_ET_Transaction_GetHistoryBySubscriber(@ip_SubscriberID:=8000001,@ip_FromDate:='2023-04-01',@ip_ip_ToDate:='2023-07-15',@ip_LoginName:=NULL, @ip_IsPartial:= 1, @ip_Skip:=0, @ip_Take:=2000, @op_TotalItem); SELECT @op_TotalItem;    

   */
	
	DROP TEMPORARY TABLE IF EXISTS Temp_Account;
	CREATE TEMPORARY TABLE Temp_Account(
			AccountID	BIGINT UNSIGNED PRIMARY KEY
		,   LoginName	VARCHAR(50)
	);
    
	#================================================================
	DROP TEMPORARY TABLE IF EXISTS Temp_Flagged;
	CREATE TEMPORARY TABLE Temp_Flagged(
			Flagged 	SMALLINT PRIMARY KEY
        ,	DisplayName VARCHAR(200)
	);
    
    INSERT INTO Temp_Flagged(Flagged, DisplayName)
    SELECT	stl.ItemID
		,	stl.ItemName
    FROM DCS_Extra.StaticList AS stl
    WHERE stl.ListID = 1;
    
	#================================================================================
	# GET SEARCH ACCOUNT
	IF(ip_IsPartial = 1) THEN #SEARCH PARTIAL
		#========SEARCH BY USERNAME=====================
		INSERT INTO Temp_Account (AccountID, LoginName)
		SELECT	acc.AccountID
			,	acc.LoginName
		FROM DCS_Extra.Account AS acc
		WHERE acc.SubscriberID = ip_SubscriberID AND acc.LoginName LIKE CONCAT(ip_LoginName,'%');
        
	ELSE #SEARCH EXACTLY
		#========SEARCH BY USERNAME=====================
		INSERT INTO Temp_Account (AccountID, LoginName)
		SELECT	acc.AccountID
			,	acc.LoginName
		FROM DCS_Extra.Account AS acc
		WHERE acc.SubscriberID = ip_SubscriberID AND acc.LoginName = ip_LoginName;
	END IF;
                		
	IF ip_LoginName IS NOT NULL THEN 
			SET @TotalRow = 0;
			SELECT 	tmp.TransID			AS TransID
				,	tmp.AccountID		AS AccountID
                ,	ip_SubscriberID		AS SubscriberID
				,	tmp.LoginName		AS LoginName
				,	tmp.TransTime		AS TransTime
				,	tmp.FirstDeviceCode	AS FirstDeviceCode
				,	tmp.Action			AS Action
				,	tmp.ActionResult	AS ActionResult
				,	tmp.OS				AS OS
				,	tmp.Browser			AS Browser
				,	tmp.URLDetails		AS URLDetails
				,	tmp.IP				AS IP
                ,	tmp.DisplayName		AS RobotTracking
			FROM	(
					SELECT 	@TotalRow := @TotalRow + 1
						,	trs.TransTime
                        ,	tmpAcc.AccountID
                        ,	tmpAcc.LoginName	AS LoginName
						,	trs.TransID
						,	trs.FirstDeviceCode
						,	ar.Action
						,	ar.ActionResult
						,	uag.OS
						,	uag.Browser
						,	ur.URLDetails
						,	trs.IP
                        ,	tmpFg.DisplayName
					FROM	DCS_Extra.Transaction07 trs
                    	INNER JOIN  Temp_Account AS tmpAcc ON trs.AccountID = tmpAcc.AccountID
						LEFT JOIN DCS_Extra.UserAgent AS uag ON trs.UserAgentKey = uag.UserAgentKey
						LEFT JOIN DCS_Extra.ActionResult AS ar ON trs.ActionResultID = ar.ActionResultID
						LEFT JOIN DCS_Extra.URL AS ur ON trs.URLID = ur.URLID
                        LEFT JOIN Temp_Flagged AS tmpFg ON trs.Flagged = tmpFg.Flagged
					WHERE trs.TransTime BETWEEN ip_FromDate AND ip_ToDate
					) AS tmp
				ORDER BY TransTime DESC            
				LIMIT ip_Skip, ip_Take;
			
			SET op_TotalItem = @TotalRow;
	ELSE # Transaction History Report    
		SET @TotalRow = 0;
		SELECT 	tmp.TransTime		AS TransTime
			,	tmp.AccountID		AS AccountID
             ,	ip_SubscriberID		AS SubscriberID
			,	tmp.TransID			AS TransID
			,	tmp.LoginName		AS LoginName
			,	tmp.FirstDeviceCode	AS FirstDeviceCode
			,	tmp.Action			AS Action
			,	tmp.ActionResult	AS ActionResult
			,	tmp.OS				AS OS
			,	tmp.Browser			AS Browser
			,	tmp.URLDetails		AS URLDetails
			,	tmp.IP				AS IP
            ,	tmp.DisplayName		AS RobotTracking
		FROM	(
				SELECT 	@TotalRow := @TotalRow + 1
					,	trs.TransTime                   
                    ,	acc.AccountID
					,	trs.TransID
					,	acc.LoginName
					,	trs.FirstDeviceCode
					,	ar.Action
					,	ar.ActionResult
					,	uag.OS
					,	uag.Browser
					,	ur.URLDetails
					,	trs.IP
                    ,	tmpFg.DisplayName
				FROM	DCS_Extra.Transaction07 AS trs 
					INNER JOIN DCS_Extra.Account AS acc ON acc.AccountID = trs.AccountID
					LEFT JOIN DCS_Extra.UserAgent AS uag ON trs.UserAgentKey = uag.UserAgentKey
					LEFT JOIN DCS_Extra.ActionResult AS ar ON trs.ActionResultID = ar.ActionResultID
					LEFT JOIN DCS_Extra.URL AS ur ON trs.URLID = ur.URLID
                    LEFT JOIN Temp_Flagged AS tmpFg ON trs.Flagged = tmpFg.Flagged
				WHERE trs.TransTime BETWEEN ip_FromDate AND ip_ToDate
					AND trs.SubscriberID = ip_SubscriberID
				) AS tmp
			ORDER BY TransTime DESC            
			LIMIT ip_Skip, ip_Take;
			
			SET op_TotalItem = @TotalRow;
	END IF;
END$$

DELIMITER ;
