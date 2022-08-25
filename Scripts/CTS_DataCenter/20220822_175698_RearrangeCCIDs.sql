/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20220822@Long.Luu
	Task: 	 Update CC's IDs  [Redmine ID: #175698]
	DB: 	 CTS_DataCenter
    
    Revisions: 
	-	20220822@Long.Luu: created [Redmine ID: #175698]
*/

USE CTS_DataCenter;
ALTER TABLE CustomerCategory
ADD COLUMN OldCustomerClass SMALLINT UNSIGNED;

SET SQL_SAFE_UPDATES = 0;
UPDATE CustomerCategory
SET OldCustomerClass = CustomerClass;

UPDATE CustomerCategory SET CustomerClass = 201 WHERE CustomerClass =1;
UPDATE CustomerCategory SET CustomerClass = 2101 WHERE CustomerClass =111;
UPDATE CustomerCategory SET CustomerClass = 2201 WHERE CustomerClass =112;
UPDATE CustomerCategory SET CustomerClass = 2001 WHERE CustomerClass =113;
UPDATE CustomerCategory SET CustomerClass = 202 WHERE CustomerClass =2;
UPDATE CustomerCategory SET CustomerClass = 2102 WHERE CustomerClass =121;
UPDATE CustomerCategory SET CustomerClass = 2202 WHERE CustomerClass =122;
UPDATE CustomerCategory SET CustomerClass = 2002 WHERE CustomerClass =123;
UPDATE CustomerCategory SET CustomerClass = 200 WHERE CustomerClass =3;
UPDATE CustomerCategory SET CustomerClass = 2100 WHERE CustomerClass =31;
UPDATE CustomerCategory SET CustomerClass = 2200 WHERE CustomerClass =32;
UPDATE CustomerCategory SET CustomerClass = 2000 WHERE CustomerClass =33;
UPDATE CustomerCategory SET CustomerClass = 2500 WHERE CustomerClass =43;
UPDATE CustomerCategory SET CustomerClass = 2503 WHERE CustomerClass =45;
UPDATE CustomerCategory SET CustomerClass = 2504 WHERE CustomerClass =46;
UPDATE CustomerCategory SET CustomerClass = 2505 WHERE CustomerClass =47;
UPDATE CustomerCategory SET CustomerClass = 203 WHERE CustomerClass =5;
UPDATE CustomerCategory SET CustomerClass = 2103 WHERE CustomerClass =51;
UPDATE CustomerCategory SET CustomerClass = 2203 WHERE CustomerClass =52;
UPDATE CustomerCategory SET CustomerClass = 2003 WHERE CustomerClass =53;
UPDATE CustomerCategory SET CustomerClass = 2303 WHERE CustomerClass =57;
UPDATE CustomerCategory SET CustomerClass = 2403 WHERE CustomerClass =58;
UPDATE CustomerCategory SET CustomerClass = 204 WHERE CustomerClass =6;
UPDATE CustomerCategory SET CustomerClass = 2104 WHERE CustomerClass =61;
UPDATE CustomerCategory SET CustomerClass = 2204 WHERE CustomerClass =62;
UPDATE CustomerCategory SET CustomerClass = 2004 WHERE CustomerClass =63;
UPDATE CustomerCategory SET CustomerClass = 2304 WHERE CustomerClass =67;
UPDATE CustomerCategory SET CustomerClass = 2404 WHERE CustomerClass =68;
UPDATE CustomerCategory SET CustomerClass = 205 WHERE CustomerClass =7;
UPDATE CustomerCategory SET CustomerClass = 2105 WHERE CustomerClass =71;
UPDATE CustomerCategory SET CustomerClass = 2205 WHERE CustomerClass =72;
UPDATE CustomerCategory SET CustomerClass = 2005 WHERE CustomerClass =73;
UPDATE CustomerCategory SET CustomerClass = 2305 WHERE CustomerClass =77;
UPDATE CustomerCategory SET CustomerClass = 2405 WHERE CustomerClass =78;
UPDATE CustomerCategory SET CustomerClass = 301 WHERE CustomerClass =8;
UPDATE CustomerCategory SET CustomerClass = 3001 WHERE CustomerClass =86;
UPDATE CustomerCategory SET CustomerClass = 302 WHERE CustomerClass =9;
UPDATE CustomerCategory SET CustomerClass = 3002 WHERE CustomerClass =96;
UPDATE CustomerCategory SET CustomerClass = 302 WHERE CustomerClass =9;
UPDATE CustomerCategory SET CustomerClass = 3002 WHERE CustomerClass =96;
UPDATE CustomerCategory SET CustomerClass = 303 WHERE CustomerClass =10;
UPDATE CustomerCategory SET CustomerClass = 3003 WHERE CustomerClass =106;
UPDATE CustomerCategory SET CustomerClass = 303 WHERE CustomerClass =10;
UPDATE CustomerCategory SET CustomerClass = 3003 WHERE CustomerClass =106;
UPDATE CustomerCategory SET CustomerClass = 303 WHERE CustomerClass =10;
UPDATE CustomerCategory SET CustomerClass = 3003 WHERE CustomerClass =106;
UPDATE CustomerCategory SET CustomerClass = 304 WHERE CustomerClass =12;
UPDATE CustomerCategory SET CustomerClass = 3004 WHERE CustomerClass =126;
UPDATE CustomerCategory SET CustomerClass = 300 WHERE CustomerClass =131;
UPDATE CustomerCategory SET CustomerClass = 3000 WHERE CustomerClass =132;
UPDATE CustomerCategory SET CustomerClass = 401 WHERE CustomerClass =14;
UPDATE CustomerCategory SET CustomerClass = 400 WHERE CustomerClass =99;
UPDATE CustomerCategory SET CustomerClass = 4000 WHERE CustomerClass =101;
UPDATE CustomerCategory SET CustomerClass = 999 WHERE CustomerClass =100;
UPDATE CustomerCategory SET CustomerClass = 901 WHERE CustomerClass =1001;
UPDATE CustomerCategory SET CustomerClass = 902 WHERE CustomerClass =1002;

UPDATE SpecialCustomerClass SET CustomerClass = 201 WHERE CustomerClass =1;
UPDATE SpecialCustomerClass SET CustomerClass = 2101 WHERE CustomerClass =111;
UPDATE SpecialCustomerClass SET CustomerClass = 2201 WHERE CustomerClass =112;
UPDATE SpecialCustomerClass SET CustomerClass = 2001 WHERE CustomerClass =113;
UPDATE SpecialCustomerClass SET CustomerClass = 202 WHERE CustomerClass =2;
UPDATE SpecialCustomerClass SET CustomerClass = 2102 WHERE CustomerClass =121;
UPDATE SpecialCustomerClass SET CustomerClass = 2202 WHERE CustomerClass =122;
UPDATE SpecialCustomerClass SET CustomerClass = 2002 WHERE CustomerClass =123;
UPDATE SpecialCustomerClass SET CustomerClass = 200 WHERE CustomerClass =3;
UPDATE SpecialCustomerClass SET CustomerClass = 2100 WHERE CustomerClass =31;
UPDATE SpecialCustomerClass SET CustomerClass = 2200 WHERE CustomerClass =32;
UPDATE SpecialCustomerClass SET CustomerClass = 2000 WHERE CustomerClass =33;
UPDATE SpecialCustomerClass SET CustomerClass = 2500 WHERE CustomerClass =43;
UPDATE SpecialCustomerClass SET CustomerClass = 2503 WHERE CustomerClass =45;
UPDATE SpecialCustomerClass SET CustomerClass = 2504 WHERE CustomerClass =46;
UPDATE SpecialCustomerClass SET CustomerClass = 2505 WHERE CustomerClass =47;
UPDATE SpecialCustomerClass SET CustomerClass = 203 WHERE CustomerClass =5;
UPDATE SpecialCustomerClass SET CustomerClass = 2103 WHERE CustomerClass =51;
UPDATE SpecialCustomerClass SET CustomerClass = 2203 WHERE CustomerClass =52;
UPDATE SpecialCustomerClass SET CustomerClass = 2003 WHERE CustomerClass =53;
UPDATE SpecialCustomerClass SET CustomerClass = 2303 WHERE CustomerClass =57;
UPDATE SpecialCustomerClass SET CustomerClass = 2403 WHERE CustomerClass =58;
UPDATE SpecialCustomerClass SET CustomerClass = 204 WHERE CustomerClass =6;
UPDATE SpecialCustomerClass SET CustomerClass = 2104 WHERE CustomerClass =61;
UPDATE SpecialCustomerClass SET CustomerClass = 2204 WHERE CustomerClass =62;
UPDATE SpecialCustomerClass SET CustomerClass = 2004 WHERE CustomerClass =63;
UPDATE SpecialCustomerClass SET CustomerClass = 2304 WHERE CustomerClass =67;
UPDATE SpecialCustomerClass SET CustomerClass = 2404 WHERE CustomerClass =68;
UPDATE SpecialCustomerClass SET CustomerClass = 205 WHERE CustomerClass =7;
UPDATE SpecialCustomerClass SET CustomerClass = 2105 WHERE CustomerClass =71;
UPDATE SpecialCustomerClass SET CustomerClass = 2205 WHERE CustomerClass =72;
UPDATE SpecialCustomerClass SET CustomerClass = 2005 WHERE CustomerClass =73;
UPDATE SpecialCustomerClass SET CustomerClass = 2305 WHERE CustomerClass =77;
UPDATE SpecialCustomerClass SET CustomerClass = 2405 WHERE CustomerClass =78;
UPDATE SpecialCustomerClass SET CustomerClass = 301 WHERE CustomerClass =8;
UPDATE SpecialCustomerClass SET CustomerClass = 3001 WHERE CustomerClass =86;
UPDATE SpecialCustomerClass SET CustomerClass = 302 WHERE CustomerClass =9;
UPDATE SpecialCustomerClass SET CustomerClass = 3002 WHERE CustomerClass =96;
UPDATE SpecialCustomerClass SET CustomerClass = 302 WHERE CustomerClass =9;
UPDATE SpecialCustomerClass SET CustomerClass = 3002 WHERE CustomerClass =96;
UPDATE SpecialCustomerClass SET CustomerClass = 303 WHERE CustomerClass =10;
UPDATE SpecialCustomerClass SET CustomerClass = 3003 WHERE CustomerClass =106;
UPDATE SpecialCustomerClass SET CustomerClass = 303 WHERE CustomerClass =10;
UPDATE SpecialCustomerClass SET CustomerClass = 3003 WHERE CustomerClass =106;
UPDATE SpecialCustomerClass SET CustomerClass = 303 WHERE CustomerClass =10;
UPDATE SpecialCustomerClass SET CustomerClass = 3003 WHERE CustomerClass =106;
UPDATE SpecialCustomerClass SET CustomerClass = 304 WHERE CustomerClass =12;
UPDATE SpecialCustomerClass SET CustomerClass = 3004 WHERE CustomerClass =126;
UPDATE SpecialCustomerClass SET CustomerClass = 300 WHERE CustomerClass =131;
UPDATE SpecialCustomerClass SET CustomerClass = 3000 WHERE CustomerClass =132;
UPDATE SpecialCustomerClass SET CustomerClass = 401 WHERE CustomerClass =14;
UPDATE SpecialCustomerClass SET CustomerClass = 400 WHERE CustomerClass =99;
UPDATE SpecialCustomerClass SET CustomerClass = 4000 WHERE CustomerClass =101;
UPDATE SpecialCustomerClass SET CustomerClass = 999 WHERE CustomerClass =100;
UPDATE SpecialCustomerClass SET CustomerClass = 901 WHERE CustomerClass =1001;
UPDATE SpecialCustomerClass SET CustomerClass = 902 WHERE CustomerClass =1002;