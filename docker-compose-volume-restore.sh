#!/usr/bin/env bash

set -eu

usage_exit() {
  echo "Usage: $0 backup_dir [-rc]" 1>&2
  exit 1
}

dryrun=1
clean=0
while getopts rch OPT; do
  case $OPT in
    r) dryrun=0
      ;;
    c) clean=1
      ;;
    h) usage_exit
      ;;
    \?) usage_exit
      ;;
  esac
done

shift $((OPTIND - 1))

get_abspath(){
  echo $(cd $1 && pwd)
}

backup_dir=$(get_abspath $1)

if (( $dryrun == 0)); then
  echo "====This is NOT dryrun===="
else
  echo "====This is dryrun===="
fi

docker-compose ps -q |
  xargs -n1 docker inspect --format='{{ range .Mounts }}{{if eq .Type "volume"}}{{println .Name}}{{end}}{{end}}' |
  grep . | while read volume_name; do
    clean_cmd="docker run --rm -v $volume_name:/data ubuntu rm -rf /data/* "
    restore_cmd="docker run --rm -v $backup_dir:/backup -v $volume_name:/data ubuntu tar -zxvf /backup/$volume_name.tar.gz -C /data"
    if [[ ! -e $backup_dir/$volume_name.tar.gz ]]; then
      break
    fi
    if (($clean == 1)); then
      echo $clean_cmd
    fi
    echo $restore_cmd
    if (($dryrun == 0)); then
      if (($clean == 1)); then
        echo real $clean_cmd
      fi
      echo real $restore_cmd
    fi
  done

docker-compose ps -q |
  xargs -n1 docker inspect --format='{{ range .Mounts }}{{if eq .Type "bind"}}{{println .Source}}{{end}}{{end}}' |
  grep . | while read volume_name; do
    tmp=${volume_name#\/}
    backup_filename=${tmp//\//_}
    clean_cmd="docker run --rm -v $volume_name:/data ubuntu rm -rf /data/* "
    restore_cmd="docker run --rm -v $backup_dir:/backup -v $volume_name:/data ubuntu tar -zxvf /backup/$backup_filename.tar.gz -C /data"
    if [[ ! -e $backup_dir/$backup_filename.tar.gz ]]; then
      break
    fi
    if (($clean == 1)); then
      echo $clean_cmd
    fi
    echo $restore_cmd
    if (($dryrun == 0)); then
      if (($clean == 1)); then
        echo real $clean_cmd
      fi
      echo real $restore_cmd
    fi
  done
