#!/usr/bin/env bash

source $HOME/.bash_aliases

now=$(date -Iseconds)
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

# grab info about installed packages
dpkg -l > "$dumpFolder/dpkg-l.txt"
apt-mark showmanual > "$dumpFolder/apt-mark-manual.txt"

# backup docker volumes
function backupVolumes {
	projectPath=$1
	shift

	if [ ! -d "$projectPath" ]; then
		echo "Project path $projectPath does not exist!"
		exit 1
	fi

	echo "Stopping containers in $projectPath"
	docker-compose -f $projectPath/docker-compose.yml stop
	for volume in "$@"; do
		echo "Backing up $volume"
		$HOME/dotfiles/bin/backup-volume $volume > "$dumpFolder/$volume.tar"
	done
	echo "Starting containers in $projectPath"
	docker-compose -f $projectPath/docker-compose.yml start
}

backupVolumes /var/web/atlas.markormesher.co.uk atlasmarkormeshercouk_postgres-data
backupVolumes /var/web/money-dashboard.markormesher.co.uk moneydashboardmarkormeshercouk_postgres-data
backupVolumes /var/web/tracker.markormesher.co.uk trackermarkormeshercouk_postgres-data

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
	| xz -4 -c | gpg2 -e -r "me@markormesher.co.uk" > "/tmp/$filename"

du -h /tmp/$filename

aws s3 cp "/tmp/$filename" "s3://mormesher.backups/$filename"
