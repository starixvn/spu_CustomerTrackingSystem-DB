SELECT *
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_DEFINITION LIKE '%RawTransaction%';


CALL DCS_RT_RawTrans_Insert(
'[
{"LoginName":"A"
, "SubscriberName":"Alpha"
, "TransTime":"2020-03-26 12:33:08.0000", "DeviceCode":"44c7180a646c41ab9e0aa095c0aa1c55"
, "FingerprintCode":"3ffd2000df67b81c07ff2921e3406cb9dc0f201e;c5764cb96a7035aed4afe0190b99d8e9"
, "FingerprintMoreInfo":"LNDpOBUxNOEOHQgdop+1MQm6DjTyWkvYrj7sE9oiYkw="
, "UserAgent":"Mozilla/5.0 (Linux; U; Android 9; zh-CN; VKY-AL00 Build/HUAWEIVKY-AL00) AppleWebKit/537.36 (KHTML,  like Gecko) Version/4.0 Chrome/57.0.2987.108 UCBrowser/12.5.0.1030 Mobile Safari/537.36"
, "IP":"117.136.79.157"
, "IPId":"1971867549", "PluginID":1971867549, "URL":"http://www.ab5252.com/Deposit_ProcessLogin.aspx", "Action":"login", "ActionResult":"successfully", "InvalidDevice":"null"
, "TransStatus":0}
]');

CALL DCS_DataCenter.DCS_DC_TransformData_UnhandleSubscriberAction(158351,158351);
