from dbtask.dbTask import DBTaskHelper
task = DBTaskHelper()

task.HealthCheckStorageJob()
task.HealthCheckMemoryJob()
task.HealthCheckReplicationJob()
task.CheckBigQueryJob()
