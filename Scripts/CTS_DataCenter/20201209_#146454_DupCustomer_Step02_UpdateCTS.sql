/************************ STEP02 UPDATE DATA CTS_DATACENTER****************************************/
USE CTS_DataCenter;

/*== STEP02_01  UPDATE CTS_DataCenter.CusDCSAccount #36=========*/
SELECT 		'ESTIMATE',  COUNT(1) #36
FROM		CTS_DataCenter.CustDCSAccount		AS cda
INNER JOIN	CTS_Adhoc.Iss145271_CTSCustomerDup  AS dup
			ON cda.CTSCustID = dup.CTSCustID
WHERE		dup.CorrectedCTSCustID IS NOT NULL;

UPDATE 		CTS_DataCenter.CustDCSAccount		AS cda
INNER JOIN	CTS_Adhoc.Iss145271_CTSCustomerDup  AS dup
			ON cda.CTSCustID = dup.CTSCustID
SET 		cda.CTSCustID = dup.CorrectedCTSCustID
WHERE		dup.CorrectedCTSCustID IS NOT NULL; 

/*== STEP02_02  REMOVE CTS_DataCenter.CTSCustomer #41=========*/
SELECT 		'ESTIMATE',  COUNT(1) #41
FROM		CTS_DataCenter.CTSCustomer AS cus
INNER JOIN 	CTS_Adhoc.Iss145271_CTSCustomerDup  AS dup
			ON dup.CTSCustID = cus.CTSCustID 
WHERE 		dup.CorrectedCTSCustID IS NOT NULL;

DELETE 		cus
FROM		CTS_DataCenter.CTSCustomer AS cus
INNER JOIN 	CTS_Adhoc.Iss145271_CTSCustomerDup  AS dup
			ON dup.CTSCustID = cus.CTSCustID 
WHERE 		dup.CorrectedCTSCustID IS NOT NULL; 

UPDATE		CTS_DataCenter.CTSCustomer AS cus
INNER JOIN 	( SELECT dup.CTSCustID, MAX(acc.LastLoginTime) AS LastLoginTime
				FROM	CTS_Adhoc.Iss145271_CTSCustomerDup  AS dup
				INNER JOIN	CTS_DataCenter.CustDCSAccount		AS cda
						ON dup.CTSCustID = cda.CTSCustID
                INNER JOIN	DCS_DataCenter.Account		AS acc
						ON cda.AccountID = acc.AccountID         
				WHERE 		dup.CorrectedCTSCustID IS NULL
                GROUP BY 	dup.CTSCustID	) AS temp
			ON cus.CTSCustID = temp.CTSCustID
SET			cus.LastLoginTime = temp.LastLoginTime; 

/*== STEP02_03  UPDATE CTS_DataCenter.AssociationByDevice #392=========*/
SELECT aCTSCustID, DCSDeviceID
FROM 	(SELECT 		IFNULL(dup.CorrectedCTSCustID,dup.CTSCustID) AS aCTSCustID, cda.*
		FROM		CTS_DataCenter.AssociationByDevice		AS cda
		INNER JOIN	CTS_Adhoc.Iss145271_CTSCustomerDup  AS dup
					ON cda.CTSCustID = dup.CTSCustID) AS a
GROUP BY aCTSCustID, DCSDeviceID
HAVING 		COUNT(1) > 1; #==> expected NULL	

SELECT 		'ESTIMATE',  COUNT(1) #392
FROM		CTS_DataCenter.AssociationByDevice		AS cda
INNER JOIN	CTS_Adhoc.Iss145271_CTSCustomerDup  AS dup
			ON cda.CTSCustID = dup.CTSCustID
WHERE		dup.CorrectedCTSCustID IS NOT NULL; 

UPDATE 		CTS_DataCenter.AssociationByDevice		AS cda
INNER JOIN	CTS_Adhoc.Iss145271_CTSCustomerDup  AS dup
			ON cda.CTSCustID = dup.CTSCustID
SET 		cda.CTSCustID = dup.CorrectedCTSCustID
WHERE		dup.CorrectedCTSCustID IS NOT NULL; 

/*== STEP02_04  UPDATE CTS_DataCenter.AssociationByDevice #392=========*/
SELECT 		'ESTIMATE',   COUNT(1) #10
FROM         CTS_DataCenter.CustEvidence        AS cus
INNER JOIN   CTS_Adhoc.Iss145271_CTSCustomerDup  AS dup
				ON cus.CTSCustID = dup.CTSCustID OR cus.FromCustID = dup.CTSCustID
WHERE        dup.CorrectedCTSCustID IS NOT NULL;

UPDATE 		 CTS_DataCenter.CustEvidence        AS cus
INNER JOIN   CTS_Adhoc.Iss145271_CTSCustomerDup  AS dup
			 ON cus.CTSCustID = dup.CTSCustID 
SET 		 cus.CTSCustID = dup.CorrectedCTSCustID
WHERE        dup.CorrectedCTSCustID IS NOT NULL;
