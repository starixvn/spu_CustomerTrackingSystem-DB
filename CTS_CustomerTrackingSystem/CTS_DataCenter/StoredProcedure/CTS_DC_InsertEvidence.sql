DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_InsertEvidence $$

CREATE PROCEDURE CTS_DC_InsertEvidence (IN ip_EvidenceList JSON)
BEGIN
	/*
		Created:	20191107@Harvey
		Task:		Insert Evidence [Redmine ID: 116528]
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):
        
        CALL CTS_DC_InsertEvidence ('[{"EvidenceGroupID":1,"EvidenceCode":"1,1","EvidenceName":"Test evidence","EvidenceDesc":"This is example","OrderNo":2,"CreatedDate":"2019-11-11 11:19:35","CreatedBy":"1","IsActive":"1"}]')
	*/
	INSERT INTO `CTS_DataCenter`.`Evidence`
				(`EvidenceGroupID`,
				`EvidenceCode`,
				`EvidenceName`,
				`EvidenceDesc`,
				`OrderNo`,
				`CreatedDate`,
				`CreatedBy`,
				`IsActive`)
	SELECT *
	FROM JSON_TABLE(ip_EvidenceList,
		 "$[*]" COLUMNS(
          EvidenceGroupID		TINYINT		 	PATH "$.EvidenceGroupID" 
		, EvidenceCode 			VARCHAR(10) 	PATH "$.EvidenceCode"
		, EvidenceName			VARCHAR(50)		PATH "$.EvidenceName" 
        , EvidenceDesc			VARCHAR(200)	PATH "$.EvidenceDesc" 
        , OrderNo				SMALLINT		PATH "$.OrderNo" 
        , CreatedDate			TIMESTAMP(4)	PATH "$.CreatedDate"
        , CreatedBy				INT 			PATH "$.CreatedBy" 
        , IsActive				TINYINT		 	PATH "$.IsActive" 
		 )) as tmpTable;

END$$
DELIMITER ;