/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20240617@Thomas.Nguyen
Task:	 	alter tables
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20240617@Thomas.Nguyen: Created [Redmine ID: #205317]
Reviewer:
*/

USE CTS_DataCenter;


/*CTSCustomerClassification*/
ALTER TABLE CTSCustomerClassification
RENAME COLUMN SportGroupID TO ParentID;

ALTER TABLE CTSCustomerClassification
MODIFY COLUMN ParentID INT UNSIGNED;

ALTER TABLE CTSCustomerClassification
MODIFY COLUMN CategoryID INT UNSIGNED;

ALTER TABLE CTSCustomerClassification
ADD IsAffectToDownline BIT(1);

ALTER TABLE CTSCustomerClassification
ADD RoleID TINYINT;

ALTER TABLE CTSCustomerClassification
RENAME COLUMN IsDirect TO IsMarkedDirectly;

/*CTSCustomerClassification_History*/
ALTER TABLE CTSCustomerClassification_History
RENAME COLUMN SportGroupID TO ParentID;

ALTER TABLE CTSCustomerClassification_History
MODIFY COLUMN ParentID INT UNSIGNED;

ALTER TABLE CTSCustomerClassification_History
MODIFY COLUMN CategoryID INT UNSIGNED;

ALTER TABLE CTSCustomerClassification_History
RENAME COLUMN FromCategoryID TO OldCategoryID;

ALTER TABLE CTSCustomerClassification_History
MODIFY COLUMN OldCategoryID INT UNSIGNED;

ALTER TABLE CTSCustomerClassification_History
RENAME COLUMN ToCategoryID TO DWCategoryID;

ALTER TABLE CTSCustomerClassification_History
MODIFY COLUMN DWCategoryID INT UNSIGNED;

ALTER TABLE CTSCustomerClassification_History
RENAME COLUMN IsDirect TO IsMarkedDirectly;

/*CTSCustomerClassification_Log*/
ALTER TABLE CTSCustomerClassification_Log
RENAME COLUMN SportGroupID TO ParentID;

ALTER TABLE CTSCustomerClassification_Log
MODIFY COLUMN ParentID INT UNSIGNED;

ALTER TABLE CTSCustomerClassification_Log
MODIFY COLUMN CategoryID INT UNSIGNED;

ALTER TABLE CTSCustomerClassification_Log
RENAME COLUMN FromCategoryID TO OldCategoryID;

ALTER TABLE CTSCustomerClassification_Log
MODIFY COLUMN OldCategoryID INT UNSIGNED;

ALTER TABLE CTSCustomerClassification_Log
RENAME COLUMN ToCategoryID TO DWCategoryID;

ALTER TABLE CTSCustomerClassification_Log
MODIFY COLUMN DWCategoryID INT UNSIGNED;

ALTER TABLE CTSCustomerClassification_Log
RENAME COLUMN IsDirect TO IsMarkedDirectly;

/*CTSCustomerClassificationQueue*/
ALTER TABLE CTSCustomerClassificationQueue
RENAME COLUMN CategoryGroup TO CategoryGroupID;

ALTER TABLE CTSCustomerClassificationQueue
RENAME COLUMN IsDirect TO IsMarkedDirectly;

ALTER TABLE CTSCustomerClassificationQueue
MODIFY COLUMN CategoryID INT UNSIGNED;