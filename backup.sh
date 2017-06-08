#!/bin/bash
# A rsync-based tool for incremental backup

SOURCE_DIR=
SNAPSHOT_DEST=
TYPE=
MAX_LEVEL=
EXCLUDE_LIST=
SNAPSHOT_PREFIX=snapshot
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
		if echo $line | grep -F '#' &>/dev/null; then
			continue
		fi
		echo $line | grep -F = &>/dev/null || \
		  abort "$1: $lineno: Linea invalida"
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
			SNAPSHOT_DEST)
				[[ ! -z $value ]] ||
						abort "$1: $lineno: $varname: Backup directory cannot be empty!"
				[[ -d "$value" ]] ||
						abort "$1: $lineno: $varname: ${value} directory not found"
				SNAPSHOT_DEST="$value"
				;;
			TYPE)
				[[ "$value" == fixed || "$value" == rotatory ]] ||
						abort "$1: $lineno: $varaneme: ${value} is not a valid backup type"
				TYPE=$value
				;;
			SNAPSHOT_PREFIX)
				[[ $value =~ ^[a-zA-Z0-9]*$ ]] ||
						abort "$1: $lineno: $varname: $value is not a valid prefix"
				SNAPSHOT_PREFIX="$value"
				;;
			MAX_LEVEL)
				[[ $MAX_LEVEL =~ ^[0-9]*$ ]] ||
						abort "$1: $lineno: $varname: $value is not an integer"
				MAX_LEVEL=$value
				;;
			EXCLUDE_LIST)
				EXCLUDE_LIST=$value
				;;
			*)
				abort "$1: $lineno: $varname: Unrecognized option"
				;;
		esac
		lineno=$((lineno + 1))
	done < $1
}

cycle_backups() {
	local bk_prefix="${SNAPSHOT_DEST}/${SNAPSHOT_PREFIX}"
	local last_bk="${bk_prefix}.${MAX_LEVEL}"
	[ -f "${last_bk}" ] && rm -rf "${last_bk}"
	for (( i = MAX_LEVEL; i > 0; i-- )); do
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

	local dir_prefix=${SNAPSHOT_DEST}/${SNAPSHOT_PREFIX}
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
[[ ! -z $SNAPSHOT_DEST ]] || abort "Not backup directory specified!"
[[ ! -z $TYPE ]] || abort "Not backup type specified!"

if [[ $TYPE == "rotatory" ]]; then
	[[ ! -z $MAX_LEVEL ]] || abort "MAX_LEVEL cannot be empty"
fi

case $TYPE in
	rotatory)
		debug echo "Rotatory backup!"
		cycle_backups
		;;
	fixed)
		debug echo "Fixed backup!"
		;;
	*)
		abort "Unexpected $TYPE type"
esac

BACKUP_SOURCES=${BACKUP_CFG%.cfg}.sources

[[ -f $BACKUP_SOURCES ]] || abort "could not find ${BACKUP_SOURCES}"

while read source; do
	backup $source
done < $BACKUP_SOURCES
