#!/usr/bin/env bash
. constants.sh
VAULT=glacier_valut
START_TIME=23
END_TIME=8
prefix_length=${#PREFIX}

function fail {
  echo $1 >&2
  exit 1
}

function retry {
  local n=1
  local max=5
  local delay=15
  while true; do
    "$@" && break || {
      if [[ $n -lt $max ]]; then
        ((n++))
        echo "Command failed. Attempt $n/$max:"
        sleep $delay;
      else
        fail "The command has failed after $n attempts."
      fi
    }
  done
}

decode () {
  ret=0
  place=1
  num_digits=${#1}
  for (( index=$(($num_digits - 1)); index>=0; index-- )); do
    char=${1:$index:1}
    char_val=$(printf "%d\n" \'$char)
    ret=$(($ret + ($char_val - 97) * $place))
    place=$(($place * 26 ))
  done
  echo $ret
}
upload () {
  file_num=$(decode ${1:$prefix_length})  
  file="$3/$1"
  echo "file num: $file_num"
  start=$(( $SPLIT_SIZE * $file_num ))
  end=$(( $start + $(bytes "$file") - 1 ))
  retry aws glacier upload-multipart-part --account-id - --vault-name $VAULT --upload-id $2 --range "bytes $start-$end/$4" --body "$file" --checksum $(cat "$file" | treehash)
}

initiate () {
  if [ -f "$1/.id" ]; then
    cat "$1/.id"
  else
    ID=$(aws glacier initiate-multipart-upload --account-id - --part-size $SPLIT_SIZE  --vault-name $VAULT --archive-description "backup for $2" | awk '{print $2}')
    echo $ID > "$1/.id"
    echo $ID
  fi
}

cleanup () {
  aws glacier complete-multipart-upload --account-id - --vault-name $VAULT --upload-id "$1" --archive-size "$2" --checksum "$3"
  rm "$DIR/.id"
  rm "$DIR/.size"
  rm "$DIR/.hash"
  rmdir "$DIR"
}

check_time () {
  now=$(date "+%H")
  if [ $now -gt $END_TIME -a $now -le $START_TIME ]; then
    exit 1
  fi
}

for I in $(ls "$MY_DIR"); do
  DIR="$MY_DIR/$I"
  if [ -d "$DIR" ]; then
    ID=$(initiate $DIR $I)
    HASH=$(cat "$DIR/.hash")
    SIZE=$(cat "$DIR/.size")
    if [ "$(ls "$DIR")" ]; then
      for FILE in $(ls "$DIR"); do        
        check_time
        upload "$FILE" "$ID" "$DIR" $SIZE
        rm "$DIR/$FILE"
      done
    fi
    if [ $HASH ]; then
      cleanup "$ID" "$SIZE" "$HASH" "$DIR"
    fi 
  fi
done
