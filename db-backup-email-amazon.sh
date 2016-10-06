#!/bin/bash
#
# SECURE BACKUP MYSQL DB to EMAIL and/or Amazon S3
# -----------------------------------------------------
# require: Mutt, Amazon S3 client [https://github.com/s3tools/s3cmd]
# use cron to run this script at specific interval.
#
# to decrypt:
# openssl aes-256-cbc -d -a -in encfile.enc -out newfile
# ------------------------------------------------------

# --- EDIT ---
S3CMD=/usr/bin/s3cmd
DBSERVER=127.0.0.1
DATABASE=dbname
DBUSER=user
DBPASS=password
ENCPASS="encpassword"
BACKUPDIR=/backup/dir
RECIP='first@youremail.com second@youremail.com'
DATE=`date +"%Y-%m-%d"`
TXTDATE=`date +"%d.%m.%Y %H:%M:%S"`
FILE=${DATABASE}_${DATE}.sql
# --- END ---


cd $BACKUPDIR

unalias rm     2> /dev/null
rm ${FILE}     2> /dev/null
rm ${FILE}.gz  2> /dev/null

# dump database
mysqldump --opt --user=${DBUSER} --password=${DBPASS} ${DATABASE} > ${FILE}

# encrypt db file
openssl aes-256-cbc -a -salt -in ${FILE} -out ${FILE}.enc -pass "pass:${ENCPASS}"
rm ${FILE} 2> /dev/null

# compress
gzip -f -q $FILE.enc

# email text message
MAILMSG=`cat <<EOF
(Automated) Backup database.

## Info Backup ##
Interval : Weekly
Date : ${TXTDATE}
Status : Encrypted
Compression : Gzip
Filename : ${FILE}.enc.gz

EOF
`

# email backup to recipient(s)
# require mutt
echo "${MAILMSG}" | mutt -nz -F "/home/user/dbmuttrc" -a "${BACKUPDIR}/${FILE}.enc.gz" -s "DB Backup ${DATE}" -- ${RECIP}


# backup to Amazon S3 (if available)
# require Amazon S3 client
$S3CMD put ${BACKUPDIR}/${FILE}.enc.gz s3://your-ama-zone/ > /home/user/s3cmd.log
