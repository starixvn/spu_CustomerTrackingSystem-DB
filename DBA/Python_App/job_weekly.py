from dbtask.dbTask import DBTaskHelper
task = DBTaskHelper()
task.ArchiveJob("Job");
task.DropPartitionJob();
task.ReOrganizePartitionJob();
task.FragmentationTableJob();