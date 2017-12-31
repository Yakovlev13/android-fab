#!/bin/bash

# file name
if [[ $(date +%d) -eq 1 ]]; then
	filename="chuck-monthly-`date -Iseconds`.tar.xz.gpg"
elif [[ $(date +%u) -eq 7 ]]; then
	filename="chuck-weekly-`date -Iseconds`.tar.xz.gpg"
else
	filename="chuck-daily-`date -Iseconds`.tar.xz.gpg"
fi

touch "/tmp/$filename"
trap "echo rm -f /tmp/$filename" EXIT

# create dumps
dumpFolder="/tmp/dumps-`date -Iseconds`"
mkdir "$dumpFolder"

dpkg -l > "$dumpFolder/dpkg-l.txt"
apt-mark showmanual > "$dumpFolder/apt-mark-manual.txt"

# create tar file, compress and encrypt
tar -cpf - \
	--exclude=".csync_journal.db*" \
	--exclude=".owncloudsync*" \
	--exclude=".git" \
	--exclude="node_modules" \
	--exclude="build" \
	"$dumpFolder" \
	"/etc/apt" \
	"/home/markormesher/.gnupg" \
	"/home/markormesher/.ssh" \
	"/home/deploy/.gnupg" \
	"/home/deploy/.ssh" \
	"/var/www" \
	"/var/node" | xz -4 -c | gpg2 -e -r "me@markormesher.co.uk" > "/tmp/$filename"

# upload
aws s3 cp "/tmp/$filename" "s3://mormesher.backups/$filename"
