#!/usr/bin/env bash

now=$(date)
echo ""
echo ""
echo "Running $0 at $now"

set -e

keepDaily=7
keepWeekly=4
keepMonthly=6

allFiles=$(aws s3 ls s3://mormesher.backups | awk '{ print $4 }')
hosts=("chuck" "casey")

for host in "${hosts[@]}"; do

	echo "Cleaning files for $host"

	hostFiles=$(echo "$allFiles" | grep "$host" || true)
	dailyFiles=$(echo "$hostFiles" | grep 'daily' || true)
	weeklyFiles=$(echo "$hostFiles" | grep 'weekly' || true)
	monthlyFiles=$(echo "$hostFiles" | grep 'monthly' || true)

	dailyToDelete=$(echo "$dailyFiles" | sort | head -n -$keepDaily)
	weeklyToDelete=$(echo "$weeklyFiles" | sort | head -n -$keepWeekly)
	monthlyToDelete=$(echo "$monthlyFiles" | sort | head -n -$keepMonthly)

	cat <(echo "$dailyToDelete") <(echo "$weeklyToDelete") <(echo "$monthlyToDelete") | sed '/^$/d' | while read file; do
		echo "DELETE $file"
		aws s3 rm "s3://mormesher.backups/$file"
	done

done
