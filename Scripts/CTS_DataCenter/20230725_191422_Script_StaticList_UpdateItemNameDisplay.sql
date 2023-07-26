/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20230725@Victoria.Le
	Task :	Correct ItemNameDisplay from table StaticList
	DB:			
	
	Description: 

	Revisions:	
		- 20230725@Victoria.Le: 	Initial Writing [Redmine ID: #191422]
		
	Param's Explanation (filtered by):

	Example:
*/
USE CTS_DataCenter;

UPDATE StaticList AS s
SET s.ItemNameDisplay = CASE 	WHEN s.ItemID = 18 THEN 'Quarter 1 Moneyline'
								WHEN s.ItemID = 19 THEN 'Quarter 2 Moneyline'
								WHEN s.ItemID = 20 THEN 'Quarter 3 Moneyline'
								WHEN s.ItemID = 21 THEN 'Quarter 4 Moneyline'
						END
WHERE s.ListID = 18 AND s.ItemID IN (18,19,20,21)
;