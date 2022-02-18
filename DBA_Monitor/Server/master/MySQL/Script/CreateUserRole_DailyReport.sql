USE MonDB;

GRANT EVENT ON  *.* TO `CTSMonitor`@`%`;
GRANT ALL PRIVILEGES ON `MonDB`.* TO `CTSMonitor`@`%`;

CREATE USER 'ctsMonitor'@'%' IDENTIFIED WITH mysql_native_password BY 'ctsMonitor@spu2022#';
GRANT `CTSMonitor` TO `ctsMonitor`@`%`;
GRANT DROP ON performance_schema.events_statements_summary_by_program TO `ctsMonitor`@`%`;
GRANT DROP ON performance_schema.table_io_waits_summary_by_table TO `ctsMonitor`@`%`;
GRANT DROP ON performance_schema.table_io_waits_summary_by_index_usage TO `ctsMonitor`@`%`;
FLUSH PRIVILEGES;