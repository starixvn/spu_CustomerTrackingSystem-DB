/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_Remark_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Remark_Get`(
	IN	ip_InputFlowID			INT
)
    SQL SECURITY INVOKER
BEGIN
  /*
		Created:	20240626@Thomas.Nguyen
		Task:		Get remark from remark template
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 20240626@Thomas.Nguyen: Created [Redmine ID: #205317]
			
		Param's Explanation (filtered by):		
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_Remark_Get();
	*/   
		/*
- Use Temp_NewClassification (custid, categoryid, sourcetypeid, turnover, winloss, betcount,...)
- Get more infor from source table (detecteddate/sourcecreateddate, probability, GBbetcount,...)
- Get template from CustomerClassification_Remark by sourcetypeid
- Fill infor into template and return full remark to insert into history table
    
		*/
    DECLARE CONST_CATEID_VVIP INT;
    DECLARE CONST_CATEID_LICBA INT;
    DECLARE CONST_CATEID_LICVIPSUSPICIOUS INT;
    DECLARE CONST_CATEID_LICVIPDANGEROUS INT;
    DECLARE CONST_CATEID_SPECIALCC INT;
    DECLARE CONST_CATEID_ROBOTUSER INT;
    DECLARE CONST_CATEID_ROBOTOCRD INT;
    DECLARE CONST_CATEID_ROBOTUSERLOSING INT;
    DECLARE CONST_CATEID_ROBOTOCRDLOSING INT;
    DECLARE CONST_CATEID_NEW INT;
    DECLARE	CONST_CATEID_UNAUTHORIZEDLOGIN 			INT;
    DECLARE	CONST_CATEID_UNAUTHORIZEDLOGINLOSING		INT;
    DECLARE	CONST_CATEID_EARLYWARNINGMEMBERS 			INT;
    DECLARE	CONST_CATEID_EARLYWARNINGMEMBERSLOSING	INT;
	DECLARE	CONST_CATEID_INITIALGB		 			INT;
    DECLARE	CONST_CATEID_INITIALGBLOSING				INT;
	DECLARE	CONST_CATEID_INITIALSMART		 			INT;
    DECLARE	CONST_CATEID_INITIALSMARTLOSING			INT;

    DECLARE CONST_REMARKID_TVSREQUESTIDPARLAY       INT DEFAULT 40;
    DECLARE CONST_REMARKID_TVSBETIDPARLAY           INT DEFAULT 41;
    DECLARE CONST_REMARKID_ROBOTFROMTW              INT DEFAULT 50;
    DECLARE CONST_REMARKID_ROBOTFROMIMPERVA         INT DEFAULT 51;
    DECLARE CONST_REMARKID_ROBOTFROMAI              INT DEFAULT 52;
    DECLARE CONST_REMARKID_ROBOTFROMCTS             INT DEFAULT 53;
    DECLARE CONST_REMARKID_ROBOTFROMTVSREQUESTID    INT DEFAULT 54;
    DECLARE CONST_REMARKID_ROBOTFROMTVSBETID        INT DEFAULT 55;

    DECLARE lv_LicBA_CategoryName				VARCHAR(50);
    DECLARE lv_LicBA_CC							SMALLINT UNSIGNED;
    DECLARE lv_LicVIPProblem_CC					SMALLINT UNSIGNED;
    DECLARE lv_LicVIPNormal_CC					SMALLINT UNSIGNED;
    DECLARE lv_LicVIPProblem_CategoryName		VARCHAR(50);
    DECLARE lv_LicVIPNormal_CategoryName		VARCHAR(50);        
    
    DECLARE lv_Delimiter VARCHAR(5);

    SET lv_Delimiter = "|";

    SET CONST_CATEID_ROBOTUSER 		                = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_ROBOTUSER');
    SET CONST_CATEID_ROBOTOCRD 		                = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_ROBOTOCRD');
    SET CONST_CATEID_ROBOTUSERLOSING 		        = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_ROBOTUSERLOSING');
    SET CONST_CATEID_ROBOTOCRDLOSING 		        = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_ROBOTOCRDLOSING');
    SET CONST_CATEID_LICBA 		                    = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICBA');
    SET CONST_CATEID_LICVIPSUSPICIOUS 		        = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICVIPSUSPICIOUS');
    SET CONST_CATEID_LICVIPDANGEROUS 		        = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICVIPDANGEROUS');
    SET CONST_CATEID_UNAUTHORIZEDLOGIN 		        = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_UNAUTHORIZEDLOGIN');
    SET CONST_CATEID_UNAUTHORIZEDLOGINLOSING 		= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_UNAUTHORIZEDLOGINLOSING');
    SET CONST_CATEID_EARLYWARNINGMEMBERS 		    = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_EARLYWARNINGMEMBERS');
    SET CONST_CATEID_EARLYWARNINGMEMBERSLOSING 		= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_EARLYWARNINGMEMBERSLOSING');
    SET CONST_CATEID_INITIALGB 		                = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_INITIALGB');
    SET CONST_CATEID_INITIALGBLOSING 		        = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_INITIALGBLOSING');
    SET CONST_CATEID_INITIALSMART 		            = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_INITIALSMART');
    SET CONST_CATEID_INITIALSMARTLOSING 		    = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_INITIALSMARTLOSING');

    SELECT cat.CategoryName, cat.CustomerClass
    INTO lv_LicBA_CategoryName, lv_LicBA_CC
    FROM CTS_DataCenter.CustomerCategory AS cat
    WHERE cat.CategoryID = CONST_CATEID_LICBA;  

    SELECT cat.CategoryName, cat.CustomerClass
    INTO lv_LicVIPProblem_CategoryName, lv_LicVIPProblem_CC
    FROM CTS_DataCenter.CustomerCategory AS cat
    WHERE cat.CategoryID = CONST_CATEID_LICBA;
    
    SELECT cat.CategoryName, cat.CustomerClass
    INTO lv_LicVIPNormal_CategoryName, lv_LicVIPNormal_CC
    FROM CTS_DataCenter.CustomerCategory AS cat
    WHERE cat.CategoryID = CONST_CATEID_LICVIPSUSPICIOUS;        

	DROP TEMPORARY TABLE IF EXISTS Temp_CustRemark;
	CREATE TEMPORARY TABLE 	Temp_CustRemark (
				CustID				BIGINT UNSIGNED
			,	CategoryID			INT
			,	Remark				TEXT
			,	PRIMARY KEY (CustID, CategoryID)	
	);

    IF EXISTS (SELECT 1 FROM Temp_NewClassification AS tmp
                        INNER JOIN CTS_DataCenter.CustomerCategorySettings AS cs ON cs.CategoryID = tmp.CategoryID
                        WHERE cs.RemarkID IS NOT NULL) THEN
        INSERT IGNORE INTO Temp_CustRemark(CustID, CategoryID, Remark)
        SELECT  tmp.CustID
            ,   tmp.CategoryID
            ,   cr.RemarkTemplate
        FROM Temp_NewClassification AS tmp
            INNER JOIN CTS_DataCenter.CustomerCategorySettings AS cs ON cs.CategoryID = tmp.CategoryID AND cs.RemarkID IS NOT NULL
            INNER JOIN CTS_DataCenter.CustomerClassification_Remark AS cr ON cr.RemarkID = cs.RemarkTemplateID;

		IF ip_InputFlowID IN (1,2,3,4) THEN /*ip_InputFlowID: VVIP/SpecialCC/LicVIP/LicBA*/
			INSERT IGNORE INTO Temp_CustRemark(CustID, CategoryID, Remark)
			SELECT  tmp.CustID
				,   tmp.CategoryID
				,	CASE WHEN tmp.TargetCC IN (lv_LicVIPProblem_CC,lv_LicVIPNormal_CC,lv_LicBA_CC) THEN
						CONCAT(CASE WHEN tmp.TargetCC = lv_LicVIPProblem_CC THEN lv_LicVIPProblem_CategoryName
								WHEN tmp.TargetCC = lv_LicVIPNormal_CC THEN lv_LicVIPNormal_CategoryName
								WHEN tmp.TargetCC = lv_LicBA_CC THEN lv_LicBA_CategoryName END,' ',cr.RemarkTemplate)
					ELSE CONCAT(cr.RemarkTemplate, lv_Delimiter, IFNULL(tmp.Remark,'')) END AS Remark
			FROM Temp_NewClassification AS tmp
				INNER JOIN CTS_DataCenter.CustomerClassification_Remark AS cr ON cr.RemarkID = tmp.SourceTypeID
			WHERE tmp.SourceTypeID IS NOT NULL;

			SELECT	CustID
				,	CategoryID
				,	Remark
			FROM Temp_CustRemark;

		END IF;
	ELSE /*IF ip_InputFlowID IN (50,51,6,7,8): PA/PotentialPA/Robot/Normal*/
        INSERT IGNORE INTO Temp_CustRemark(CustID, CategoryID, Remark)
        WITH CTECustRemarkID AS (
        SELECT  tmp.CustID
            ,   tmp.CategoryID
            ,   CASE    
                    WHEN tmp.IsFromTVS = 1 AND TVSRequestID > 0 AND tmp.WinlossRM IS NOT NULL AND tmp.TVSSportType > 0 AND tmp.IsTVSParlay = 1 THEN CONST_REMARKID_TVSREQUESTIDPARLAY
                    WHEN tmp.IsFromTVS = 1 AND TVSRequestID = 0 AND tmp.WinlossRM IS NOT NULL AND tmp.TVSSportType > 0 AND tmp.IsTVSParlay = 1 THEN CONST_REMARKID_TVSBETIDPARLAY
                    WHEN tmp.CategoryID IN (CONST_CATEID_ROBOTUSER, CONST_CATEID_ROBOTOCRD, CONST_CATEID_ROBOTUSERLOSING, CONST_CATEID_ROBOTOCRDLOSING) THEN
                        CASE    WHEN tmp.IsFromTW = 1 THEN CONST_REMARKID_ROBOTFROMTW
                                WHEN tmp.IsFromImperva = 1 THEN CONST_REMARKID_ROBOTFROMIMPERVA
                                WHEN tmp.IsFromAI = 1 THEN CONST_REMARKID_ROBOTFROMAI
                                WHEN tmp.IsFromCTS = 1 THEN CONST_REMARKID_ROBOTFROMCTS
                                WHEN tmp.IsFromTVS = 1 AND TVSRequestID > 0 THEN CONST_REMARKID_ROBOTFROMTVSREQUESTID
                                WHEN tmp.IsFromTVS = 1 AND TVSRequestID = 0 THEN CONST_REMARKID_ROBOTFROMTVSBETID END
                    END AS RemarkID
        FROM Temp_NewClassification AS tmp
        )
        SELECT  cte.CustID
            ,   cte.CategoryID
            ,   cr.RemarkTemplate
        FROM CTECustRemarkID AS cte
        INNER JOIN CTS_DataCenter.CustomerClassification_Remark AS cr ON cr.RemarkID = cte.RemarkID;

        INSERT IGNORE INTO Temp_CustRemark(CustID, CategoryID, Remark)
        SELECT  tmp.CustID
            ,   tmp.CategoryID
            ,   cr.RemarkTemplate
		FROM Temp_NewClassification AS tmp
		    INNER JOIN CTS_DataCenter.CustomerClassification_Remark AS cr ON cr.RemarkID = tmp.SourceTypeID
        WHERE tmp.SourceTypeID IS NOT NULL;

        IF EXISTS (SELECT 1 FROM Temp_CustRemark WHERE CategoryID IN (CONST_CATEID_UNAUTHORIZEDLOGIN, CONST_CATEID_UNAUTHORIZEDLOGINLOSING)) THEN
            UPDATE Temp_CustRemark AS tmp
                INNER JOIN CustomerLoginInfoDetection AS cld ON cld.CustID = tmp.CustID
            SET tmp.Remark = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(tmp.Remark,'[FBDate]', DATE_FORMAT(cld.FirstBetDate, '%b %d, %Y'))
								,'[DetectedDate]', DATE_FORMAT(cld.SourceCreatedDate, '%b %d, %Y')), '[Bot]', cld.Bot),'[BotPCT]',cld.BotTransPercentage),'[InvalidBrowser]'
                                ,cld.InvalidBrowser),'[InvalidBrowserPCT]',cld.InvalidBrowserInfoTransPercentage)
            WHERE tmp.CategoryID IN (CONST_CATEID_UNAUTHORIZEDLOGIN, CONST_CATEID_UNAUTHORIZEDLOGINLOSING);

        ELSEIF EXISTS (SELECT 1 FROM Temp_CustRemark WHERE CategoryID IN (CONST_CATEID_EARLYWARNINGMEMBERS, CONST_CATEID_EARLYWARNINGMEMBERSLOSING)) THEN
            UPDATE Temp_CustRemark AS tmp
                INNER JOIN Customer_DangerousScore AS cds ON cds.CustID = tmp.CustID
            SET tmp.Remark = REPLACE(REPLACE(tmp.Remark,'[DetectedDate]', DATE_FORMAT(cds.ClassifiedDate, '%b %d, %Y')), '[DangerousScore]', CAST(cds.ClassifiedScore*100 AS DECIMAL(5,2)))
            WHERE tmp.CategoryID IN (CONST_CATEID_EARLYWARNINGMEMBERS, CONST_CATEID_EARLYWARNINGMEMBERSLOSING);

        ELSEIF EXISTS (SELECT 1 FROM Temp_CustRemark WHERE CategoryID IN (CONST_CATEID_INITIALSMART, CONST_CATEID_INITIALSMARTLOSING)) THEN
            UPDATE Temp_CustRemark AS tmp
                INNER JOIN Customer_InitialSmart AS cis ON cis.CustID = tmp.CustID
            SET tmp.Remark = REPLACE(REPLACE(tmp.Remark,'[DetectedDate]', DATE_FORMAT(cis.SourceCreatedDate, '%b %d, %Y')), '[Probability]', cis.Probability)
            WHERE tmp.CategoryID IN (CONST_CATEID_INITIALSMART, CONST_CATEID_INITIALSMARTLOSING);

        ELSEIF EXISTS (SELECT 1 FROM Temp_CustRemark WHERE CategoryID IN (CONST_CATEID_INITIALGB, CONST_CATEID_INITIALGBLOSING)) THEN
            UPDATE Temp_CustRemark AS tmp
                INNER JOIN Customer_InitialGroupBetting AS cgb ON cgb.CustID = tmp.CustID
            SET tmp.Remark = REPLACE(REPLACE(REPLACE(tmp.Remark,'[DetectedDate]', DATE_FORMAT(cgb.SourceCreatedDate, '%b %d, %Y')), '[GBTicketCount]', cgb.GBTicketCount), '[Sport]', cgb.SportType)
            WHERE tmp.CategoryID IN (CONST_CATEID_INITIALGB, CONST_CATEID_INITIALGBLOSING);
        END IF;

        SELECT	CustID
		    ,	CategoryID
		    ,	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(cust.Remark, 
                        '[TVSRequestID]', tmp.TVSRequestID)
                    ,   '[Winloss]', tmp.WinlossRM)
                    ,   '[TVSSportType]', tmp.TVSSportType)
                    ,   '[Margin]', CASE WHEN tmp.TurnOverRM = 0 THEN 0 ELSE (tmp.WinlossRM/tmp.TurnoverRM) * 100 END)
                    ,   '[BetCount]', tmp.BetCount)
                    ,   '[TurnOver]', tmp.TurnoverRM)
                    ,   '[ActiveDays]', tmp.ActiveDays)
                    /*,   '[TWBetCount]', tmp.TWBetCount*/
                    ,   '[TWGBRate]', tmp.TWGroupBettingRate)
                    ,   '[TWDesktopUsageRate]', tmp.TWDesktopUsageRate)
                    ,   '[TWTicketRejectRate]', tmp.TWTicketRejectRate)
                    ,   '[TWRobotCounter]', tmp.TWRobotCounter)
                    ,   '[MatchID]', tmp.MatchID)
                    ,   '[UserComment]', IFNULL(tmp.Remark,''))
	    FROM Temp_CustRemark AS cust
        INNER JOIN Temp_NewClassification AS tmp ON tmp.CustID = cust.CustID;
	END IF;

/*
{ RequestID }
,  {winloss}
, {sportname}
, {margin}
, {betCount}
, {turnOver}
, {activeDays}
, {first5TWGBTicketCount}
, {twGroupBettingRate}
, {twDesktopTicket}
, {twTicketRejectRate}
, {RobotCounter}
, {TVSRequestID}
, {MatchID}
, {CategoryName}
, {LicVIP}
, {LicBA} 

Detection Date: [DetectedDate] - GB Bet Count: [GBTicketCount] - Sport: [Sport] | Turnover: [Turnover] | Win loss: [Winloss] | Margin: [Margin] | Bet Count: [BetCount]
Customer_InitialGroupBetting
Customer_InitialSmart
Customer_DangerousScore
CustomerLoginInfoDetection
First Bet Date: Mar 30, 2024 | Detection Date: Apr 07, 2024 - Bot Trans: 8 (66.67%) - Invalid Browser Info Trans: 0 (0%) | Win loss: 1,984.52
Margin = (Winloss/Turnover) * 100
*/
END$$
DELIMITER ;
