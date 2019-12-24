DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_InsertEvidenceGroup $$

CREATE PROCEDURE CTS_DC_InsertEvidenceGroup (IN ip_EvidenceGroupList JSON)
BEGIN
	/*
		Created:	20191107@Harvey
		Task:		Insert Customer [Redmine ID: 116528]
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):
        
        CALL CTS_DC_InsertEvidenceGroup ('[{"EvidenceGroupName":"Group A","EvidenceGroupDesc":"This is example","OrderNo":2,"CreatedDate":"2019-11-11 11:19:35","CreatedBy":"1","IsActive":"1"}]')
	*/

	INSERT INTO `CTS_DataCenter`.`EvidenceGroup`
				(`EvidenceGroupName`,
				`EvidenceGroupDesc`,
				`OrderNo`,
				`CreatedDate`,
				`CreatedBy`,
				`IsActive`)
	SELECT *
	FROM JSON_TABLE(ip_EvidenceGroupList,
		 "$[*]" COLUMNS(
		  EvidenceGroupName 	VARCHAR(50) 	PATH "$.EvidenceGroupName"
		, EvidenceGroupDesc		VARCHAR(200)	PATH "$.EvidenceGroupDesc" 
        , OrderNo				SMALLINT		PATH "$.OrderNo" 
        , CreatedDate			TIMESTAMP(4)	PATH "$.CreatedDate"
        , CreatedBy				INT 			PATH "$.CreatedBy" 
        , IsActive				TINYINT		 	PATH "$.IsActive" 
		 )) as tmpTable;

END$$
DELIMITER ;