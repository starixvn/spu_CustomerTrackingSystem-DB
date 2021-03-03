/*<info serverAlias="CTSMain-MonDB" databaseType="2"></info>*/
/*
	Created: 20210303@Aries.Nguyen
	Task: 	 Create user for grafana monitor [Redmine ID: #149662]
	DB: 	 MonDB
*/

CREATE USER 'ctsGrafana.vn'@'%' IDENTIFIED WITH mysql_native_password BY 'password';
GRANT SELECT, PROCESS, REPLICATION CLIENT ON *.* TO `ctsGrafana.vn`@`%`;
GRANT SELECT, INSERT, EXECUTE ON `MonDB`.* TO `ctsGrafana.vn`@`%`;
FLUSH PRIVILEGES;








