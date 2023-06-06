/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transaction_GetHistoryBySubscriber`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transaction_GetHistoryBySubscriber`(
		IN	ip_SubscriberID	INT	
    ,	IN	ip_FromDate		DATETIME
    ,	IN	ip_ToDate 		DATETIME
    ,	IN	ip_CTSCustID	BIGINT UNSIGNED
    ,	IN  ip_UserName		VARCHAR(50)
    ,	IN	ip_IsPartial	BOOLEAN
    ,	IN	ip_Skip			INT
    ,	IN	ip_Take			INT
    ,	OUT	op_TotalItem	INT
    )
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20230601@Casey.Huynh
		Task :		Get Association Account List
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20230601@Casey.Huynh: Created [Redmine ID: 185787]
			
		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_DC_Transaction_GetHistoryBySubscriber(@ip_SubscriberID:=6,@ip_FromDate:='2023-01-01',@ip_ip_ToDate:='2023-01-15'
            ,@ip_CTSCustID:=null,@ip_UserName:=null,@ip_IsPartial:=null,@ip_Skip:=0, @ip_Take:=2000, @op_TotalItem); SELECT @op_TotalItem;
			CALL DCS_DC_Transaction_GetHistoryBySubscriber(@ip_SubscriberID:=6,@ip_FromDate:='2023-01-01',@ip_ip_ToDate:='2023-01-15',@ip_CTSCustID:=5560,@ip_UserName:=null,@ip_IsPartial:=null,@ip_Skip:=0, @ip_Take:=2000, @op_TotalItem); SELECT @op_TotalItem;    
    */

	DROP TEMPORARY TABLE IF EXISTS Temp_Account;
	CREATE TEMPORARY TABLE Temp_Account(
		AccountID INT PRIMARY KEY
	);
    
    IF (ip_CTSCustID IS NOT NULL) THEN #Account Details Page
    
		INSERT INTO Temp_Account(AccountID)
		SELECT	cda.AccountID
		FROM	CTS_DataCenter.CustDCSAccount AS cda
		WHERE	cda.CTSCustID = ip_CTSCustID
			AND cda.SubscriberID = ip_SubscriberID;
            
	ELSE # Transaction History Report
		# GET SEARCH ACCOUNT
        #=============GET CUSTOMER BY SEARCH====================================
		DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
		CREATE TEMPORARY TABLE Temp_Customer(
				CTSCustID		BIGINT UNSIGNED PRIMARY KEY
		);
		
		DROP TEMPORARY TABLE IF EXISTS Temp_UserName;
		CREATE TEMPORARY TABLE Temp_UserName(
				UserName		VARCHAR(50)  PRIMARY KEY        
		);

		#============================================
        IF ip_UserName IS NOT NULL THEN			
			SET @sql = CONCAT("INSERT INTO Temp_UserName (UserName) VALUES ('", REPLACE(ip_UserName, ",", "'),('"),"');");
			PREPARE stmt1 FROM @sql;
			EXECUTE stmt1;
		END IF;	
        
        IF(ip_IsPartial = 1) THEN #SEARCH PARTIAL
			#========SEARCH BY USERNAME=====================
			INSERT INTO Temp_Customer (CTSCustID)
			SELECT	cus.CTSCustID
			FROM CTS_DataCenter.CTSCustomer AS cus
				INNER JOIN Temp_UserName AS tmp ON  cus.SubscriberID = ip_SubscriberID AND cus.UserName LIKE CONCAT(tmp.UserName,'%') AND cus.IsInternal = 0 AND cus.LastLoginTime IS NOT NULL;
				
			#========SEARCH BY USERNAME2=====================
			INSERT IGNORE INTO Temp_Customer (CTSCustID)
			SELECT	cus.CTSCustID
			FROM CTS_DataCenter.CTSCustomer AS cus
				INNER JOIN Temp_UserName AS tmp ON cus.SubscriberID = ip_SubscriberID AND cus.UserName2 LIKE CONCAT(tmp.UserName,'%') AND cus.IsInternal = 0 AND cus.LastLoginTime IS NOT NULL;
		ELSE #SEARCH EXACTLY
			#========SEARCH BY USERNAME=====================
			INSERT INTO Temp_Customer (CTSCustID)
			SELECT	cus.CTSCustID
			FROM CTS_DataCenter.CTSCustomer AS cus
				INNER JOIN Temp_UserName AS tmp ON  cus.SubscriberID = ip_SubscriberID AND cus.UserName = tmp.UserName AND cus.IsInternal = 0 AND cus.LastLoginTime IS NOT NULL;
				
			#========SEARCH BY USERNAME2=====================
			INSERT IGNORE INTO Temp_Customer (CTSCustID)
			SELECT	cus.CTSCustID
			FROM CTS_DataCenter.CTSCustomer AS cus
				INNER JOIN Temp_UserName AS tmp ON cus.SubscriberID = ip_SubscriberID AND cus.RegisterName =  tmp.UserName AND cus.IsInternal = 0 AND cus.LastLoginTime IS NOT NULL;
        END IF;
        
		INSERT INTO Temp_Account(AccountID)
		SELECT	cda.AccountID
		FROM	CTS_DataCenter.CustDCSAccount AS cda
			INNER JOIN Temp_Customer AS tmp ON cda.CTSCustID = tmp.CTSCustID
		WHERE	cda.SubscriberID = ip_SubscriberID;
        
    END IF;
		
	IF EXISTS(SELECT 1 FROM Temp_Account LIMIT 1) AND (ip_CTSCustID IS NOT NULL OR ip_UserNameList IS NOT NULL) THEN 
			SET @TotalRow = 0;
			SELECT 	tmp.TransID			AS TransID
				,	tmp.TransTime		AS TransTime
				,	tmp.FirstDeviceCode	AS FirstDeviceCode
				,	tmp.Action			AS Action
				,	tmp.ActionResult	AS ActionResult
				,	tmp.OS				AS OS
				,	tmp.Browser			AS Browser
				,	tmp.URLDetails		AS URLDetails
				,	tmp.IP				AS IP
			FROM	(
					SELECT 	@TotalRow := @TotalRow + 1
						,	trs.TransTime
						,	trs.TransID
						,	trs.FirstDeviceCode
						,	ar.Action
						,	ar.ActionResult
						,	uag.OS
						,	uag.Browser
						,	ur.URLDetails
						,	trs.IP
					FROM	DCS_DataCenter.Transaction07 trs
                    	INNER JOIN CTS_DataCenter.CustDCSAccount AS ca ON trs.AccountID = ca.AccountID AND ca.SubscriberID = trs.SubscriberID
						INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON ca.CTSCustID = cus.CTSCustID 
						LEFT JOIN DCS_DataCenter.UserAgent AS uag ON trs.UserAgentKey = uag.UserAgentKey
						LEFT JOIN DCS_DataCenter.ActionResult AS ar ON trs.ActionResultID = ar.ActionResultID
						LEFT JOIN DCS_DataCenter.URL AS ur ON trs.URLID = ur.URLID
					WHERE trs.CreatedDate BETWEEN ip_FromDate AND ip_ToDate
						AND trs.AccountID IN (SELECT tmpAcc.AccountID FROM Temp_Account AS tmpAcc)
					) AS tmp
				ORDER BY TransTime DESC            
				LIMIT ip_Skip, ip_Take;
			
			SET op_TotalItem = @TotalRow;
	ELSE # Transaction History Report    
		SET @TotalRow = 0;
		SELECT 	tmp.TransTime		AS TransTime
			,	tmp.TransID			AS TransID
			,	tmp.LoginName		AS LoginName
			,	tmp.FirstDeviceCode	AS FirstDeviceCode
			,	tmp.Action			AS Action
			,	tmp.ActionResult	AS ActionResult
			,	tmp.OS				AS OS
			,	tmp.Browser			AS Browser
			,	tmp.URLDetails		AS URLDetails
			,	tmp.IP				AS IP
		FROM	(
				SELECT 	@TotalRow := @TotalRow + 1
					,	trs.TransTime
					,	trs.TransID
					,	trs.LoginName
					,	trs.FirstDeviceCode
					,	ar.Action
					,	ar.ActionResult
					,	uag.OS
					,	uag.Browser
					,	ur.URLDetails
					,	trs.IP
				FROM	DCS_DataCenter.Transaction07 trs 
					INNER JOIN CTS_DataCenter.CustDCSAccount AS ca ON trs.AccountID = ca.AccountID AND ca.SubscriberID = trs.SubscriberID
					INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON ca.CTSCustID = cus.CTSCustID AND cus.IsInternal = 0
					LEFT JOIN DCS_DataCenter.UserAgent AS uag ON trs.UserAgentKey = uag.UserAgentKey
					LEFT JOIN DCS_DataCenter.ActionResult AS ar ON trs.ActionResultID = ar.ActionResultID
					LEFT JOIN DCS_DataCenter.URL AS ur ON trs.URLID = ur.URLID
				WHERE trs.CreatedDate BETWEEN ip_FromDate AND ip_ToDate
					AND trs.SubscriberID = ip_SubscriberID
				) AS tmp
			ORDER BY TransTime DESC            
			LIMIT ip_Skip, ip_Take;
			
			SET op_TotalItem = @TotalRow;
	END IF;
END$$

DELIMITER ;
