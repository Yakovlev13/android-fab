#!/bin/bash

set -e
set -v

# file name
if [[ $(date +%d) -eq 1 ]]; then
	filename="casey-monthly-`date -Iseconds`.tar.xz.gpg"
elif [[ $(date +%u) -eq 7 ]]; then
	filename="casey-weekly-`date -Iseconds`.tar.xz.gpg"
else
	filename="casey-daily-`date -Iseconds`.tar.xz.gpg"
fi

echo "Backup file: /tmp/$filename"
touch "/tmp/$filename"

# create dumps
dumpFolder="/tmp/dumps-`date -Iseconds`"
mkdir "$dumpFolder"
echo "Dump folder: $dumpFolder"

dpkg -l > "$dumpFolder/dpkg-l.txt"
apt-mark showmanual > "$dumpFolder/apt-mark-manual.txt"

# cleanup when this is all over
trap "rm -rf /tmp/$filename $dumpFolder" EXIT

# create tar file, compress and encrypt
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

# upload
aws s3 cp "/tmp/$filename" "s3://mormesher.backups/$filename"
