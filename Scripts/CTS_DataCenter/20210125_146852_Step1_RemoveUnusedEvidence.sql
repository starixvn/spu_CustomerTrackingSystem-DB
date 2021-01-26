/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20200121@Casey.Huynh
	Task: 	 Remove Unused Evidence
	DB: 	 CTS_DataCenter
    
    Revisions: 
	- 20200125@Casey.Huynh: Remove Unused Evidence [RedmineID: 146852]
*/
/*GET Unused Evidence List from CTS_DataCenter.CustEvidence*/
DROP TEMPORARY TABLE IF EXISTS Temp_RemoveEvidence;
CREATE TEMPORARY TABLE Temp_RemoveEvidence
(
	EvidenceID SMALLINT	PRIMARY KEY
);
INSERT INTO Temp_RemoveEvidence(EvidenceID)
SELECT	evd.EvidenceID
FROM	CTS_DataCenter.Evidence AS evd
WHERE	evd.EvidenceGroupID != 6 ;

/*DETELE CTS_DataCenter.CustEvidence*/ /*54*/
DELETE		del
FROM 		CTS_DataCenter.CustEvidence AS del
	INNER JOIN	Temp_RemoveEvidence AS tmpRev ON tmpRev.EvidenceID = del.EvidenceID;

/*DETELE CTS_DataCenter.CustRetractEvidence*/ /*10*/
DELETE		del
FROM 		CTS_DataCenter.CustRetractEvidence AS del
	INNER JOIN	Temp_RemoveEvidence AS tmpRev ON tmpRev.EvidenceID = del.EvidenceID;

/*DETELE CTS_DataCenter.Evidence*/ /*54*/
DELETE		del
FROM 		CTS_DataCenter.Evidence AS del
	INNER JOIN	Temp_RemoveEvidence AS tmpRev ON tmpRev.EvidenceID = del.EvidenceID;

/*DETELE CTS_DataCenter.EvidenceGroup*/ /*7*/
DELETE		evg
FROM 		CTS_DataCenter.EvidenceGroup AS evg
WHERE		evg.EvidenceGroupID != 6 ;
