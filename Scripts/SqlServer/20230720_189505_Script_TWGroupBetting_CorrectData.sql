/*<info serverAlias="DBCTS-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created:	20230720@Victoria.Le
	Task : TW Group Betting - Correct Data
	DB:	DB062		
	
	Description: 

	Revisions:	
		- 20230720@Victoria.Le: 	Initial Writing - [Redmine ID: #189505]
*/

USE [bodb02]

IF OBJECT_ID('tempdb..#tmpSPU_GroupBettingCustomer') IS NOT NULL
	DROP TABLE #tmpSPU_GroupBettingCustomer;

CREATE TABLE #tmpSPU_GroupBettingCustomer (
		CustId						INT 	
	,	ScanDate					DATE
	,	LastCountTotalTicketDate	DATETIME	
	,	TicketCount					INT
	,	RejectTicketCount			INT
	,	DesktopTicketCount			INT
	,	ParlayTicketCount			INT
	,	PRIMARY KEY (CustId,ScanDate)
);	

INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (25076619,'2023-07-03',7,0,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (31254069,'2023-07-03',1,0,0,1);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (38143020,'2023-07-03',25,0,17,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (42461279,'2023-07-03',13,2,0,12);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (47288984,'2023-07-03',9,0,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (47320766,'2023-07-03',1,0,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (48765257,'2023-07-03',150,2,0,1);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (49462756,'2023-07-03',30,0,0,2);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (50380778,'2023-07-03',8,0,0,8);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (50380977,'2023-07-03',13,0,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (52423663,'2023-07-03',20,0,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (52812919,'2023-07-03',49,2,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (54273216,'2023-07-03',3,0,3,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (55463124,'2023-07-03',4,0,0,4);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (55732574,'2023-07-03',1,0,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (55770802,'2023-07-03',22,12,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (59351310,'2023-07-03',1,0,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (62918353,'2023-07-03',4,0,0,3);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (63572550,'2023-07-03',8,0,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (64056311,'2023-07-03',12,0,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (66237324,'2023-07-03',1,0,0,1);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (68982018,'2023-07-03',5,1,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (69299532,'2023-07-03',5,2,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (77020237,'2023-07-03',7,1,7,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (77205573,'2023-07-03',21,0,21,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (78308948,'2023-07-03',5,0,0,5);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (78915937,'2023-07-03',1,0,0,1);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (78986644,'2023-07-03',13,0,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (78986759,'2023-07-03',50,24,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (79318853,'2023-07-03',1,0,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (79547647,'2023-07-03',56,2,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (83631141,'2023-07-03',13,0,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (84108872,'2023-07-03',7,0,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (84357041,'2023-07-03',5,1,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (84543226,'2023-07-03',2,0,0,2);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (84836870,'2023-07-03',44,4,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (84933333,'2023-07-03',16,0,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (85263185,'2023-07-03',4,0,0,4);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (86591835,'2023-07-03',16,2,0,9);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (86946451,'2023-07-03',8,0,8,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (87097011,'2023-07-03',9,0,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (87655252,'2023-07-03',1,0,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (87829467,'2023-07-03',5,0,0,4);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (87829479,'2023-07-03',12,0,3,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (87865151,'2023-07-03',10,1,0,10);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (88114178,'2023-07-03',17,0,0,4);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (88114179,'2023-07-03',1,0,0,1);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (89741431,'2023-07-03',4,0,0,2);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (90854469,'2023-07-03',1,0,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (90854488,'2023-07-03',2,0,0,2);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (90854498,'2023-07-03',2,0,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (90854519,'2023-07-03',5,0,0,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (70008639,'2023-07-12',47,2,0,2);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (18734441,'2023-07-12',215,2,215,0);
INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate,TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount) VALUES (65172015,'2023-07-12',15,1,0,0);


UPDATE gbc WITH (ROWLOCK,UPDLOCK)
SET		gbc.TicketCount = tmp.TicketCount
	,	gbc.RejectTicketCount = tmp.RejectTicketCount
	,	gbc.DesktopTicketCount = tmp.DesktopTicketCount
	,	gbc.ParlayTicketCount = tmp.ParlayTicketCount
	,	gbc.LastCountTotalTicketDate = GETDATE()
FROM dbo.SPU_GroupBettingCustomer AS gbc
	INNER JOIN #tmpSPU_GroupBettingCustomer AS tmp ON tmp.CustId = gbc.CustId AND tmp.ScanDate = gbc.ScanDate
;