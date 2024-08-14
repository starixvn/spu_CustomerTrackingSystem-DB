/* 1. Customer_InitialGroupBetting - 2600/2601 */
select JobScannedType, count(1)
from dbo.CustomerClassification_ScannedNewCust with (nolock)
where (JobScannedType = 2 or custid = 116986922)
and CreatedTime < '2024-07-01 00:00:00'
group by JobScannedType
;



select h.custid, count(1), min(h1.LastModifiedDate), max(h1.LastModifiedDate), group_concat(h1.CategoryID)
from CTSCustomerClassification_History as h
inner join CTSCustomerClassification_History as h1 on h.CustID = h1.CustID
where h.CategoryID in (239,234,254,264,274) -- New GB / Lic Sub
group by h.custid
;

with cte as
(select h.custid, max(h1.ID) AS maxID
from CTSCustomerClassification_History as h
inner join CTSCustomerClassification_History as h1 on h.CustID = h1.CustID
where h.CategoryID in (239,234,254,264,274) -- Lic Sub
group by h.custid
)
select h.*
from CTSCustomerClassification_History as h
inner join cte as c on c.maxID = h.ID
;
-- 679 clean data history 239 + Lic sub

with cte as
(select h.custid, max(h1.ID) AS maxID
from CTSCustomerClassification_History as h
inner join CTSCustomerClassification_History as h1 on h.CustID = h1.CustID
where h.TargetCC  IN (43,45,46,47,2500,2503,2504,2505)
group by h.custid
)
select h.*
from CTSCustomerClassification_History as h
inner join cte as c on c.maxID = h.ID
;
-- target CC: specialCC 4X
-- clean data history 
-- update IsDataChange = 0 >> IsDataChange = 1


select SportGroupID, MIN(ID), COUNT(1)
from CTSCustomerClassification_History
group by SportGroupID
;


select SportID, MIN(ID), COUNT(1)
from CTSCustomerClassification_BySport_History
group by SportID
;

select CategoryID, MIN(ID), COUNT(1)
from ArchiveCustomer_CTSCustomer
group by CategoryID
;


-- ------------------------
select count(1)
from CTSCustomerClassification as cc
right join CTSCustomer as cust on cust.CustID = cc.CustID
where cc.CustID is null
;


select cc.SportGroupID, count(cc.CustID), count(distinct cc.CustID), min(cc.CreatedDate), max(cc.CreatedDate)
from CTSCustomerClassification as cc
group by cc.SportGroupID;

select cc.SportGroupID, cc.CategoryID, count(cc.CustID), count(distinct cc.CustID), min(cc.CreatedDate), max(cc.CreatedDate)
from CTSCustomerClassification as cc
group by cc.SportGroupID, cc.CategoryID;


select cc.SportGroupID, cc.CategoryID, count(cc.CustID), count(distinct cc.CustID), min(cc.CreatedDate), max(cc.CreatedDate)
from CTSCustomerClassification_History as cc
group by cc.SportGroupID, cc.CategoryID;

select cc.SportGroupID, count(cc.ID), min(cc.ID), max(cc.ID), min(cc.LastModifiedDate ), max(cc.LastModifiedDate )
from CTSCustomerClassification_History as cc
where cc.ID >= 8
group by cc.SportGroupID;

select *
from CTSCustomerClassification_History
where CustID = 104737771;


select *
from CTSCustomerClassification
where CustID = 104737771;

select *
from ProbationAccountMonitor
where CustID = 104737771;


select cc.SportGroupID, cc.CategoryID, count(cc.ID), min(cc.ID), max(cc.ID), min(cc.LastModifiedDate ), max(cc.LastModifiedDate )
from CTSCustomerClassification_History as cc
where cc.ID >= 8
group by cc.SportGroupID, cc.CategoryID;

select min(ID),count(1) from CTSCustomerClassification_History as cc;

select min(ID),count(1) from CTSCustomerClassification_Log as cc;

select cust.SiteID, cust.SiteName, count(cc.CTSCustID)
from CTSCustomerClassification as cc
inner join CTSCustomer as cust on cust.CTSCustID = cc.CTSCustID
where cc.CategoryID = 1001
group by  cust.SiteID, cust.SiteName
;



