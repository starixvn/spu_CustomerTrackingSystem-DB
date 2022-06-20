/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220620@Aries.Nguyen
    Task:	    Cannot mark PA (affected by uplines) correctly with First Mark [Redmine ID: #174136]
    DBName:		CTS_DataCenter
*/
USE CTS_DataCenter;
UPDATE CTS_DataCenter.CTSCustomer AS cus
INNER JOIN  CTS_Adhoc.FixData174136_IsInternal AS tmp ON cus.CTSCustID = tmp.CTSCustID
SET cus.IsInternal = tmp.IsInternal
WHERE cus.IsInternal IS NULL;

USE CTS_DataCenter;
UPDATE CTS_DataCenter.CTSCustomer AS cus
INNER JOIN  CTS_Adhoc.FixData174136_IsLicensee AS tmp ON cus.CTSCustID = tmp.CTSCustID
SET cus.IsLicensee = tmp.IsLicensee
WHERE tmp.CTSCustID BETWEEN  41011025 AND 65121176;

USE CTS_DataCenter;
UPDATE CTS_DataCenter.CTSCustomer AS cus
INNER JOIN  CTS_Adhoc.FixData174136_IsLicensee AS tmp ON cus.CTSCustID = tmp.CTSCustID
SET cus.IsLicensee = tmp.IsLicensee
WHERE tmp.CTSCustID BETWEEN  65121177  AND 65142101;



USE CTS_DataCenter;
UPDATE CTS_DataCenter.CTSCustomer AS cus
INNER JOIN  CTS_Adhoc.FixData174136_IsLicensee AS tmp ON cus.CTSCustID = tmp.CTSCustID
SET cus.IsLicensee = tmp.IsLicensee
WHERE tmp.CTSCustID BETWEEN  65162723  AND 65183301;


USE CTS_DataCenter;
UPDATE CTS_DataCenter.CTSCustomer AS cus
INNER JOIN  CTS_Adhoc.FixData174136_IsLicensee AS tmp ON cus.CTSCustID = tmp.CTSCustID
SET cus.IsLicensee = tmp.IsLicensee
WHERE tmp.CTSCustID BETWEEN  65142102  AND 65162722;


USE CTS_DataCenter;
UPDATE CTS_DataCenter.CTSCustomer AS cus
INNER JOIN  CTS_Adhoc.FixData174136_IsLicensee AS tmp ON cus.CTSCustID = tmp.CTSCustID
SET cus.IsLicensee = tmp.IsLicensee
WHERE tmp.CTSCustID BETWEEN  65183302  AND 65203923;


USE CTS_DataCenter;
UPDATE CTS_DataCenter.CTSCustomer AS cus
INNER JOIN  CTS_Adhoc.FixData174136_IsLicensee AS tmp ON cus.CTSCustID = tmp.CTSCustID
SET cus.IsLicensee = tmp.IsLicensee
WHERE tmp.CTSCustID BETWEEN  65203924  AND 65224553;


USE CTS_DataCenter;
UPDATE CTS_DataCenter.CTSCustomer AS cus
INNER JOIN  CTS_Adhoc.FixData174136_IsLicensee AS tmp ON cus.CTSCustID = tmp.CTSCustID
SET cus.IsLicensee = tmp.IsLicensee
WHERE tmp.CTSCustID BETWEEN  65224554  AND 72441308;

















