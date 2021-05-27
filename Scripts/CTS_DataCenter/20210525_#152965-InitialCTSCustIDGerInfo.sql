/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20210525@Irena.Vo
	Task: 	 152965 - Initial & Update Schema & Add Index for CustID -> CTSCustID
	DB: 	 CTS_DataCenter
    
    Revisions: 
	-	[20210525@Irena.Vo]: Initial & Update Schema & Add Index for CustID -> CTSCustID.
*/
USE CTS_DataCenter;

/* Initial CustID to CTSCustID for table TaggingExclusion */ 
UPDATE TaggingExclusion AS te
	INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = te.CustID AND cust.CustSubID = 0
SET te.CustID = cust.CTSCustID;

/* Update Column Name for table TaggingExclusion */
ALTER TABLE TaggingExclusion
CHANGE COLUMN CustID CTSCustID BIGINT UNSIGNED, ALGORITHM=INPLACE, LOCK=NONE;

/* Initial CustID to CTSCustID for table PinCustomerCategory */ 
UPDATE PinCustomerCategory AS p
	INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = p.CustID AND cust.CustSubID = 0
SET p.CustID = cust.CTSCustID;

/* Update Column Name for table PinCustomerCategory */
ALTER TABLE PinCustomerCategory
CHANGE COLUMN CustID CTSCustID BIGINT UNSIGNED, ALGORITHM=INPLACE, LOCK=NONE;

/* Add Index CTSCustID for table ProbationAccountMonitor */
ALTER TABLE ProbationAccountMonitor
ADD INDEX IX_ProbationAccountMonitor_CTSCustID(CTSCustID), ALGORITHM=INPLACE, LOCK=NONE;