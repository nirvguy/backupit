bkrootdir=`mktemp -d /tmp/bktest_XXX`
LS=/bin/ls
srcdir="$bkrootdir/source"
bkdir="$bkrootdir/backup"
cfgfile="$bkrootdir/test.cfg"
srcfile="$bkrootdir/test.sources"
TEST_PASSED=0
TEST_TOTAL=0

abort() {
	echo "$@" >&2
	exit 1
}

getinode() {
	if [ ! -f $1 ]; then
		echo "Could not open $1: file no exists" 2>&1
		return 1
	fi

	$LS -i $1 | cut -d ' ' -f 1
}

assert() {
	if [ -z $1 ]; then
		return 1
	fi

	local lineno=$1
	shift

	if test $@; then
		echo -e "[$lineno]: \e[1;92mOK\e[0m"
		TEST_PASSED=$((TEST_PASSED+1))
	else
		echo -e "[$lineno]: $@: \e[1;91mTEST FAIL\e[0m"
		# rm -rf $bkrootdir
	fi
	TEST_TOTAL=$((TEST_TOTAL+1))
}

