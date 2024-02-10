#!/bin/bash

INFO()  { 
  echo -e "\e[32m $*\e[39m"; 
  }
WARN()  { 
  echo -e "\e[33m $*\e[39m"; 
  }
# error() { 
#   echo -e "\e[31m $*\e[39m"; 
#   }
  
clear

SPIN() {
pid=$! 
spin='🔍🔎🔍🔎'
i=0

while kill -0 $pid 2>/dev/null
do
  i=$(( (i+1) %4 ))
  printf "\r${spin:$i:1}"
  sleep 1
done
}

SCAN() {
command kubectl get no > /dev/null 2>&1 || KUBECTL=("not found")

if [[  $KUBECTL != "not found" ]]; then
  images=$(kubectl get po -A -o jsonpath="{.items[*].spec.containers[*].image}" | tr -s '[[:space:]]' '\n' | sort | uniq -c | awk '{print  $2}' | awk '{gsub("quay.io/", "");print}')
else 
  images=$(docker images --format "{{.Repository}}:{{.Tag}}")
fi

Images=mariadb:11.2.1
for IMAGE in $images; do
  REPO=$(printf '%s' "$IMAGE" | cut -f1 -d":")
  VERSION=$(printf '%s' "$IMAGE" | cut -f2 -d":")
  LIBRARY=$(printf '%s' "$REPO" | grep /)
  APIREPO="https://registry.hub.docker.com/v2/repositories/${REPO}/tags?page_size=40"
  APILIBRARY="https://registry.hub.docker.com/v2/repositories/library/${REPO}/tags?page_size=40"
  LATEST=$(
      if [[ $REPO == "koenkk/zigbee2mqtt" ]]; then
      curl --silent $APIREPO \
      | jq -r ".results[].name" | sort --version-sort -r \
      | sed '/^[master|sha|latest|tilt]/d' \
      | sed '/v[0-9].[0-9][0-9].[0-9]$/d' \
      | head -n 1
      elif [[ -z $LIBRARY ]]; then
      curl --silent $APILIBRARY \
      | jq -r ".results[].name" | sort --version-sort -r \
      | sed '/^[master|sha|latest|tilt]/d' \
      | sed '/[a-zA-Z647]$/d' \
      | sed '/rc[0-9]$/d' \
      | sed '/rc.[0-9]$/d' \
      | sed '/pre.[0-9]$/d' \
      | sed '/dev-2024[0-9][0-9][0-9][0-9]$/d' \
      | head -n 1
      elif [[ ! -z $LIBRARY ]]; then
      curl --silent $APIREPO \
      | jq -r ".results[].name" | sort --version-sort -r \
      | sed '/^[master|sha|latest|tilt]/d' \
      | sed '/[a-zA-Z647]$/d' \
      | sed '/rc[0-9]$/d' \
      | sed '/rc.[0-9]$/d' \
      | sed '/pre.[0-9]$/d' \
      | sed '/dev-2024[0-9][0-9][0-9][0-9]$/d' \
      | head -n 1
      else
      error "error"
      exit 1
      fi    
  )    

  if [[ $LATEST != $VERSION ]]; then
  WARN "   $REPO:[$LATEST]"  >> /tmp/images.txt
  fi
done
}

INFO "scan.."

echo ""

SCAN & SPIN

clear

if [[ -f /tmp/images.txt ]]; then
INFO "\U2757 update available:"
cat /tmp/images.txt
rm /tmp/images.txt
else
INFO "\U2705 images is up to date"
fi