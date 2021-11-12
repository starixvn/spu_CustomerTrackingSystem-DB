/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_TWProblemDetectionMonitor_Insert`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_TWProblemDetectionMonitor_Insert`(
	IN ip_CustDetectInfo JSON
)
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20211110@Casey.Huynh
		Task :		Insert Cust need to monitor
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20211110@Casey.Huynh: Created [Redmine ID: 164148]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL CTS_DC_TWProblemDetectionMonitor_Insert('[
				  {"CustID" : 2111103,"UserName" : "AW0078010","RoleID" : 1,"ReasonID" : 1,"PreventActionID" : 2,"Comment" : "Testing","VoidTime" : "2021-11-12 00:36:39.5043","LimitAcount" : 1000.01,"UserID" : 1234,"IP" : "192.168.8.9"},
				  {"CustID" : 2158796,"UserName" : "AW0078045","RoleID" : 1,"ReasonID" : 1,"PreventActionID" : 2,"Comment" : "Testing","VoidTime" : "2021-11-12 00:36:39.5043","LimitAcount" : 1000.01,"UserID" : 1234,"IP" : "192.168.8.9"}
					]');;
            

	*/
    
    INSERT IGNORE INTO CTS_DataCenter.TWProblemDetectionMonitor(CustID, UserName, RoleID, ReasonID, PreventActionID, Comment, VoidTime, LimitAcount, UserID, IP, CreatedDate)
    SELECT	jsTbl.CustID
		,	jsTbl.UserName
		,	jsTbl.RoleID
		,	jsTbl.ReasonID
		,	jsTbl.PreventActionID
		,	jsTbl.Comment
		,	jsTbl.VoidTime
		,	jsTbl.LimitAcount
		,	jsTbl.UserID
		,	jsTbl.IP
		,	CURRENT_DATE() AS CreatedDate
	 FROM JSON_TABLE(ip_CustDetectInfo,
					"$[*]" COLUMNS(
										CustID		INT UNSIGNED	PATH "$.CustID"
									,	UserName	VARCHAR(50)		PATH "$.UserName"
									,	RoleID		TINYINT			PATH "$.RoleID"
									,	ReasonID	TINYINT 		PATH "$.ReasonID"
									,	PreventActionID	TINYINT		PATH "$.PreventActionID"
									,	Comment		VARCHAR(300)	PATH "$.Comment"
									,	VoidTime	VARCHAR(50)		PATH "$.VoidTime"
									,	LimitAcount DECIMAL(20,4)	PATH "$.LimitAcount"
									,	UserID		INT				PATH "$.UserID"
									,	IP			VARCHAR(15)    	PATH "$.IP"
					 )) AS 	jsTbl;

END$$
DELIMITER ;

