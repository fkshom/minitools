#!/usr/bin/env bash

set -eu

usage_exit() {
  echo "Usage: $0 [-r]" 1>&2
  exit 1
}

dryrun=1
while getopts rh OPT; do
  case $OPT in
    r) dryrun=0
      ;;
    h) usage_exit
      ;;
    \?) usage_exit
      ;;
  esac
done

shift $((OPTIND - 1))

current_datetime=$(date '+%Y%m%d_%H%M%S')
backup_destination=$(pwd)/backup.$current_datetime

if (( $dryrun == 0)); then
  echo "====This is NOT dryrun===="
  mkdir $backup_destination
else
  echo "====This is dryrun===="
fi

docker-compose ps -q |
  xargs -n1 docker inspect --format='{{ range .Mounts }}{{if eq .Type "volume"}}{{println .Name}}{{end}}{{end}}' |
  grep . | while read volume_name; do
    backup_cmd="docker run --rm -v $backup_destination:/backup -v $volume_name:/data ubuntu tar -zcvf /backup/$volume_name.tar.gz -C /data ."
    echo $backup_cmd
    if (($dryrun == 0)); then
      $backup_cmd
    fi
  done

docker-compose ps -q |
  xargs -n1 docker inspect --format='{{ range .Mounts }}{{if eq .Type "bind"}}{{println .Source}}{{end}}{{end}}' |
  grep . | while read volume_name; do
    tmp=${volume_name#\/}
    backup_filename=${tmp//\//_}
    backup_cmd="docker run --rm -v $backup_destination:/backup -v $volume_name:/data ubuntu tar -zcvf /backup/$backup_filename.tar.gz -C /data ."
    echo $backup_cmd
    if (($dryrun == 0)); then
      $backup_cmd
    fi
  done
