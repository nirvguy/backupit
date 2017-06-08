# Backupit #

This is a script for make rotatory and full backups using rsync and bash.

- fixed backups: full backup, ie. copy all content always even if wasn't changes.
- rotatory backups: copy only files that was changed from the previous backup, and, for
	those who wasnt changed, it place a hard link to the same file backuped in
	the previous backup. This mantains the directory structure of the snapshot
	and source folder identically but ocupying much less space than a full
	backup.

For the rotatory backups the naming convention for a snapshot prefix name
"snap." for example is snap.0, snap.1, snap.2, and so on. snap.0 is the last
recent snapshot. snap.1 is the is the last to last recent snapshot and so on.
To mantain this, every time a rotatory backup begins the folders moves to the
next number (snap.0 to snap.1, snap.1 to snap.2, and so on) to make a place for
the new snapshot. If the number reaches the MAX_LEVEL then the oldest backup
will be discarded.

For the fixed bakup only a snap.0 will be created and replaced if already exists.

## Configuration file ##

The input of the program is a configuration file.
The configuration file contains the folowing environment variables

* SOURCE_DIR: Directory where its placed the data to backup.
* SNAPSHOPT_DEST: Directory where the backups were be placed.
* TYPE: fixed or rotatory.
* SNAPSHOT_PREFIX: Prefix of the snaphhot name folder. Example: SNAPSHOT=snap_, so then
the backups folder where be snap_0, snap_1, snap_2, etc.. Default is snapshot
* MAX_LEVEL: In case of rotatory type backup its the total number of spanshots folder that will
be created and after that it will start cycling.
* EXLUDE_LIST: File with list of files/folder per line to exclude from the backup that are
usually inside a folder that is already part of the backup.


## Usage ##

1. Create a config file as explained before with cfg extension. snap_home.cfg for example.

```bash
SOURCE_DIR=/home/myuser/
SNAPSHOT_DEST=/mnt/myuser/backups/home/
SNAPSHOT_PREFIX=snap_
TYPE=rotatory
MAX_LEVEL=12
```


2. Create along config file (in the same directory level) with the same name but with extension
source. In the example, snap_home.sources. In this file are every directory you want to backup
inside the SOURCE_DIR specified in config file. Example:

```
Documents/
Images/
.vim/
.vimrc
```

3. Run ./backupit snap_home.cfg


## TODO ##

* Make an install script.
* Do more tests
* Extend script to configure cron or systemd to
  run periodically backups.
