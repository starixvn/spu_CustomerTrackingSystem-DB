/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_Adhoc_CleanABI_CTSCustomer`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Adhoc_CleanABI_CTSCustomer`()
	SQL SECURITY INVOKER
sp: BEGIN 
/*
    Created: 20250404@Thomas.Nguyen
	Task: Correct ABI for customers
	DB: CTSMain-CTS_DataCenter

	Example:
			- CALL CTS_DataCenter.CTS_DC_Adhoc_CleanABI_CTSCustomer();

	Revisions: 
			- 20250404@Thomas.Nguyen:	Created[Redmine ID: #223426]
*/

DECLARE lv_StartRow 			INT;
DECLARE lv_StopRow 				INT;
DECLARE lv_MaxRow 				INT;  /* the total row of your data */
DECLARE lv_Threshold 			INT;  /* the number of each batch */
DECLARE lv_UpdatedCount			INT DEFAULT 0;
DECLARE lv_TotalRowsUpdated		INT DEFAULT 0;

DROP TEMPORARY TABLE IF EXISTS Tmp_CustNeedToUpdateABI;
CREATE TEMPORARY TABLE Tmp_CustNeedToUpdateABI(
		ID INT AUTO_INCREMENT PRIMARY KEY
	,	CustID BIGINT UNSIGNED
);

INSERT INTO Tmp_CustNeedToUpdateABI (CustID)
SELECT CustID
FROM CustNeedToUpdateABI;

CREATE INDEX IX_CustNeedToUpdateABI_CustID ON Tmp_CustNeedToUpdateABI (CustID);
		
SELECT MAX(ID) INTO lv_MaxRow FROM Tmp_CustNeedToUpdateABI;
SET lv_Threshold = 2000;

IF lv_Threshold >= lv_MaxRow THEN
	SET lv_Threshold = lv_MaxRow;
END IF;

/* SET for first batch */
SET lv_StartRow = 1;
SET lv_StopRow = lv_Threshold;

WHILE (lv_MaxRow IS NOT NULL) DO
		SET lv_UpdatedCount = 0;

		UPDATE CTS_DataCenter.CTSCustomer_thomas AS cus 
			INNER JOIN Tmp_CustNeedToUpdateABI AS tmp ON cus.CustID = tmp.CustID
		SET cus.Danger2 = 0
		WHERE tmp.ID BETWEEN lv_StartRow AND lv_StopRow;
		
        SET lv_UpdatedCount = FOUND_ROWS();
        SET lv_TotalRowsUpdated = lv_TotalRowsUpdated + lv_UpdatedCount;
        
		IF lv_StopRow = lv_MaxRow THEN 
			SELECT	lv_MaxRow AS TotalRows
				,	lv_TotalRowsUpdated AS TotalRowsUpdated;
            LEAVE sp; 
		END IF;

		SET lv_StartRow = lv_StopRow + 1;
		SET lv_StopRow = lv_StopRow + lv_Threshold;
		IF lv_StopRow >= lv_MaxRow	THEN
			SET lv_StopRow = lv_MaxRow;
		END IF;
END WHILE;

END$$
DELIMITER ;