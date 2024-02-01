#!/bin/bash
clear
echo "
██████╗██╗  ██╗███████╗ ██████╗██╗  ██╗
██╔════╝██║  ██║██╔════╝██╔════╝██║ ██╔╝
██║     ███████║█████╗  ██║     █████╔╝
██║     ██╔══██║██╔══╝  ██║     ██╔═██╗
╚██████╗██║  ██║███████╗╚██████╗██║  ██╗
╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝
"
sleep 3
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

info "cheks images.."

for IMAGE in $images; do
  docker pull $IMAGE > /dev/null 2>&1
  exit_code=$?
  if [ $exit_code = 1 ]; then
    error "$IMAGE pull error" 
  fi

  REPO=$(printf '%s' "$IMAGE" | cut -f1 -d":")
  VERSION=$(printf '%s' "$IMAGE" | cut -f2 -d":")
  INSTALLED=$(docker image inspect $IMAGE | jq -r '.[].RepoDigests[]' | awk -F@ '{print $2}')
  docker pull $REPO > /dev/null 2>&1
  exit_code=$?

  if [ $exit_code = 1 ]; then
      error "$REPO pull error" 
  fi

  LATEST=$(docker image inspect $REPO | jq -r '.[].RepoDigests[]' | awk -F@ '{print $2}')
  if [[ $INSTALLED != $LATEST ]]  && [[ ! -z $LATEST ]] ; then
      warn "$IMAGE" >> /tmp/images.txt 
  fi
done

info "[images necessary update]"
cat /tmp/images.txt
rm /tmp/images.txt
