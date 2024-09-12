/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20240809@Victoria.Le
Task:	 	Initial data
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20240809@Victoria.Le: 		Initial Writing - Mssing Initial Data [Redmine ID: #205317]
										
*/

USE CTS_DataCenter;

/************************* I. CustClassification_BySport ******************************/
/*
-- DONE 16/08/2024
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 10000,1,201,21938,4633210);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 10000,1,202,2344,2094457);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 10000,2,201,3562,2305009);
*/


/************************* II. ArchiveCustomer_CTSCustomer ******************************/
/* 1. clean data SubscriberID: TerminatedDate is not null AND ParentID is not null - Expected: 3029 rows*/
WITH CTE AS
(
	select ar.ID
	from ArchiveCustomer_CTSCustomer as ar
		inner join CTS_Admin.Subscriber as sub on sub.SubscriberID = ar.SubscriberID
	where sub.TerminatedDate is not null AND ar.ParentID is not null
)
UPDATE ArchiveCustomer_CTSCustomer as ar
	INNER JOIN CTE AS c on c.ID = ar.ID
SET 	ar.ParentID = NULL
	,	ar.CategoryID_new = NULL
;

/* 1. Initial data: missing on UM15082024*/
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,210,44458862,54547666,24);

CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,2,42997317,42997321,4);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,3,27639967,54927498,39);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,4,27634063,54918673,178);

CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,52,27634015,54935387,627);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,53,27635925,54556362,3688);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,54,27639910,54923575,96);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,55,27636941,54934802,300);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,58,37014238,50588934,45);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,59,27640729,54933786,720);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,63,27731897,54935158,165);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,72,27639800,54933810,330);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,73,43003175,50699092,321);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,74,27640553,54904857,137);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,75,27640178,54909020,127);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,78,40608985,43984913,2);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,79,27640448,54933650,164);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,82,27732634,41930923,13);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,92,27634934,54934634,71);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,93,41922547,50699020,861);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,94,35001718,50699086,104);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,95,27732008,54918124,42);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,98,39655518,50572575,43);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,99,34892950,42648143,186);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,103,27731690,54932964,85);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,112,27634348,34906623,52);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,113,44227249,50697863,45);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,114,40556974,50627979,6);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,115,34902315,50672186,32);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,118,39655504,40554891,2);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,119,35828618,52419929,43);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,132,27642470,54933637,71);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,133,40839821,50699087,158);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,134,40838844,50551901,13);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,135,27642575,54919910,48);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,138,39655501,44683428,7);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,139,27641644,54924436,311);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,142,39491899,39491899,1);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,152,27639509,54934016,534);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,153,35835114,54880478,712);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,154,27641175,54905031,263);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,155,27641186,54934111,98);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,158,39655495,44680652,15);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,159,27638755,54933588,363);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,162,27732774,49577343,93);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,163,27639388,54934537,355);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,164,27635026,54927884,111);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,165,27752942,50530022,7);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,166,44717493,44717493,1);

CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,201,54936446,54936448,3);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,202,35827191,35827191,1);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,204,35822903,35822903,1);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,205,35822848,35832786,8);

CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 1000,1001,27629134,54936391,17833316);
CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 10000,1002,27633850,54935604,6312);

