USE MonDB;
DROP TABLE IF EXISTS MonDB.SystemEventSchedule;
CREATE TABLE MonDB.`SystemEventSchedule` (
	ID 			INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	EventName 	VARCHAR(50),
	DayWeek 	SMALLINT COMMENT '0 = Monday, 1 = Tuesday, … 6 = Sunday',
    DateUM		DATE,
	FromTime 	TIME,
	ToTime 		TIME,
    IsProccesed	BIT DEFAULT 0,
    Enabled		BIT DEFAULT 1,
	TimeZone 	VARCHAR(20),
	INDEX 		IX_SystemEventSchedule_EventName(EventName),
    INDEX 		IX_SystemEventSchedule_Date(DayWeek, FromTime, ToTime)
 ) ENGINE=InnoDB;

INSERT INTO `MonDB`.`SystemEventSchedule` (`EventName`, `DayWeek`, `DateUM`, `FromTime`, `ToTime`, `TimeZone`) 
VALUES 	('UM', null, '2022-01-20', '15:30', '19:00', 'GTM+7'),
		('EV_CTS_DataCenter_ArchiveCustomer', '0',null, '15:30', '19:00', 'GTM+7'),
		('EV_CTS_DataCenter_ArchiveCustomer', '1',null, '15:30', '19:00', 'GTM+7'),
		('EV_CTS_DataCenter_ArchiveCustomer', '2',null, '15:30', '19:00', 'GTM+7'),
		('EV_CTS_DataCenter_ArchiveCustomer', '3',null, '15:30', '19:00', 'GTM+7'),
        ('EV_CTS_DataCenter_ArchiveCustomer', '4',null,'15:30', '19:00', 'GTM+7'),
        ('EV_CTS_DataCenter_ArchiveCustomer', '5',null,'15:30', '19:00', 'GTM+7'),
        ('EV_CTS_DataCenter_ArchiveCustomer', '6',null, '15:30', '19:00', 'GTM+7'),
        ('EV_DCS_DataCenter_Archive_DeviceCode', '0',null, '15:30', '19:00', 'GTM+7'),
		('EV_DCS_DataCenter_Archive_DeviceCode', '1',null, '15:30', '19:00', 'GTM+7'),
		('EV_DCS_DataCenter_Archive_DeviceCode', '2',null, '15:30', '19:00', 'GTM+7'),
		('EV_DCS_DataCenter_Archive_DeviceCode', '3',null, '15:30', '19:00', 'GTM+7'),
        ('EV_DCS_DataCenter_Archive_DeviceCode', '4',null, '15:30', '19:00', 'GTM+7'),
        ('EV_DCS_DataCenter_Archive_DeviceCode', '5',null, '15:30', '19:00', 'GTM+7'),
        ('EV_DCS_DataCenter_Archive_DeviceCode', '6',null, '15:30', '19:00', 'GTM+7'),
        ('EV_DCS_DataCenter_ArchiveAccountInactive_Device', '0',null, '15:30', '19:00', 'GTM+7'),
		('EV_DCS_DataCenter_ArchiveAccountInactive_Device', '1',null, '15:30', '19:00', 'GTM+7'),
		('EV_DCS_DataCenter_ArchiveAccountInactive_Device', '2',null, '15:30', '19:00', 'GTM+7'),
		('EV_DCS_DataCenter_ArchiveAccountInactive_Device', '3',null, '15:30', '19:00', 'GTM+7'),
        ('EV_DCS_DataCenter_ArchiveAccountInactive_Device', '4',null, '15:30', '19:00', 'GTM+7'),
        ('EV_DCS_DataCenter_ArchiveAccountInactive_Device', '5',null, '15:30', '19:00', 'GTM+7'),
        ('EV_DCS_DataCenter_ArchiveAccountInactive_Device', '6',null, '15:30', '19:00', 'GTM+7');