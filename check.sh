#!/bin/bash

INFO()  { 
  echo -e "\e[32m $*\e[39m"; 
  }
WARN()  { 
  echo -e "\e[33m $*\e[39m"; 
  }
ERROR() { 
  echo -e "\e[31m $*\e[39m"; 
  }
  
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
  images=$(kubectl get po -A -o jsonpath="{.items[*].spec.containers[*].image}" | tr -s '[[:space:]]' '\n' | sort | uniq -c | awk '{print  $2}' | awk '{gsub("quay.io/", "");print}' | awk '{gsub("docker.io/", "");print}')
else 
  images=$(docker images --format "{{.Repository}}:{{.Tag}}")
fi

#Images=neuvector/controller:5.3.0
for IMAGE in $images; do
REPO=$(printf '%s' "$IMAGE" | cut -f1 -d":")
VTAG=$(printf '%s' "$IMAGE" | cut -f2 -d":" | cut -b1)
VERSION=$(printf '%s' "$IMAGE" | cut -f2 -d":")
LIBRARY=$(printf '%s' "$REPO" | grep /)
APIREPO="https://registry.hub.docker.com/v2/repositories/${REPO}/tags?page_size=50"
APILIBRARY="https://registry.hub.docker.com/v2/repositories/library/${REPO}/tags?page_size=50"
LATEST=$(
  if [[ $REPO == "koenkk/zigbee2mqtt" ]]; then
  curl --silent $APIREPO \
  | jq -r ".results[].name" | sort --version-sort -r \
  | grep  -E -x '([0-9]+).[0-9]+.[0-9]+' \
  | head -n 1

  elif [[ ($REPO == "neuvector/controller") || ($REPO == "neuvector/enforcer") || ($REPO == "neuvector/manager") || ($REPO == "neuvector/scanner") ]]; then
  curl --silent https://registry.hub.docker.com/v2/repositories/${REPO}/tags?page_size=10 \
  | jq -r ".results[].name" | sort --version-sort -r \
  | grep  -E -x '([0-9]+).[0-9]+.[0-9]+' \
  | head -n 1

  elif [[ $REPO == "rabbitmq" ]]; then
  curl --silent $APILIBRARY \
  | jq -r ".results[].name" | sort --version-sort -r \
  | grep  -E -x '[0-9]+.[0-9]+.[0-9]+-management-alpine' \
  | head -n 1

  elif [[ -z $LIBRARY ]]; then
  curl --silent $APILIBRARY \
  | jq -r ".results[].name" | sort --version-sort -r \
  | grep  -E -x '(v[0-9]+||[0-9]+).[0-9]+.[0-9]+' \
  | head -n 1

  elif [[ ! -z $LIBRARY ]]; then
  curl --silent $APIREPO \
  | jq -r ".results[].name" | sort --version-sort -r \
  | grep  -E -x '(v[0-9]+||[0-9]+).[0-9]+.[0-9]+' \
  | head -n 1

  else
  ERROR "error"
  exit 1
  fi
)

if [[ $LATEST != $VERSION ]]; then
  echo "$IMAGE" >> /tmp/images.txt; INFO "|____$LATEST" >> /tmp/images.txt
fi
done
}

INFO "scan.."

echo ""

SCAN & SPIN

clear

if [[ -f /tmp/images.txt ]]; then
  WARN "\U2757 update available:"
  cat /tmp/images.txt
  rm /tmp/images.txt

else
  INFO "\U2705 images is up to date"
fi