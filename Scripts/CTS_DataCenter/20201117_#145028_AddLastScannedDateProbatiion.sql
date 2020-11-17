/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Created: 20201117@Irena.Vo
Task: Add LastScannedDate column
DB: CTS_DataCenter
*/
ALTER TABLE CTS_DataCenter.ProbationAccountMonitor
ADD COLUMN LastScannedDate DATE, ALGORITHM=INSTANT, LOCK=NONE;

ALTER TABLE CTS_DataCenter.ProbationAccountMonitor
ADD INDEX IX_ProbationAccountMonitor_LastScannedDate(LastScannedDate), ALGORITHM=INPLACE, LOCK=NONE;