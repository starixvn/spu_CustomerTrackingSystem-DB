# 2020/05/18: Lex - Update displayname & name

/****=====Step=====****/ 
UPDATE CTS_DataCenter.StaticList
SET		ItemName = 'Linked', ItemNameDisplay = 'Linked'
WHERE	ListID = 3
AND		ItemID = 1;

UPDATE CTS_DataCenter.StaticList
SET		ItemName = 'Unlinked', ItemNameDisplay = 'Unlinked'
WHERE	ListID = 3
AND		ItemID = 2
/*====================*/