/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20240809@Victoria.Le
Task:	 	Initial data
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20240809@Victoria.Le: 		Initial Writing - Phase 1-b: Initial Data [Redmine ID: #205317]
										1	Clean up data - history which are older than 30 days
										2	Update data incorrect
										3	Stop event to check association detection from MMHedging
								
*/

/* 1	Clean up data - history which are older than 30 days */
DROP TEMPORARY TABLE IF EXISTS Temp_History;    
CREATE TEMPORARY TABLE Temp_History(	  
		ID					BIGINT UNSIGNED	PRIMARY KEY
);

INSERT INTO Temp_History (ID)
WITH cte_ALL AS
(
	SELECT h.CTSCustID, COUNT(1) as TotalRows
	FROM CTSCustomerClassification_History as h
	WHERE h.IsDataChanged = 1
	GROUP BY h.CTSCustID
), cte_KEEP as
(
	SELECT h.CTSCustID, MIN(h.ID) AS KeepID
	FROM CTSCustomerClassification_History as h
		INNER JOIN cte_ALL AS c ON c.CTSCustID = h.CTSCustID
	WHERE c.TotalRows >= 1
		AND h.InsertDate >= DATE_SUB(CURRENT_DATE(), INTERVAL 29 DAY)
		AND h.IsDataChanged = 1
	GROUP BY h.CTSCustID
)
SELECT h.ID
FROM CTSCustomerClassification_History as h
	INNER JOIN cte_KEEP AS c ON h.CTSCustID = c.CTSCustID AND h.ID < c.KeepID
;

SELECT COUNT(1) FROM Temp_History;

DELETE h
FROM CTSCustomerClassification_History as h
	INNER JOIN Temp_History AS temp ON temp.ID = h.ID

/* 2	Update data incorrect */

--  CategoryID in (0,51,151,160) - Abnormal + Others
DELETE FROM CTSCustomerClassification
WHERE CategoryID in (0,51,151,160);

-- MARK/UNMARK SPECIAL CC
UPDATE CTSCustomerClassification_History as h
SET h.IsDataChanged = 1
WHERE h.IsDataChanged = 0
	AND h.SourceTypeID IN (10,12)
;


/* 3	Stop event to check association detection from MMHedging */

TRUNCATE TABLE MatchMonitor_AssociationDetection_Monitor;

ALTER EVENT EV_CTS_DC_MatchMonitor_Wrapper
	DISABLE;