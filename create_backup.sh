#!/usr/bin/env bash
. constants.sh
BACKUP_DIRS=(/some/dir/to/backup /another/dir/to/backup)
INCREMENTAL_FILE=$MY_DIR/.incremental
TODAY_DIR=$MY_DIR/$(date "+%Y-%m-%d")
mkdir -p $TODAY_DIR
BACKUP_FILE=$MY_DIR/the_backup.tar
tar --listed-incremental=$INCREMENTAL_FILE -cvf $BACKUP_FILE "${BACKUP_DIRS[@]}"

file_size=$(bytes $BACKUP_FILE)
echo "backup file is $file_size bytes"
mod=$(($file_size % $SPLIT_SIZE)) 
add=$([ 0 -eq $mod ] && echo 0 || echo 1)
num_files=$(($file_size / $SPLIT_SIZE + $add))
echo "We will split into $num_files"
num_digits=$(($(echo "x=l($num_files)/l(26);scale=0;x/1" | bc -l) + 1 ))
split -a$num_digits -b$SPLIT_SIZE "$BACKUP_FILE" "$TODAY_DIR/$PREFIX"
echo $(cat $BACKUP_FILE | treehash) > "$TODAY_DIR/.hash"
bytes $BACKUP_FILE > "$TODAY_DIR/.size"
rm $BACKUP_FILE
