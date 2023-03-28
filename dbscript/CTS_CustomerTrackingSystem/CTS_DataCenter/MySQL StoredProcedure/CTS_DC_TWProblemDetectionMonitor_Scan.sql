/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_TWProblemDetectionMonitor_Scan`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_TWProblemDetectionMonitor_Scan`(OUT op_LastCustID INT UNSIGNED)
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20211110@Casey.Huynh
		Task :		Return Cust list to scan
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20211110@Casey.Huynh: 	Created [Redmine ID: 164148]
			-	20230317@Victoria.Le:	Remove surplusage for not using - table CategoryToCustomerClass [Redmine ID: #184773]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL CTS_DC_TWProblemDetectionMonitor_Scan();
	*/
    DECLARE lv_BatchSize SMALLINT DEFAULT 500;
    DECLARE lv_LastCustID INT UNSIGNED;
    DECLARE lv_DelDate DATETIME;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Remove;
    CREATE TEMPORARY TABLE Temp_Remove(
			CustID INT UNSIGNED PRIMARY KEY
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Scan;
    CREATE TEMPORARY TABLE Temp_Scan(
			CustID INT UNSIGNED PRIMARY KEY
		,	CreatedDate	DATETIME
    );
    
	SELECT s.ParameterValue 
    INTO lv_BatchSize 
    FROM CTS_DataCenter.SystemParameter AS s WHERE s.ParameterID = 62;    
    
    SELECT s.ParameterValue 
    INTO lv_LastCustID 
    FROM CTS_DataCenter.SystemParameter AS s WHERE s.ParameterID = 63;   
    
    INSERT INTO Temp_Scan(CustID, CreatedDate)
    SELECT	tpd.CustID
		,	tpd.CreatedDate
    FROM CTS_DataCenter.TWProblemDetectionMonitor AS tpd
    WHERE tpd.CustID > lv_LastCustID AND tpd.CreatedDate < CURRENT_DATE()
    ORDER BY tpd.CustID ASC
    LIMIT lv_BatchSize;

    IF EXISTS (SELECT 1 FROM Temp_Scan) THEN
		SET lv_DelDate = DATE_SUB(CURRENT_DATE(), INTERVAL 59 DAY);
        
		SET op_LastCustID = (SELECT MAX(s.CustID) FROM Temp_Scan AS s); 
        
		INSERT INTO Temp_Remove(CustID)    
		SELECT	tmpS.CustID
		FROM Temp_Scan AS tmpS
			INNER JOIN CTS_Archive.CTSCustomerAssociationStatus AS cas ON cas.CustID = tmpS.CustID AND cas.LastTicketDate < lv_DelDate
		WHERE tmpS.CreatedDate < lv_DelDate;
        
        IF EXISTS (SELECT 1 FROM Temp_Remove) THEN
			DELETE tpd
			FROM CTS_DataCenter.TWProblemDetectionMonitor AS tpd
			INNER JOIN Temp_Remove AS tmpRev ON tpd.CustID = tmpRev.CustID;
			
			DELETE tmpS
			FROM Temp_Scan AS tmpS
				INNER JOIN Temp_Remove AS tmpRev ON tmpS.CustID = tmpRev.CustID;
		END IF;	
        
		SELECT 	tpd.CustID
			,	tpd.UserName
			,	tpd.RoleID
			,	tpd.ReasonID
			,	tpd.PreventActionID
			,	tpd.Comment
			,	tpd.VoidTime
			,	tpd.LimitAmount
			,	tpd.UserID
			,	tpd.IP
			,	(CASE WHEN cc.ParentID = 200 AND GROUP_CONCAT(cc.CategoryGroup) IN (201,202,205) THEN 1 ELSE 0 END) AS IsMonitorCategoryGroup
			,	1 AS IsMonitorSite
			,	tpd.InsertTime        
		FROM Temp_Scan AS tmpS
			INNER JOIN CTS_DataCenter.TWProblemDetectionMonitor AS tpd ON tpd.CustID = tmpS.CustID
			INNER JOIN CTS_DataCenter.CTSCustomerClassification AS ccl ON tpd.CustID = ccl.CustID 
			INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON ccl.CategoryID = cc.CategoryID
		GROUP BY cc.ParentID, tpd.CustID, tpd.UserName, tpd.RoleID, tpd.ReasonID, tpd.PreventActionID, tpd.Comment, tpd.VoidTime, tpd.LimitAmount, tpd.UserID, tpd.IP; 			
	ELSE 
		SET op_LastCustID = 0;
		
		UPDATE CTS_DataCenter.SystemParameter AS s 
		SET s.ParameterValue =0
		WHERE s.ParameterID = 63;
    END IF;

END$$
DELIMITER ;

