CREATE USER 'ctsGrafana.vn'@'%' IDENTIFIED WITH mysql_native_password BY 'password';
GRANT SELECT, PROCESS, REPLICATION CLIENT ON *.* TO `ctsGrafana.vn`@`%`;
GRANT SELECT, INSERT, EXECUTE ON `MonDB`.* TO `ctsGrafana.vn`@`%`;
FLUSH PRIVILEGES;