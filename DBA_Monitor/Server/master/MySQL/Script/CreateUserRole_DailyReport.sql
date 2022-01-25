USE MonDB;

GRANT EVENT ON  *.* TO `CTSMonitor`@`%`;
GRANT ALL PRIVILEGES ON `MonDB`.* TO `CTSMonitor`@`%`;

CREATE USER 'ctsMonitor'@'%' IDENTIFIED WITH mysql_native_password BY 'ctsMonitor@spu2022#';
GRANT `CTSMonitor` TO `ctsMonitor`@`%`;
FLUSH PRIVILEGES;