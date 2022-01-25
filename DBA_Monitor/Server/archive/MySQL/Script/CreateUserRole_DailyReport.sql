USE MonDB;
CREATE ROLE 'CTSMonitor';
GRANT ALL PRIVILEGES ON `MonDB`.* TO `CTSMonitor`@`%`;
GRANT EVENT ON  *.* TO `CTSMonitor`@`%`;
GRANT PROCESS ON *.* TO `CTSMonitor`@`%`;
GRANT FLUSH_STATUS ON *.* TO `CTSMonitor`@`%`;
GRANT SELECT ON `sys`.* TO `CTSMonitor`@`%`;
GRANT SELECT ON `performance_schema`.* TO `CTSMonitor`@`%`;
GRANT SELECT ON `mysql`.`slow_log` TO `CTSMonitor`@`%`;

CREATE USER 'ctsMonitor'@'%' IDENTIFIED WITH mysql_native_password BY 'ctsMonitor@spu2022#';
GRANT `CTSMonitor` TO `ctsMonitor`@`%`;
FLUSH PRIVILEGES;