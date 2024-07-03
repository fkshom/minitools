#!/usr/bin/env bash

basefilename="/tmp/basefile.txt"
tmpfilename="/tmp/tmpfile.txt"

ps -A o user,pid,ppid,tty,stat,start,command | grep -v ps | grep -v zabbix | grep -v $$ | grep -v grep > $tmpfilename

diff $basefilename $tmpfilename;

if [ $? = 1 ];  then
  echo "difference exists"
  cp $tmpfilename $basefilename
  git add $basefilename
  git commit -m "difference exists"
else
  echo "Not difference"
fi
