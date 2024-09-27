/*<info serverAlias="CTSMain-CTS_Archive" databaseType="2" executers="ctsServiceAdmin,ctsWebAdmin,ctsAPIAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_Arc_CustomerAssociation_InsertUpdate`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_Arc_CustomerAssociation_InsertUpdate`(
		IN ip_CustInfo 	JSON
)
    SQL SECURITY INVOKER
BEGIN
/*
		Created:	20211026@Aries.Nguyen
		Task:		Archive Inactive Association
		DB:			CTS_Archive
		Original:
		Revisions:
			- 20211026@Aries.Nguyen: Created [Redmine ID: #163087]         
			- 20230207@Long.Luu: Get exact lastticketdate [Redmine ID: #183281]
            - 20240927@Casey.Huynh: Insert New SMA to CTSCustomerAssociationStatusSMA [Redmine ID: #185799]
        Param's Explanation (filtered by):
        
        Example:
			- CALL CTS_Arc_CustomerAssociation_InsertUpdate('[
						{"CTSCustID": 1,"CustID": 11, "RoleID:4"}
					,	{"CTSCustID": 2,"CustID": 12, "RoleID:3"}
					,	{"CTSCustID": 3,"CustID": 13, "RoleID:2"}
                    , 	{"CTSCustID": 4,"CustID": 14, "RoleID:1"}]');
	*/   
    DECLARE	CONST_ROLEID_MEMBER TINYINT DEFAULT 1;
    DECLARE	CONST_ROLEID_AGENT TINYINT DEFAULT 2;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;    
	CREATE TEMPORARY TABLE Temp_Cust( 	  
			CTSCustID 	BIGINT UNSIGNED	
		,	CustID		BIGINT UNSIGNED
        ,	RoleID		TINYINT
        
        ,	PRIMARY	KEY (CTSCustID)
        ,	INDEX IX_Temp_Cust_RoleID(RoleID)
	);
    
	INSERT IGNORE INTO Temp_Cust(CTSCustID, CustID, RoleID)
	SELECT	info.CTSCustID
		, 	info.CustID
        ,	info.RoleID
	FROM JSON_TABLE(ip_CustInfo,
		 "$[*]" COLUMNS(
				CTSCustID	BIGINT UNSIGNED	PATH "$.CTSCustID" 
			, 	CustID		BIGINT UNSIGNED	PATH "$.CustID" 
			, 	CustSubID	BIGINT UNSIGNED	PATH "$.CustSubID" 
			, 	RoleID		TINYINT			PATH "$.RoleID" )
	) AS info
	WHERE info.RoleID IN (CONST_ROLEID_MEMBER,CONST_ROLEID_AGENT) AND info.CustSubID = 0;
    
	INSERT INTO CTS_Archive.CTSCustomerAssociationStatus(CTSCustID, CustID, LastTicketDate)
	SELECT	tmp.CTSCustID
		,	tmp.CustID
		,	NULL
	FROM Temp_Cust AS tmp
	WHERE tmp.RoleID = CONST_ROLEID_MEMBER
		AND NOT EXISTS (SELECT 1 FROM CTS_Archive.CTSCustomerAssociationStatus AS arc  WHERE arc.CTSCustID = tmp.CTSCustID);
        
	INSERT INTO CTS_Archive.CTSCustomerAssociationStatusSMA(CTSCustID, CustID, RoleID, LastTicketDate)
	SELECT	tmp.CTSCustID
		,	tmp.CustID
		,	tmp.RoleID
		,	NULL
	FROM Temp_Cust AS tmp
	WHERE tmp.RoleID = CONST_ROLEID_AGENT
		AND NOT EXISTS (SELECT 1 FROM CTS_Archive.CTSCustomerAssociationStatusSMA AS arc  WHERE arc.CTSCustID = tmp.CTSCustID);
    
END$$
DELIMITER ;

