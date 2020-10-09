#remote rsync
cd /volumes/cts_archive_mysql80
rsync -rvh --progress data/ vnteam@10.40.40.58:/dev/mapper/volumes/cts_master_mysql80/data/