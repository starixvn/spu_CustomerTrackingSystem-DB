#[20200911@Roger.Le][138102]: Function add new subscriber
ALTER TABLE CTS_Admin.Subscriber ADD COLUMN TerminatedDate DATETIME DEFAULT NULL;
ALTER TABLE CTS_Admin.Subscriber MODIFY `SubscriberPrefix` VARCHAR(30) DEFAULT NULL;
CREATE INDEX IX_Subscriber_SubscriberPrefix ON CTS_Admin.Subscriber (SubscriberPrefix);