CALL CTS_Arc_CustomerAssociation_InsertUpdate('[{"CTSCustID":646661,"CustID":70449935,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646674,"CustID":70449943,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646675,"CustID":70450017,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646676,"CustID":70450189,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646677,"CustID":70450507,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646678,"CustID":70450748,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646679,"CustID":70450835,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646680,"CustID":70450852,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646681,"CustID":70450904,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646682,"CustID":70450950,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646683,"CustID":70451359,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646684,"CustID":70451370,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646685,"CustID":70451380,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646686,"CustID":70451631,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646687,"CustID":70451815,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646688,"CustID":70452384,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646689,"CustID":70452400,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646690,"CustID":70452653,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646691,"CustID":70452969,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646692,"CustID":70453089,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646693,"CustID":70453359,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646694,"CustID":70454022,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646695,"CustID":70454282,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646696,"CustID":70454293,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646697,"CustID":70454357,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646698,"CustID":70454413,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646699,"CustID":70454456,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646700,"CustID":70454923,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646701,"CustID":70455226,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646702,"CustID":70455294,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646703,"CustID":70455302,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646704,"CustID":70455332,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646705,"CustID":70455450,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646706,"CustID":70455500,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646707,"CustID":70455583,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646708,"CustID":70455672,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646709,"CustID":70455777,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646710,"CustID":70455812,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646711,"CustID":70456151,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646712,"CustID":70456317,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646713,"CustID":70456428,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646714,"CustID":70456658,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646715,"CustID":70457025,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646716,"CustID":70457183,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646717,"CustID":70457590,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646718,"CustID":70457609,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646719,"CustID":70457650,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646720,"CustID":70457658,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646721,"CustID":70457770,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646722,"CustID":70458309,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646723,"CustID":70458514,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646724,"CustID":70458569,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646725,"CustID":70458636,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646726,"CustID":70458755,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646727,"CustID":70459367,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646728,"CustID":70459529,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646729,"CustID":70459648,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646730,"CustID":70460091,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646731,"CustID":70460418,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646732,"CustID":70460633,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646733,"CustID":70460745,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646734,"CustID":70460851,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646735,"CustID":70461272,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646736,"CustID":70461393,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646737,"CustID":70461766,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646738,"CustID":70462533,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646739,"CustID":70463162,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646740,"CustID":70463388,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646741,"CustID":70463880,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646742,"CustID":70464028,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646743,"CustID":70464102,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646744,"CustID":70464273,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646745,"CustID":70464394,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646746,"CustID":70464436,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646747,"CustID":70464453,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646748,"CustID":70464538,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646749,"CustID":70464793,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646750,"CustID":70465221,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646751,"CustID":70465589,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646752,"CustID":70465652,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646753,"CustID":70465790,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646754,"CustID":70466024,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646755,"CustID":70466097,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646756,"CustID":70466130,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646757,"CustID":70466552,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646758,"CustID":70466587,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646759,"CustID":70466992,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646760,"CustID":70467117,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646761,"CustID":70467698,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646762,"CustID":70467942,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646763,"CustID":70468390,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646764,"CustID":70469073,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646765,"CustID":70469077,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646766,"CustID":70469140,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646767,"CustID":70469163,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646768,"CustID":70469297,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646769,"CustID":70469402,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646770,"CustID":70469505,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646771,"CustID":70469872,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646772,"CustID":70470264,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646773,"CustID":70471349,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646774,"CustID":70471437,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646775,"CustID":70472300,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646776,"CustID":70472383,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646777,"CustID":70472920,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646778,"CustID":70473644,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646779,"CustID":70473846,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646780,"CustID":70473913,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646781,"CustID":70474462,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646782,"CustID":70474987,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646783,"CustID":70475006,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646784,"CustID":70475044,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646785,"CustID":70475231,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646786,"CustID":70475282,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646787,"CustID":70475674,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646788,"CustID":70475804,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646789,"CustID":70475942,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646790,"CustID":70476159,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646791,"CustID":70476246,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646792,"CustID":70476379,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646793,"CustID":70476438,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646794,"CustID":70476472,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646795,"CustID":70476473,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646796,"CustID":70476482,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646797,"CustID":70476587,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646798,"CustID":70476624,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646799,"CustID":70476719,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646800,"CustID":70476722,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646801,"CustID":70476750,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646802,"CustID":70476761,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646803,"CustID":70476994,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646804,"CustID":70477157,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646805,"CustID":70477340,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646806,"CustID":70477487,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646807,"CustID":70477491,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646808,"CustID":70477637,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646809,"CustID":70477863,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646810,"CustID":70478116,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646811,"CustID":70478204,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646812,"CustID":70478304,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646813,"CustID":70478373,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646814,"CustID":70478383,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646815,"CustID":70478552,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646816,"CustID":70478648,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646817,"CustID":70478671,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646818,"CustID":70478679,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646819,"CustID":70478960,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646820,"CustID":70479037,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646821,"CustID":70479213,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646822,"CustID":70479216,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646823,"CustID":70479241,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646824,"CustID":70479287,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646825,"CustID":70479353,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646826,"CustID":70479522,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646827,"CustID":70479607,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646828,"CustID":70480045,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646829,"CustID":70480118,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646830,"CustID":70480218,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646831,"CustID":70480316,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646832,"CustID":70480337,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646833,"CustID":70480349,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646834,"CustID":70480682,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646835,"CustID":70480796,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646836,"CustID":70480930,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646837,"CustID":70480953,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646838,"CustID":70481118,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646839,"CustID":70481248,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646840,"CustID":70481286,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646841,"CustID":70481310,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646842,"CustID":70481373,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646843,"CustID":70481585,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646844,"CustID":70481851,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646845,"CustID":70481853,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646846,"CustID":70482001,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646847,"CustID":70482331,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646848,"CustID":70482370,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646849,"CustID":70482389,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646850,"CustID":70482511,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646851,"CustID":70482830,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646852,"CustID":70482912,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646853,"CustID":70483156,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646854,"CustID":70483274,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646855,"CustID":70483564,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646856,"CustID":70483601,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646857,"CustID":70483613,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646858,"CustID":70483743,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646859,"CustID":70483750,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646860,"CustID":70483956,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646861,"CustID":70483988,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646862,"CustID":70484315,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646863,"CustID":70484463,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646864,"CustID":70484587,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646865,"CustID":70485002,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646866,"CustID":70485009,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646867,"CustID":70485054,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646868,"CustID":70485084,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646869,"CustID":70485098,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646870,"CustID":70485132,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646871,"CustID":70485151,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646872,"CustID":70485316,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646873,"CustID":70485349,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646874,"CustID":70485400,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646875,"CustID":70485547,"RoleID":4,"CustSubID":0}
,{"CTSCustID":646876,"CustID":70485548,"RoleID":3,"CustSubID":0}
,{"CTSCustID":646877,"CustID":70485549,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646878,"CustID":70485550,"RoleID":3,"CustSubID":0}
,{"CTSCustID":646879,"CustID":70485551,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646880,"CustID":70485552,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646881,"CustID":70485553,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646882,"CustID":70485554,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646883,"CustID":70485555,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646884,"CustID":70485556,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646885,"CustID":70485557,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646886,"CustID":70485558,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646887,"CustID":70485559,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646888,"CustID":70485560,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646889,"CustID":70485561,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646890,"CustID":70485562,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646891,"CustID":70485563,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646892,"CustID":70485564,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646893,"CustID":70485565,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646894,"CustID":70485566,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646895,"CustID":70485567,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646896,"CustID":70485568,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646897,"CustID":70485574,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646898,"CustID":70485575,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646899,"CustID":70485576,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646900,"CustID":70485577,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646901,"CustID":70485578,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646902,"CustID":70485579,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646903,"CustID":70485580,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646904,"CustID":70485581,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646905,"CustID":70485582,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646906,"CustID":70485583,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646907,"CustID":70485584,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646908,"CustID":70485585,"RoleID":4,"CustSubID":0}
,{"CTSCustID":646909,"CustID":70485586,"RoleID":3,"CustSubID":0}
,{"CTSCustID":646910,"CustID":70485587,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646911,"CustID":70485588,"RoleID":3,"CustSubID":0}
,{"CTSCustID":646912,"CustID":70485589,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646913,"CustID":70485590,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646914,"CustID":70485591,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646915,"CustID":70485592,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646916,"CustID":70485593,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646917,"CustID":70485594,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646918,"CustID":70485595,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646919,"CustID":70485596,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646920,"CustID":70485597,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646921,"CustID":70485598,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646922,"CustID":70485599,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646923,"CustID":70485600,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646924,"CustID":70485601,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646925,"CustID":70485602,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646926,"CustID":70485603,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646927,"CustID":70485604,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646928,"CustID":70485605,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646929,"CustID":70485606,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646930,"CustID":70485611,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646931,"CustID":70485612,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646932,"CustID":70485613,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646933,"CustID":70485614,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646934,"CustID":70485615,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646935,"CustID":70485616,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646936,"CustID":70485617,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646937,"CustID":70485618,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646938,"CustID":70485619,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646939,"CustID":70485620,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646940,"CustID":70485621,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646941,"CustID":70485622,"RoleID":4,"CustSubID":0}
,{"CTSCustID":646942,"CustID":70485623,"RoleID":3,"CustSubID":0}
,{"CTSCustID":646943,"CustID":70485624,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646944,"CustID":70485625,"RoleID":3,"CustSubID":0}
,{"CTSCustID":646945,"CustID":70485626,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646946,"CustID":70485627,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646947,"CustID":70485628,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646948,"CustID":70485629,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646949,"CustID":70485630,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646950,"CustID":70485631,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646951,"CustID":70485632,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646952,"CustID":70485633,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646953,"CustID":70485634,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646954,"CustID":70485635,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646955,"CustID":70485636,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646956,"CustID":70485637,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646957,"CustID":70485638,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646958,"CustID":70485639,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646959,"CustID":70485640,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646960,"CustID":70485641,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646961,"CustID":70485642,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646962,"CustID":70485643,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646963,"CustID":70485645,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646964,"CustID":70485646,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646965,"CustID":70485647,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646966,"CustID":70485648,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646967,"CustID":70485649,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646968,"CustID":70485650,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646969,"CustID":70485651,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646970,"CustID":70485652,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646971,"CustID":70485653,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646972,"CustID":70485654,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646973,"CustID":70485655,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646974,"CustID":70485656,"RoleID":4,"CustSubID":0}
,{"CTSCustID":646975,"CustID":70485657,"RoleID":3,"CustSubID":0}
,{"CTSCustID":646976,"CustID":70485658,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646977,"CustID":70485659,"RoleID":3,"CustSubID":0}
,{"CTSCustID":646978,"CustID":70485660,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646979,"CustID":70485661,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646980,"CustID":70485662,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646981,"CustID":70485663,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646982,"CustID":70485664,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646983,"CustID":70485665,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646984,"CustID":70485666,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646985,"CustID":70485667,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646986,"CustID":70485668,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646987,"CustID":70485669,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646988,"CustID":70485670,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646989,"CustID":70485671,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646990,"CustID":70485672,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646991,"CustID":70485673,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646992,"CustID":70485674,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646993,"CustID":70485675,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646994,"CustID":70485676,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646995,"CustID":70485677,"RoleID":2,"CustSubID":0}
,{"CTSCustID":646996,"CustID":70485683,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646997,"CustID":70485684,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646998,"CustID":70485685,"RoleID":1,"CustSubID":0}
,{"CTSCustID":646999,"CustID":70485686,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647000,"CustID":70485687,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647001,"CustID":70485688,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647002,"CustID":70485689,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647003,"CustID":70485690,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647004,"CustID":70485691,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647005,"CustID":70485692,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647006,"CustID":70485693,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647007,"CustID":70485694,"RoleID":4,"CustSubID":0}
,{"CTSCustID":647008,"CustID":70485695,"RoleID":3,"CustSubID":0}
,{"CTSCustID":647009,"CustID":70485696,"RoleID":2,"CustSubID":0}
,{"CTSCustID":647010,"CustID":70485697,"RoleID":3,"CustSubID":0}
,{"CTSCustID":647011,"CustID":70485698,"RoleID":2,"CustSubID":0}
,{"CTSCustID":647012,"CustID":70485699,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647013,"CustID":70485700,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647014,"CustID":70485701,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647015,"CustID":70485702,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647016,"CustID":70485703,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647017,"CustID":70485704,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647018,"CustID":70485705,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647019,"CustID":70485706,"RoleID":2,"CustSubID":0}
,{"CTSCustID":647020,"CustID":70485707,"RoleID":2,"CustSubID":0}
,{"CTSCustID":647021,"CustID":70485708,"RoleID":2,"CustSubID":0}
,{"CTSCustID":647022,"CustID":70485709,"RoleID":2,"CustSubID":0}
,{"CTSCustID":647023,"CustID":70485710,"RoleID":2,"CustSubID":0}
,{"CTSCustID":647024,"CustID":70485711,"RoleID":2,"CustSubID":0}
,{"CTSCustID":647025,"CustID":70485712,"RoleID":2,"CustSubID":0}
,{"CTSCustID":647026,"CustID":70485713,"RoleID":2,"CustSubID":0}
,{"CTSCustID":647027,"CustID":70485714,"RoleID":2,"CustSubID":0}
,{"CTSCustID":647028,"CustID":70485715,"RoleID":2,"CustSubID":0}
,{"CTSCustID":647029,"CustID":70485719,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647030,"CustID":70485720,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647031,"CustID":70485721,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647032,"CustID":70485722,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647033,"CustID":70485723,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647034,"CustID":70485724,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647035,"CustID":70485725,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647036,"CustID":70485726,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647037,"CustID":70485727,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647038,"CustID":70485728,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647039,"CustID":70485729,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647040,"CustID":70485731,"RoleID":4,"CustSubID":0}
,{"CTSCustID":647041,"CustID":70485732,"RoleID":3,"CustSubID":0}
,{"CTSCustID":647042,"CustID":70485733,"RoleID":2,"CustSubID":0}
,{"CTSCustID":647043,"CustID":70485734,"RoleID":3,"CustSubID":0}
,{"CTSCustID":647044,"CustID":70485735,"RoleID":2,"CustSubID":0}
,{"CTSCustID":647045,"CustID":70485736,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647046,"CustID":70485737,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647047,"CustID":70485738,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647048,"CustID":70485739,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647049,"CustID":70485740,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647050,"CustID":70485741,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647051,"CustID":70485742,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647052,"CustID":70485743,"RoleID":2,"CustSubID":0}
,{"CTSCustID":647053,"CustID":70485744,"RoleID":2,"CustSubID":0}
,{"CTSCustID":647054,"CustID":70485745,"RoleID":2,"CustSubID":0}
,{"CTSCustID":647055,"CustID":70485746,"RoleID":2,"CustSubID":0}
,{"CTSCustID":647056,"CustID":70485747,"RoleID":2,"CustSubID":0}
,{"CTSCustID":647057,"CustID":70485748,"RoleID":2,"CustSubID":0}
,{"CTSCustID":647058,"CustID":70485749,"RoleID":2,"CustSubID":0}
,{"CTSCustID":647059,"CustID":70485750,"RoleID":2,"CustSubID":0}
,{"CTSCustID":647060,"CustID":70485751,"RoleID":2,"CustSubID":0}
,{"CTSCustID":647061,"CustID":70485752,"RoleID":2,"CustSubID":0}
,{"CTSCustID":647062,"CustID":70485760,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647063,"CustID":70485761,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647064,"CustID":70485762,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647065,"CustID":70485763,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647066,"CustID":70485764,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647067,"CustID":70485765,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647068,"CustID":70485766,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647069,"CustID":70485767,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647070,"CustID":70485768,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647071,"CustID":70485769,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647072,"CustID":70485770,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647073,"CustID":70485925,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647074,"CustID":70485980,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647075,"CustID":70486120,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647076,"CustID":70486219,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647077,"CustID":70486347,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647078,"CustID":70486361,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647079,"CustID":70486444,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647080,"CustID":70486531,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647081,"CustID":70486765,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647082,"CustID":70486867,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647083,"CustID":70487620,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647084,"CustID":70487896,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647085,"CustID":70487909,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647086,"CustID":70487980,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647087,"CustID":70488072,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647088,"CustID":70488242,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647089,"CustID":70488283,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647090,"CustID":70488406,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647091,"CustID":70488502,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647092,"CustID":70488529,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647093,"CustID":70488646,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647094,"CustID":70488747,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647095,"CustID":70489181,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647096,"CustID":70489332,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647097,"CustID":70489519,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647098,"CustID":70489613,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647099,"CustID":70489665,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647100,"CustID":70489749,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647101,"CustID":70489791,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647102,"CustID":70489832,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647103,"CustID":70489953,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647104,"CustID":70490122,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647105,"CustID":70490268,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647106,"CustID":70490316,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647107,"CustID":70490359,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647108,"CustID":70490438,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647109,"CustID":70490520,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647110,"CustID":70490594,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647111,"CustID":70490608,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647112,"CustID":70490611,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647113,"CustID":70490829,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647114,"CustID":70490840,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647115,"CustID":70491165,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647116,"CustID":70491229,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647117,"CustID":70491369,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647118,"CustID":70491419,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647119,"CustID":70491454,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647120,"CustID":70491476,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647121,"CustID":70491616,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647122,"CustID":70491801,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647123,"CustID":70491823,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647124,"CustID":70491895,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647125,"CustID":70491949,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647126,"CustID":70491999,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647127,"CustID":70492048,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647128,"CustID":70492103,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647129,"CustID":70492295,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647130,"CustID":70492598,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647131,"CustID":70492655,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647132,"CustID":70492739,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647133,"CustID":70492887,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647134,"CustID":70492942,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647135,"CustID":70493170,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647136,"CustID":70493270,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647137,"CustID":70493390,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647138,"CustID":70493553,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647139,"CustID":70493574,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647140,"CustID":70493651,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647141,"CustID":70493656,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647142,"CustID":70493663,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647143,"CustID":70494010,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647144,"CustID":70494019,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647145,"CustID":70494248,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647146,"CustID":70494349,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647147,"CustID":70494363,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647148,"CustID":70494473,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647149,"CustID":70494861,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647150,"CustID":70494965,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647151,"CustID":70495158,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647152,"CustID":70495354,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647153,"CustID":70495379,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647154,"CustID":70495449,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647155,"CustID":70495485,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647156,"CustID":70495634,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647157,"CustID":70495916,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647158,"CustID":70496005,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647159,"CustID":70496025,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647160,"CustID":70496092,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647161,"CustID":70496162,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647162,"CustID":70496241,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647163,"CustID":70496301,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647164,"CustID":70496380,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647165,"CustID":70496460,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647166,"CustID":70496683,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647167,"CustID":70496952,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647168,"CustID":70496955,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647169,"CustID":70497323,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647170,"CustID":70497324,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647171,"CustID":70497397,"RoleID":1,"CustSubID":0}
,{"CTSCustID":647172,"CustID":70497419,"RoleID":1,"CustSubID":0}]');