select *
from CTSCustomerClassification
where CategoryID = 0;

select *
from CTSCustomerClassification
where CustID in (38557892,38587175,39726390,41770821);

select * from CTSCustomer where CustID in (38557892,38587175,39726390,41770821);

select * from CustomerCategory;


select *
from CTSCustomerClassification
where CustID in (104974565);


select *
from CTSCustomerClassification
where CategoryID = 160;

select 
from CTSCustomerClassification as cc
group by cc.SportGroupID, cc.CategoryID;

with cte as 
(
select distinct custid 
from CTSCustomerClassification as cc
where cc.CategoryID in (72)
)
select ar.LastTicketDate, ar.Created, ar.CustID, group_concat(distinct cc.SportGroupID), group_concat(distinct cc.CategoryID)
, min(cc.CreatedDate), max(cc.CreatedDate), min(cc.LastModifiedDate ), max(cc.LastModifiedDate ), min(cc.LastScannedDate ), max(cc.LastScannedDate )
from cte as c
inner join CTSCustomerClassification as cc on cc.CustID = c.CustID 
inner join CTS_Archive.CTSCustomerAssociationStatus as ar on ar.CustID = cc.CustID 
group by ar.LastTicketDate, ar.Created, ar.CustID
;


select 
from CTSCustomerClassification as cc
group by cc.SportGroupID, cc.CategoryID;

with cte as 
(
select distinct custid 
from CTSCustomerClassification as cc
where cc.CategoryID in (79)
)
select ar.LastTicketDate, ar.Created, ar.CustID, group_concat(distinct cc.SportGroupID), group_concat(distinct cc.CategoryID)
, min(cc.CreatedDate), max(cc.CreatedDate), min(cc.LastModifiedDate ), max(cc.LastModifiedDate ), min(cc.LastScannedDate ), max(cc.LastScannedDate )
from cte as c
inner join CTSCustomerClassification as cc on cc.CustID = c.CustID 
inner join CTS_Archive.CTSCustomerAssociationStatus as ar on ar.CustID = cc.CustID 
group by ar.LastTicketDate, ar.Created, ar.CustID
;

with cte as 
(
select distinct custid 
from CTSCustomerClassification as cc
where cc.CategoryID in (0,51,151,160)
)
select ar.LastTicketDate, ar.Created, ar.CustID, group_concat(distinct cc.SportGroupID), group_concat(distinct cc.CategoryID)
, min(cc.CreatedDate), max(cc.CreatedDate), min(cc.LastModifiedDate ), max(cc.LastModifiedDate ), min(cc.LastScannedDate ), max(cc.LastScannedDate )
from cte as c
inner join CTSCustomerClassification as cc on cc.CustID = c.CustID 
inner join CTS_Archive.CTSCustomerAssociationStatus as ar on ar.CustID = cc.CustID 
group by ar.LastTicketDate, ar.Created, ar.CustID
;


with cte as 
(
select distinct custid 
from CTSCustomerClassification as cc
where cc.CategoryID in (0,51,151,160)
)
select ar.LastTicketDate, ar.Created, ar.CustID, group_concat(distinct cc.SportGroupID), group_concat(distinct cc.CategoryID)
, min(cc.CreatedDate), max(cc.CreatedDate), min(cc.LastModifiedDate ), max(cc.LastModifiedDate ), min(cc.LastScannedDate ), max(cc.LastScannedDate )
from cte as c
inner join CTSCustomerClassification as cc on cc.CustID = c.CustID 
inner join CTS_Archive.CTSCustomerAssociationStatus as ar on ar.CustID = cc.CustID 
group by ar.LastTicketDate, ar.Created, ar.CustID
;


select cust.SubscriberID, cust.SiteID, cust.Site , count(cc.CTSCustID)
from CTSCustomerClassification as cc
inner join CTSCustomer as cust on cust.CTSCustID = cc.CTSCustID
where cc.CategoryID = 1001
AND YEAR(cc.CreatedDate) = 2020
group by  cust.SubscriberID, cust.SiteID, cust.Site
;

select * from Adhoc_Stats4UM;
