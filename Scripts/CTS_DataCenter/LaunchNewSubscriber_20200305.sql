/*
		Created:	20200528@CaseyHuynh	
		Task :		Subsriber: New (2)
		DB:			CTS_Admin
		Original:

		Revisions:
		Param's Explanation (filtered by):
*/
INSERT INTO `CTS_Admin`.`Subscriber`
(`SubscriberID`,
`SubscriberName`,
`SubscriberPrefix`,
`SubscriberType`,
`SubscriberStatus`,
`CreatedDate`,
`CreatedBy`,
`IsTest`,
`DCSStatus`,
`DCSIntegrationDate`)
VALUES (111111, 'BPLE', 'BPLE$', 1,1,'2020-03-05',NULL,0,1,'2020-03-05')
, (111111, 'Weiwei', 'Weiwei$', 1,1,'2020-03-05',NULL,0,1,'2020-03-05')
, (111111, 'GGBOOKES', 'GGBOOKES$', 1,1,'2020-03-05',NULL,0,1,'2020-03-05');

/*
1. Termination 6 licensees
VCAsia, Empire555, AsianBet, BBIN4, tcycyl, Aixawin (wrong licensee's name)

2. Integration 4 licenses
GGBOOKES, BPLE, Weiwei and Axiawin


(<{SubscriberID: }>,
<{SubscriberName: }>,
<{SubscriberPrefix: }>,
<{SubscriberType: }>,
<{SubscriberStatus: }>,
<{CreatedDate: }>,
<{CreatedBy: }>,
<{IsTest: }>,
<{DCSStatus: }>,
<{DCSIntegrationDate: }>);
SELECT SubscriberID
      ,SubscriberName
      ,SubscriberPrefix
      ,SubscriberType
      ,SubscriberSourceID
      ,SubscriberStatus
      ,CreatedDate
      ,CreatedBy
      ,IsTest
      ,DCSStatus
      ,DCSIntegrationDate
      ,FPSSubscriberID
      ,TerminatedDate 
FROM CTS_Admin.Subscriber;*/