/*
Creator: 20190117@Harvey Nguyen
Task:	 	CTS_Schema
Server:  	Slave
DBName:		CTS_DataCenter

Revisions: 
    
Reviewer:
	#1.  
*/

ALTER TABLE		CTS_DataCenter.CustEvidence
DROP			IsRetracted;

# ===================================================
CREATE TABLE IF NOT EXISTS CTS_DataCenter.CustRetractEvidence
(
	  CTSCustID			BIGINT		NOT NULL
    , EvidenceID		SMALLINT    NOT NULL
    , CreatedDate		DATETIME
    
    , PRIMARY KEY PK_CustRetractEvidence_CTSCustID_EvidenceID(CTSCustID,EvidenceID)
) ENGINE=INNODB;
