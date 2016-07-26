#!/bin/bash

set -e

OUTPUT_DIR="pcf_support_`date +%Y%m%d%H%M%S`"
UAAC_PATH="uaac"

if [[ -z $UAAC_PATH ]]; then
  echo "This script requires uaac. Enter the path to it: "
  read UAAC_PATH
fi

UAAC="$UAAC_PATH --config support_uaac.yml"

echo "Please enter https://OPSMAN_ADDR"
read -p "OpsMan URL: " OPSMAN

$UAAC target $OPSMAN/uaa --skip-ssl-validation

$UAAC token owner get opsman -s ""

mkdir -p $OUTPUT_DIR
echo "All information fetched will be put in $OUTPUT_DIR."

OPAMAN_API=$OPSMAN/api/v0
UAAC_CURL="$UAAC curl -k $OPAMAN_API"

$UAAC_CURL/diagnostic_report > $OUTPUT_DIR/diagnostic_report.log 2>&1

while [ true ]
do
  echo "[1] Recent installation events
[2] Fetch installation logs
[3] Something
[x] Exit"
  read -p "Select: " ITEM
  case $ITEM in
    "1")
      $UAAC_CURL/installations > $OUTPUT_DIR/installations.log 2>&1
      ;;
    "2")
      read -p "Installation ID: " INSTALLATION_ID
      $UAAC_CURL/installations/$INSTALLATION_ID/logs > $OUTPUT_DIR/installation-$INSTALLATION_ID.log 2>&1
      ;;
    "x")
      exit 0
  esac
done
