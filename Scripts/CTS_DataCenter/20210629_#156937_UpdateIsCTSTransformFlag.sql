/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20210629@Casey.Huynh
	Task:		Update IsCTSTransformed Flag if less than -1 [Redmine ID: #156937] 
	DB:			DCS_DataCenter
*/

USE DCS_DataCenter;

#Step 1: Association, update IsCTSTransformed < -1 to 0; 
UPDATE	DCS_DataCenter.Association AS ass
SET		ass.IsCTSTransformed = 0
WHERE	ass.IsCTSTransformed < -1; #78756

#Step 2: Association Of Account, Update to -1; 
UPDATE	DCS_DataCenter.Association AS ass
	INNER JOIN DCS_DataCenter.Account AS acc ON ass.AccountID = acc.AccountID
SET		ass.IsCTSTransformed = -1
WHERE	ass.IsCTSTransformed < -1; #337646

#Step 3:  Account, Update to 0; 
UPDATE	DCS_DataCenter.Account AS acc
SET 	acc.IsCTSTransformed = 0
WHERE 	acc.IsCTSTransformed < -1; #48284