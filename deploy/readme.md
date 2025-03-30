#########
To check the backup for the collections use this command 
gsutil cat gs://shravani_kalyanam_bucket/backups/mongo-backup-2025-03-30-01-39-14.gz | \
mongorestore --uri="mongodb+srv://galaDbUser:<password>@cluster0.sod5j.mongodb.net/galadb?appName=Cluster0&retryWrites=true&w=majority" \
--archive --gzip --dryRun -vvvvv