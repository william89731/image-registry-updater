#!/bin/bash

clear
function info  { echo -e "\e[32m $*\e[39m"; }
function warn  { echo -e "\e[33m $*\e[39m"; }
function error { echo -e "\e[31m $*\e[39m"; }


command kubectl get no > /dev/null 2>&1 || KUBECTL=("not found")

if [[  $KUBECTL != "not found" ]]; then
  images=$(kubectl get po -A -o jsonpath="{.items[*].spec.containers[*].image}" | tr -s '[[:space:]]' '\n' | sort | uniq -c | awk '{print  $2}')
else 
  images=$(docker images --format "{{.Repository}}:{{.Tag}}")
fi

info  "\U1F440 checks images.."
for IMAGE in $images; do
  docker pull $IMAGE > /dev/null 2>&1
  exit_code=$?
  if [ $exit_code = 1 ]; then
    error "$IMAGE pull error" 
  fi
  REPO=$(printf '%s' "$IMAGE" | cut -f1 -d":")
  VERSION=$(printf '%s' "$IMAGE" | cut -f2 -d":")
  

  docker pull $REPO > /dev/null 2>&1

  exit_code=$?
  if [ $exit_code = 1 ]; then
      error "\U26D4 $REPO" 
  fi

  INSTALLED=$(docker image inspect $IMAGE | jq -r '.[].RepoDigests[]' | awk -F@ '{print $2}')
  LATEST=$(docker image inspect $REPO | jq -r '.[].RepoDigests[]' | awk -F@ '{print $2}')
  if [[ $INSTALLED != $LATEST ]]  && [[ ! -z $LATEST ]] ; then
      echo "$IMAGE" >> /tmp/images.txt 
  fi
  
done

docker image prune -a --force > /dev/null 2>&1

if [[ ! -f /tmp/images.txt ]]; then
  info "\U2705 images updates"
else
  warn "\U2757 images found:"
  cat /tmp/images.txt
  rm /tmp/images.txt
fi
