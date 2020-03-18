#!/bin/bash

# Must be run from inside pEp4iOS scripts dir
dir="$1"

# No directory has been provided, use current
if [ -z "$dir" ]
then
    dir="`pwd`"
fi

CHANGESET="${dir}/../../CHANGESETS"
rm -f $CHANGESET
touch $CHANGESET

# cd in src folder
cd ../../..

pwd

dir="`pwd`"

# Print version
#printf %s  "v" >> $CHANGESET

#INFO_PLIST=${dir}/pEp_for_iOS/pEpForiOS/Info.plist
#VERSION=$(/usr/libexec/PlistBuddy -c "Print :MARKETING_VERSION" "${INFO_PLIST}")
#echo "${VERSION}" >> $CHANGESET



# Make sure directory ends with "/"
if [[ $dir != */ ]]
then
	dir="$dir/*"
else
	dir="$dir*"
fi

# Loop all sub-directories
for f in $dir
do
	# Only interested in directories
	[ -d "${f}" ] || continue

	# Check if directory is a git repository
	if [ -d "$f/.git" ]
	then
		cd $f

		REPO_NAME="$(basename $f)"
		printf %s  "${REPO_NAME}: " >> $CHANGESET
		git rev-parse HEAD >> $CHANGESET

	# Check if directory is a HG repository
	elif [ -d "$f/.hg" ]
	then
		cd $f
		REPO_NAME="$(basename $f)"
		printf %s  "${REPO_NAME}: " >> $CHANGESET
		hg id -i  >> $CHANGESET
	else
		echo "No git nor HG: ${f}"
	fi
done
