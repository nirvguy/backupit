#!/bin/bash
# A rsync-based tool for incremental backup

SOURCE_DIR=
BACKUP_DIR=
BACKUP_TYPE=
BACKUP_MAX=
BACKUP_PREFIX=bk
RSYNC=/bin/rsync

debug() {
	[[ $DEBUG ]] && "$@" || true
}

abort() {
	echo "$@" >&2
	echo "Aborting backup!" >&2
	exit 1
}

read_config() {
	local varname
	local value
	local lineno=1
	while read line; do
		if echo $line | grep -F = &>/dev/null; then
			varname=$(echo $line | cut -d '=' -f 1)
			value="$(echo $line | cut -d '=' -f 2)"
			case $varname in
				SOURCE_DIR)
					[[ ! -z $value ]] ||
					    abort "$1: $lineno: $varname: Source directory cannot be empty!"
					[[ -d "$value" ]] ||
					    abort "$1: $lineno: $varname: ${value} directory not found"
					SOURCE_DIR="$value"
					;;
				BACKUP_DIR)
					[[ ! -z $value ]] ||
					    abort "$1: $lineno: $varname: Backup directory cannot be empty!"
					[[ -d "$value" ]] ||
					    abort "$1: $lineno: $varname: ${value} directory not found"
					BACKUP_DIR="$value"
					;;
				TYPE)
					[[ "$value" == fixed || "$value" == rotatory ]] ||
					    abort "$1: $lineno: $varaneme: ${value} is not a valid backup type"
					BACKUP_TYPE=$value
					;;
				PREFIX)
					[[ $value =~ ^[a-zA-Z0-9]*$ ]] ||
					    abort "$1: $lineno: $varname: $value is not a valid prefix"
					BACKUP_PREFIX="$value"
					;;
				MAX)
					[[ $BACKUP_MAX =~ ^[0-9]*$ ]] ||
					    abort "$1: $lineno: $varname: $value is not an integer"
					BACKUP_MAX=$value
					;;
			esac
		fi
		lineno=$((lineno + 1))
	done < $1
}

cycle_backups() {
	local bk_prefix="${BACKUP_DIR}/${BACKUP_PREFIX}"
	local last_bk="${bk_prefix}.${BACKUP_MAX}"
	[ -f "${last_bk}" ] && rm -rf "${last_bk}"
	for (( i = BACKUP_MAX; i > 0; i-- )); do
		local prev_bk="${bk_prefix}.$((i-1))"
		[ -d "${prev_bk}" ] && mv "${prev_bk}" "${bk_prefix}.$i"
	done
}

usage() {
	echo "./backup.sh CONFIG_FILE"
}

backup() {
	local file="${SOURCE_DIR}/$1"

	if [[ ! -f "$file" ]] && [[ ! -d "$file" ]]; then
		echo "$file: file/dir not found!"
		return
	fi

	local dir_prefix=${BACKUP_DIR}/${BACKUP_PREFIX}
	if [[ -f "$file" ]]; then
		local link_dest="$(dirname "${dir_prefix}.1/$1")"
	else
		local link_dest="$dir_prefix.1/$1"
	fi

	mkdir -p "$(dirname "${dir_prefix}.0/$1")"

	if [[ -d "${dir_prefix}.1/$1" ]] ||
		 [[ -f "${dir_prefix}.1/$1" ]]; then
		$RSYNC \
			 -Ha --delete \
			 --link-dest="$link_dest" \
			 "$file" "${dir_prefix}.0/$1"
	else
		$RSYNC \
			 -Ha --delete \
			 "$file" "${dir_prefix}.0/$1"
	fi
}

BACKUP_CFG="$1"

if [[ -z $BACKUP_CFG ]]; then
	usage
	exit 1
fi

[[ -f $BACKUP_CFG ]] || abort "Not config file $BACKUP_CFG founded!"

read_config $BACKUP_CFG

[[ ! -z $SOURCE_DIR ]] || abort "Not source directory specified!"
[[ ! -z $BACKUP_DIR ]] || abort "Not backup directory specified!"
[[ ! -z $BACKUP_TYPE ]] || abort "Not backup type specified!"

if [[ $BACKUP_TYPE == "rotatory" ]]; then
	[[ ! -z $BACKUP_MAX ]] || abort "MAX cannot be empty"
fi

case $BACKUP_TYPE in
	rotatory)
		debug echo "Rotatory backup!"
		cycle_backups
		;;
	fixed)
		debug echo "Fixed backup!"
		;;
	*)
		abort "Unexpected $BACKUP_TYPE type"
esac

BACKUP_SOURCES=${BACKUP_CFG%.cfg}.sources

[[ -f $BACKUP_SOURCES ]] || abort "could not find ${BACKUP_SOURCES}"

while read source; do
	backup $source
done < $BACKUP_SOURCES
