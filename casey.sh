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
filename="casey-$backupType-$now.tar.xz.gpg"
touch "/tmp/$filename"
echo "Backup file: /tmp/$filename"

dumpFolder="/tmp/dumps-`date -Iseconds`"
mkdir "$dumpFolder"
echo "Dump folder: $dumpFolder"

trap "rm -rf /tmp/$filename $dumpFolder" EXIT

dpkg -l > "$dumpFolder/dpkg-l.txt"
apt-mark showmanual > "$dumpFolder/apt-mark-manual.txt"

tar -cpf - \
	--exclude=".csync_journal.db*" \
	--exclude=".owncloudsync*" \
	--exclude=".git" \
	--exclude="node_modules" \
	--exclude="build" \
	"$dumpFolder" \
	"/etc/apt" \
	"/home/markormesher/.byobu" \
	"/home/markormesher/.local/share/data/ownCloud" \
	"/home/markormesher/.gnupg" \
	"/home/markormesher/.ssh" \
	"/home/markormesher/Documents" \
	"/home/markormesher/Pictures" \
	"/home/markormesher/Projects" \
	"/home/markormesher/Tools" | xz -4 -c | gpg2 -e -r "me@markormesher.co.uk" > "/tmp/$filename"

aws s3 cp "/tmp/$filename" "s3://mormesher.backups/$filename"
