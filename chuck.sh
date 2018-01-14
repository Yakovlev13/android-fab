#!/bin/bash

now=$(date)
echo ""
echo ""
echo "Running $0 at $now"

set -e
set -v

# cleanup ownCloud before backing up
sudo -u www-data php /var/www/owncloud/occ files:scan --all
sudo -u www-data php /var/www/owncloud/occ files:cleanup

# backup file name
if [[ $(date +%d) -eq 1 ]]; then
	filename="chuck-monthly-`date -Iseconds`.tar.xz.gpg"
elif [[ $(date +%u) -eq 7 ]]; then
	filename="chuck-weekly-`date -Iseconds`.tar.xz.gpg"
else
	filename="chuck-daily-`date -Iseconds`.tar.xz.gpg"
fi

echo "Backup file: /tmp/$filename"
touch "/tmp/$filename"

# create dumps
dumpFolder="/tmp/dumps-`date -Iseconds`"
mkdir "$dumpFolder"
echo "Dump folder: $dumpFolder"

dpkg -l > "$dumpFolder/dpkg-l.txt"
apt-mark showmanual > "$dumpFolder/apt-mark-manual.txt"
mysqldump --all-databases > "$dumpFolder/mysqldump.txt"
pg_dumpall > "$dumpFolder/pgdump.txt"

# cleanup when this is all over
trap "rm -rf /tmp/$filename $dumpFolder" EXIT

# create tar file, compress and encrypt
tar -cpf - \
	--exclude=".csync_journal.db*" \
	--exclude=".owncloudsync*" \
	--exclude=".git" \
	--exclude="node_modules" \
	--exclude="build" \
	--exclude="dist" \
	--exclude="/var/www/owncloud/data/*/files_trashbin" \
	--exclude="/var/www/owncloud/data/*/files_versions" \
	"$dumpFolder" \
	"/etc/apt" \
	"/home/markormesher/.gnupg" \
	"/home/markormesher/.ssh" \
	"/var/www" \
	"/var/node" | xz -4 -c | gpg2 -e -r "me@markormesher.co.uk" > "/tmp/$filename"

# upload
aws s3 cp "/tmp/$filename" "s3://mormesher.backups/$filename"
