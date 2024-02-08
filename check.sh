#!/bin/bash

info()  { 
  echo -e "\e[32m $*\e[39m"; 
  }
warn()  { 
  echo -e "\e[33m $*\e[39m"; 
  }
error() { 
  echo -e "\e[31m $*\e[39m"; 
  }
  
clear

check() {
  command kubectl get no > /dev/null 2>&1 || KUBECTL=("not found")

  if [[  $KUBECTL != "not found" ]]; then
    images=$(kubectl get po -A -o jsonpath="{.items[*].spec.containers[*].image}" | tr -s '[[:space:]]' '\n' | sort | uniq -c | awk '{print  $2}' | awk '{gsub("quay.io/", "");print}')
  else 
    images=$(docker images --format "{{.Repository}}:{{.Tag}}")
  fi

  info  "\U1F440 checks images.."

  echo ""
  
  for IMAGE in $images; do
    REPO=$(printf '%s' "$IMAGE" | cut -f1 -d":")
    VERSION=$(printf '%s' "$IMAGE" | cut -f2 -d":")
    LATEST=$(
        API=https://registry.hub.docker.com/v2/repositories/library/${REPO}/tags
        if [[  stderror ]]; then
        API=https://registry.hub.docker.com/v2/repositories/${REPO}/tags?page_size=20
        fi
        curl --silent \
        "$API" \
        | jq -r ".results[].name" | sort --version-sort -r \
        | sed '/^master/d' | sed '/^latest/d' | sed '/^sha/d' | sed '/^tilt/d' | sed '/[a-zA-Z]$/d' | sed '/[a-zA-Z647]$/d'| sed '/rc[0-9]$/d' | sed '/rc.[0-9]$/d' \
        | head -n 1   
    )

    if [[ $LATEST != $VERSION ]]; then
        warn "$REPO"  #>> /tmp/images.txt
        echo "update available: [$LATEST]"
        echo ""  
    fi
  done
}

check