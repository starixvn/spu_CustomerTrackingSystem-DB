/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220323@Aries.Nguyen
    Task:	 	Allow Unmark and Update on PA Management Function [Redmine ID: #170135]
    DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;
ALTER TABLE CustEvidence ADD COLUMN SourceType SMALLINT UNSIGNED COMMENT "1: NAP, 0: Others" DEFAULT 0;

USE CTS_DataCenter;
ALTER TABLE CustomerCategory 
ADD COLUMN EvidenceID_Licensee SMALLINT,
ADD COLUMN EvidenceCode_Licensee VARCHAR(10),
ADD COLUMN EvidenceID_Credit SMALLINT,
ADD COLUMN EvidenceCode_Credit VARCHAR(10),
ADD INDEX IX_CustomerCategory_ReasonID(ReasonID);



/********************Update Data CustomerCategory *************************/
USE CTS_DataCenter;
DROP TEMPORARY TABLE IF EXISTS Temp_EvidenceMapping;    
CREATE TEMPORARY TABLE Temp_EvidenceMapping(	  
			EvidenceID			BIGINT UNSIGNED
		,	EvidenceCode		VARCHAR(10) 
        ,	IsLicensee			BIT
        ,	ReasonID			SMALLINT
        ,	CategoryID			SMALLINT
        ,	PRIMARY KEY			PK_Temp_EvidenceMapping(EvidenceID,IsLicensee,ReasonID,CategoryID)
); 
    
INSERT IGNORE INTO Temp_EvidenceMapping(EvidenceID,EvidenceCode,IsLicensee,ReasonID,CategoryID)
SELECT DISTINCT evd.EvidenceID
		,	evd.EvidenceCode
        ,	CASE WHEN evd.OrderNo <= 10 THEN 0 ELSE 1 END AS IsLicensee
        ,	rs.ReasonID
        ,   rs.CategoryID
FROM CTS_DataCenter.Evidence AS evd
	INNER JOIN CTS_DataCenter.EvidenceToCategory AS etc ON etc.EvidenceID = evd.EvidenceID
    INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = etc.CategoryID
    INNER JOIN CTS_DataCenter.CustomerCategory AS rs ON rs.CategoryGroup = cat.CategoryGroup 
WHERE (evd.OrderNo BETWEEN 1 AND 20) AND rs.ReasonID <> 0;

UPDATE CTS_DataCenter.CustomerCategory AS cate
INNER JOIN Temp_EvidenceMapping AS tmp ON cate.CategoryID = tmp.CategoryID AND tmp.IsLicensee = 1
SET 	cate.EvidenceID_Licensee = tmp.EvidenceID
	,	cate.EvidenceCode_Licensee = tmp.EvidenceCode;
    
UPDATE CTS_DataCenter.CustomerCategory AS cate
INNER JOIN Temp_EvidenceMapping AS tmp ON cate.CategoryID = tmp.CategoryID AND tmp.IsLicensee = 0
SET 	cate.EvidenceID_Credit = tmp.EvidenceID
	,	cate.EvidenceCode_Credit = tmp.EvidenceCode;