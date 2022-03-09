CREATE TABLE `CTS_DataCenter`.`TWGroupBettingRule` (
  `RuleId` 					INT 					NOT NULL AUTO_INCREMENT,
  `RuleName` 				VARCHAR(100) 			NULL,
  `LimitSecond` 			SMALLINT 	UNSIGNED 	NULL,
  `TicketCountLimit`		SMALLINT 	UNSIGNED 	NULL,
  `RFMLimitValue` 			SMALLINT 	UNSIGNED 	NULL,
  `RFMLimitPercent`			TINYINT 	UNSIGNED 	NULL,
  `CustClassLimitValue`		VARCHAR(50)				NULL,
  `CustClassLimitPercent`	TINYINT 	UNSIGNED 	NULL,
  `BetFromLimitValue`		VARCHAR(50) 			NULL,
  `BetFromLimitPercent`		TINYINT 	UNSIGNED 	NULL,
  PRIMARY KEY (`RuleId`));

INSERT INTO `CTS_DataCenter`.`TWGroupBettingRule` (`RuleName`, `LimitSecond`, `TicketCountLimit`, `RFMLimitValue`, `RFMLimitPercent`, `CustClassLimitValue`, `CustClassLimitPercent`, `BetFromLimitValue`, `BetFromLimitPercent`) VALUES ('RuleType1', '5', '13', '8', '70', '1,2', '50', 'x,z', '70');
INSERT INTO `CTS_DataCenter`.`TWGroupBettingRule` (`RuleName`, `LimitSecond`, `TicketCountLimit`, `RFMLimitValue`, `RFMLimitPercent`, `CustClassLimitValue`, `CustClassLimitPercent`, `BetFromLimitValue`, `BetFromLimitPercent`) VALUES ('RuleType2', '5', '13', '8', '70', '1,2', '50', 'x,z', '70');
INSERT INTO `CTS_DataCenter`.`TWGroupBettingRule` (`RuleName`, `LimitSecond`, `TicketCountLimit`, `RFMLimitValue`, `RFMLimitPercent`, `CustClassLimitValue`, `CustClassLimitPercent`, `BetFromLimitValue`, `BetFromLimitPercent`) VALUES ('RuleType3', '5', '7', '8', '60', '1,2', '50', 'x,z', '70');
INSERT INTO `CTS_DataCenter`.`TWGroupBettingRule` (`RuleName`, `LimitSecond`, `TicketCountLimit`, `RFMLimitValue`, `RFMLimitPercent`, `CustClassLimitValue`, `CustClassLimitPercent`, `BetFromLimitValue`, `BetFromLimitPercent`) VALUES ('RuleType4', '5', '8', '8', '60', '1,2', '50', 'x,z', '70');
INSERT INTO `CTS_DataCenter`.`TWGroupBettingRule` (`RuleName`, `LimitSecond`, `TicketCountLimit`, `RFMLimitValue`, `RFMLimitPercent`, `CustClassLimitValue`, `CustClassLimitPercent`, `BetFromLimitValue`, `BetFromLimitPercent`) VALUES ('RuleType5', '5', '11', '8', '60', '1,2', '50', 'x,z', '70');
INSERT INTO `CTS_DataCenter`.`TWGroupBettingRule` (`RuleName`, `LimitSecond`, `TicketCountLimit`, `RFMLimitValue`, `RFMLimitPercent`, `CustClassLimitValue`, `CustClassLimitPercent`, `BetFromLimitValue`, `BetFromLimitPercent`) VALUES ('RuleType6', '5', '12', '8', '60', '1,2', '50', 'x,z', '70');
INSERT INTO `CTS_DataCenter`.`TWGroupBettingRule` (`RuleName`, `LimitSecond`, `TicketCountLimit`, `RFMLimitValue`, `RFMLimitPercent`, `CustClassLimitValue`, `CustClassLimitPercent`, `BetFromLimitValue`, `BetFromLimitPercent`) VALUES ('RuleType7', '5', '6', '8', '60', '1,2', '50', 'x,z', '70');
INSERT INTO `CTS_DataCenter`.`TWGroupBettingRule` (`RuleName`, `LimitSecond`, `TicketCountLimit`, `RFMLimitValue`, `RFMLimitPercent`, `CustClassLimitValue`, `CustClassLimitPercent`, `BetFromLimitValue`, `BetFromLimitPercent`) VALUES ('RuleType8', '5', '7', '8', '60', '1,2', '50', 'x,z', '70');
INSERT INTO `CTS_DataCenter`.`TWGroupBettingRule` (`RuleName`, `LimitSecond`, `TicketCountLimit`, `RFMLimitValue`, `RFMLimitPercent`, `CustClassLimitValue`, `CustClassLimitPercent`, `BetFromLimitValue`, `BetFromLimitPercent`) VALUES ('RuleType9', '5', '12', '8', '50', '1,2', '50', 'x,z', '50');
INSERT INTO `CTS_DataCenter`.`TWGroupBettingRule` (`RuleName`, `LimitSecond`, `TicketCountLimit`, `RFMLimitValue`, `RFMLimitPercent`, `CustClassLimitValue`, `CustClassLimitPercent`, `BetFromLimitValue`, `BetFromLimitPercent`) VALUES ('RuleType10', '5', '7', '8', '50', '1,2', '50', 'x,z', '50');
INSERT INTO `CTS_DataCenter`.`TWGroupBettingRule` (`RuleName`, `LimitSecond`, `TicketCountLimit`, `RFMLimitValue`, `RFMLimitPercent`, `CustClassLimitValue`, `CustClassLimitPercent`, `BetFromLimitValue`, `BetFromLimitPercent`) VALUES ('RuleType11', '5', '8', '8', '50', '1,2', '50', 'x,z', '50');
INSERT INTO `CTS_DataCenter`.`TWGroupBettingRule` (`RuleName`, `LimitSecond`, `TicketCountLimit`, `RFMLimitValue`, `RFMLimitPercent`, `CustClassLimitValue`, `CustClassLimitPercent`, `BetFromLimitValue`, `BetFromLimitPercent`) VALUES ('RuleType12', '5', '10', '8', '50', '1,2', '50', 'x,z', '60');
INSERT INTO `CTS_DataCenter`.`TWGroupBettingRule` (`RuleName`, `LimitSecond`, `TicketCountLimit`, `RFMLimitValue`, `RFMLimitPercent`, `CustClassLimitValue`, `CustClassLimitPercent`, `BetFromLimitValue`, `BetFromLimitPercent`) VALUES ('RuleType13', '5', '11', '8', '50', '1,2', '50', 'x,z', '50');
INSERT INTO `CTS_DataCenter`.`TWGroupBettingRule` (`RuleName`, `LimitSecond`, `TicketCountLimit`, `RFMLimitValue`, `RFMLimitPercent`, `CustClassLimitValue`, `CustClassLimitPercent`, `BetFromLimitValue`, `BetFromLimitPercent`) VALUES ('RuleType14', '5', '5', '8', '50', '1,2', '50', 'x,z', '60');
INSERT INTO `CTS_DataCenter`.`TWGroupBettingRule` (`RuleName`, `LimitSecond`, `TicketCountLimit`, `RFMLimitValue`, `RFMLimitPercent`, `CustClassLimitValue`, `CustClassLimitPercent`, `BetFromLimitValue`, `BetFromLimitPercent`) VALUES ('RuleType15', '5', '6', '8', '50', '1,2', '50', 'x,z', '50');
INSERT INTO `CTS_DataCenter`.`TWGroupBettingRule` (`RuleName`, `LimitSecond`, `TicketCountLimit`, `RFMLimitValue`, `RFMLimitPercent`, `CustClassLimitValue`, `CustClassLimitPercent`, `BetFromLimitValue`, `BetFromLimitPercent`) VALUES ('RuleType16', '5', '5', '8', '50', '1,2', '50', 'x,z', '60');
INSERT INTO `CTS_DataCenter`.`TWGroupBettingRule` (`RuleName`, `LimitSecond`, `TicketCountLimit`, `RFMLimitValue`, `RFMLimitPercent`, `CustClassLimitValue`, `CustClassLimitPercent`, `BetFromLimitValue`, `BetFromLimitPercent`) VALUES ('RuleType17', '5', '6', '8', '50', '1,2', '50', 'x,z', '50');
