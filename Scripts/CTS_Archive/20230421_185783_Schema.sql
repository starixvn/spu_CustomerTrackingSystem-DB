/*<info serverAlias="CTSMain-CTS_Archive" databaseType="2"></info>*/
/*
	20220408@Casey.Huynh: Add AssociationGroupByAI [Redmine ID: #171222]
	Task: Add table schema.
	DB: CTS_Archive
*/
USE CTS_Archive;

ALTER TABLE AssociationByIP_Arc
		ADD AssType SMALLINT UNSIGNED AFTER ID
	,	DROP INDEX UX_AssociationByAI_FromCustIDToCustID
    ,	DROP INDEX UX_AssociationByAI_ToCustIDFromCustID
    ,	ADD UNIQUE KEY UX_AssociationByIP_FromCustIDToCustID (FromCustID,ToCustID,AssType);


