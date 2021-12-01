/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator:    20211115@Aries.Nguyen
    Task:	 	Update Category when PA updated
    DBName:		CTS_DataCenter

    Revisions: 
		    - 20211115@Long.Luu: Created [#156935]

*/
/*Add source stype*/
USE CTS_DataCenter;
UPDATE CTS_DataCenter.StaticList
SET PriorityOrder = ItemID
WHERE ItemID IN (18,19,20,21);

INSERT INTO CTS_DataCenter.StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,PriorityOrder,Status,Description,CreatedDate)
VALUES(4,22, 'Classification Source Type','Classification Source Type','Update from NAP CM manually','Update Problem Account manually',22,1,'From PA',CURRENT_TIME());


/*Add column*/
USE CTS_DataCenter;
ALTER TABLE CTS_DataCenter.CustomerCategory ADD COLUMN ReasonID INT, ALGORITHM=INSTANT;
ALTER TABLE CTS_DataCenter.CustomerCategory ADD COLUMN SourceType VARCHAR(50), ALGORITHM=INSTANT;


/*Init data*/
USE CTS_DataCenter;
UPDATE CTS_DataCenter.CustomerCategory
SET ReasonID = DisplayOrder;

UPDATE CTS_DataCenter.CustomerCategory
SET SourceType = 'NAP'
WHERE (CategoryID BETWEEN 51 AND 62 OR CategoryID BETWEEN 151 AND 162) AND CategoryID != 161;

