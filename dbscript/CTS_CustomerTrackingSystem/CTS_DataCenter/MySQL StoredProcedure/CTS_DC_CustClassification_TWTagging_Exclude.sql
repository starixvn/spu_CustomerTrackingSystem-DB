/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250328@Logan.Nguyen
Task:	 	Customer Classification - TW - Adjust criteria for New_Good_Normal - GB_High Rejected [Redmine ID: 202503]
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250328@Logan.Nguyen: Created [Redmine ID: #202503]

Reviewer:
*/


DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE CTS_DC_CustClassification_TWTagging_Exclude (
    IN ip_json JSON
)
    SQL SECURITY INVOKER
BEGIN
    /*
        Created:    20250328@Logan

        Task:       Customer Classification - TW - Adjust criteria for New_Good_Normal - GB_High Rejected [Redmine ID: 202503]
        DB:         CTS_DataCenter

        Revisions:
            - 20250328@Logan: Initial create

        Param's Explanation:
            ip_json : JSON array list CustID, CategoryID, TaggingID

        Sample Call:
            CALL CTS_DataCenter.CTS_DC_CustClassification_TWTagging_Exclude(
                '[{"CustID":1,"CategoryID":40100,"TaggingID":101},{"CustID":2,"CategoryID":40200,"TaggingID":102}]'
            );
    */


    DROP TEMPORARY TABLE IF EXISTS Temp_Input;

    CREATE TEMPORARY TABLE Temp_Input (
		CustID INT,
		CategoryID INT,
		TaggingID INT,
		PRIMARY KEY (
			CustID,
			TaggingID
		)
	);



    INSERT INTO Temp_Input (CustID, CategoryID, TaggingID)
    SELECT 
        js.CustID,
        js.CategoryID,
        js.TaggingID
    FROM JSON_TABLE(
        ip_json,
        "$[*]" COLUMNS (
            CustID     INT UNSIGNED PATH "$.CustID",
            CategoryID INT          PATH "$.CategoryID",
            TaggingID  INT UNSIGNED PATH "$.TaggingID"
        )
    ) AS js;

    SELECT 
        ti.CustID, ti.TaggingID
    FROM Temp_Input AS ti
    WHERE ti.CategoryID IS NOT NULL
      AND ti.CategoryID IN (40100, 40200, 40300)
      AND NOT EXISTS (
        SELECT 1 
        FROM Customer_FirstTWTaggingCC AS c
        WHERE c.CustID = ti.CustID 
          AND c.TWTaggingID = ti.TaggingID
    );


    DROP TEMPORARY TABLE IF EXISTS Temp_Input;

END$$

DELIMITER ;
