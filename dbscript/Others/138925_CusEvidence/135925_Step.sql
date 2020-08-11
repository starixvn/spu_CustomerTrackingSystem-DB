/***Step01: Move data to New table ******/
CALL CTS_Adhoc.CS138925_GetCusEvidence_New();

/***Step02: UM*/
#2.1: Remove Evidence
DELETE		 	ed
FROM 			CTS_Adhoc.CS138925_CustEvidence_BK	AS ed
LEFT JOIN  		CTS_DataCenter.CustEvidence AS cus
				ON ed.CustEvidID = cus.CustEvidID
WHERE			cus.CustEvidID IS NULL;

#2.2: Copy Evidence: GAP
CALL CTS_Adhoc.CS138925_GetCusEvidence_NewGAP();

#2.3: Rename Table 

Rename Table "CTS_DataCenter.CustEvidence" to "CTS_DataCenter.CustEvidence_BK"

Rename Table "CTS_DataCenter.CS138925_CustEvidence_New" to "CTS_DataCenter.CustEvidence"
