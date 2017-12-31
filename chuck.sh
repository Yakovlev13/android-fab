#!/bin/bash

# file name
if [[ $(date +%d) -eq 1 ]]; then
	filename="`hostname`-monthly-`date -Iseconds`.tar.xz.gpg"
elif [[ $(date +%u) -eq 7 ]]; then
	filename="`hostname`-weekly-`date -Iseconds`.tar.xz.gpg"
else
	filename="`hostname`-daily-`date -Iseconds`.tar.xz.gpg"
fi

touch "/tmp/$filename"
trap "rm -f /tmp/$filename" EXIT

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
	"/home/markormesher/.byobu" \
	"/home/markormesher/.local/share/data/ownCloud" \
	"/home/markormesher/.gnupg" \
	"/home/markormesher/.ssh" \
	"/home/markormesher/Documents" \
	"/home/markormesher/Pictures" \
	"/home/markormesher/Tools" | xz -4 -c | gpg2 -e -r "me@markormesher.co.uk" -o "$filename"

# upload
aws s3 cp "/tmp/$filename" "s3://mormesher.backups/$file""
