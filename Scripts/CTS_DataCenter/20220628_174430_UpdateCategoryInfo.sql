/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220628@Aries.Nguyen
    Task:	    [CTS] Update robot classification rule [Redmine ID: #174430]
    DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;
UPDATE CTS_DataCenter.CustomerCategory 
SET CategoryName = 'Robot User'
, 	CategorySpec = 'Robot User'
, 	CategoryNameCN = '机械玩家'
, 	CustomerClassException = 131
, 	RelevantCategoryID = 164
WHERE CategoryID = 163;

UPDATE CTS_DataCenter.CustomerCategory 
SET CategoryName = 'Robot User (Losing)'
, 	CategorySpec = 'Robot User (Losing)'
, 	CategoryNameCN = '机械玩家 (输钱)'
, 	CustomerClassException = 132
, 	RelevantCategoryID = 163
, 	ABIDangerLevelException_Licensee = 32
, 	ABIDangerLevelException_Credit = 32
,   IsProbation = 1 
,   IsPAProbation = 1
 WHERE CategoryID = 164;
