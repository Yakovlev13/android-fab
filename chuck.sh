#!/usr/bin/env bash

now=$(date -Iseconds)
echo ""
echo ""
echo "Running $0 at $now"

set -e

if [[ $(date +%d) -eq 1 ]]; then
	backupType="monthly"
elif [[ $(date +%u) -eq 7 ]]; then
	backupType="weekly"
else
	backupType="daily"
fi
filename="chuck-$backupType-$now.tar.xz.gpg"
touch "/tmp/$filename"
echo "Backup file: /tmp/$filename"

dumpFolder="/tmp/dumps-`date -Iseconds`"
mkdir "$dumpFolder"
echo "Dump folder: $dumpFolder"

trap "rm -rf /tmp/$filename $dumpFolder" EXIT

if [[ "$backupType" = "daily" ]]; then
	mysqldump --all-databases > "$dumpFolder/mysqldump.txt"
	pg_dumpall > "$dumpFolder/pgdump.txt"

	tar -cpf - \
		--exclude=".csync_journal.db*" \
		--exclude=".owncloudsync*" \
		--exclude=".git" \
		--exclude="node_modules" \
		--exclude="build" \
		--exclude="dist" \
		--exclude="/var/www/owncloud/data/*/files_trashbin" \
		--exclude="/var/www/owncloud/data/*/files_versions" \
		"$dumpFolder" | xz -4 -c | gpg2 -e -r "me@markormesher.co.uk" > "/tmp/$filename"
else
	sudo -u www-data php /var/www/owncloud/occ files:scan --all
	sudo -u www-data php /var/www/owncloud/occ files:cleanup

	dpkg -l > "$dumpFolder/dpkg-l.txt"
	apt-mark showmanual > "$dumpFolder/apt-mark-manual.txt"
	mysqldump --all-databases > "$dumpFolder/mysqldump.txt"
	pg_dumpall > "$dumpFolder/pgdump.txt"

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
fi

aws s3 cp "/tmp/$filename" "s3://mormesher.backups/$filename"
