#!/bin/bash

set -e

WORK_DIR=".pcf_support"
OUTPUT_DIR="pcf_support_`date +%Y%m%d%H%M%S`"

rm -rf $WORK_DIR
mkdir -p $WORK_DIR

UAAC="eval BUNDLE_GEMFILE=/home/tempest-web/tempest/web/vendor/uaac/Gemfile bundle exec uaac --config $WORK_DIR/.uaac_support.yml"

#echo "Please enter https://OPSMAN_ADDR"
#read -p "OpsMan URL: " OPSMAN
OPSMAN_HOSTNAME=$(sudo -u postgres psql -t -d tempest_production -c "SELECT hostname FROM uaa_configs WHERE id=1" | tr -d "\ ")

$UAAC target https://$OPSMAN_HOSTNAME/uaa --skip-ssl-validation

$UAAC token owner get opsman -s \"\"

mkdir -p $OUTPUT_DIR
echo "All information fetched will be put in $OUTPUT_DIR."

OPAMAN_API="https://$OPSMAN_HOSTNAME/api/v0"
UAAC_CURL="$UAAC curl -k $OPAMAN_API"
BOSH_TARGET=""
BOSH_CMD=""
BOSH_DEPLOYMENT=""

function setup_bosh
{
  if [[ -z $BOSH_TARGET ]]; then
    BOSH_PRODUCT=$($UAAC_CURL/deployed/products | grep "guid\": \"p-bosh-" | awk '{ print $2 }' | sed s/\"//g | sed s/,//g)
    DIRECTOR_IP=$($UAAC_CURL/deployed/products/$BOSH_PRODUCT/static_ips | awk '/\"ips\"/, /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/' | tail -n 1 | sed s/\"//g | sed s/,//g | sed s/\ //g)
    BOSH_TARGET="https://$DIRECTOR_IP:25555"
    export BOSH_CLIENT=ops_manager
    export BOSH_CLIENT_SECRET=$($UAAC_CURL/deployed/director/manifest | awk '/\"ops_manager\":/, /\"secret\":/' | tail -n 1 | awk '{ print $2 }' | sed 's/\"//g' | sed 's/,//g' | sed s/\ //g)
    BOSH="eval BUNDLE_GEMFILE=/home/tempest-web/tempest/web/vendor/bosh/Gemfile bundle exec bosh --ca-cert /var/tempest/workspaces/default/root_ca_certificate -c $WORK_DIR/.bosh_config_support"
    $BOSH target $BOSH_TARGET
  fi
}

function list_and_target_deployment
{
  setup_bosh
  echo "Available deployments: "
  $BOSH deployments | awk '/bosh-/ { print $2 }'
  read -p "Enter deployment: " BOSH_DEPLOYMENT
  $BOSH download manifest $BOSH_DEPLOYMENT $WORK_DIR/$BOSH_DEPLOYMENT.yml
  $BOSH deployment $WORK_DIR/$BOSH_DEPLOYMENT.yml
}

$UAAC_CURL/diagnostic_report > $OUTPUT_DIR/diagnostic_report.log

while [ true ]
do
  echo
  echo "[1] Recent installation events
[2] Installation logs
[3] BOSH task logs
[4] BOSH deployments
[5] BOSH instances
[6] BOSH VM logs
[x] Exit"
  read -p "Select: " ITEM
  case $ITEM in
    "1")
      $UAAC_CURL/installations > $OUTPUT_DIR/installations.log
      echo "Result saved to $OUTPUT_DIR/installations.log."
      ;;
    "2")
      read -p "Installation ID: " INSTALLATION_ID
      $UAAC_CURL/installations/$INSTALLATION_ID/logs > $OUTPUT_DIR/installation-$INSTALLATION_ID.log
      echo "Result saved to $OUTPUT_DIR/installation-$INSTALLATION_ID.log."
      ;;
    "3")
      read -p "Task ID: " TASK_ID
      while [[ -z $TASK_ID ]]
      do
        read -p "Task ID: " TASK_ID
      done
      setup_bosh
      $BOSH task $TASK_ID --event > $OUTPUT_DIR/bosh_task_"$TASK_ID"_event.log
      $BOSH task $TASK_ID --cpi > $OUTPUT_DIR/bosh_task_"$TASK_ID"_cpi.log
      $BOSH task $TASK_ID --debug > $OUTPUT_DIR/bosh_task_"$TASK_ID"_debug.log
      $BOSH task $TASK_ID --result > $OUTPUT_DIR/bosh_task_"$TASK_ID"_result.log
      ;;
    "4")
      setup_bosh
      $BOSH deployments > $OUTPUT_DIR/bosh_deployments.log
      ;;
    "5")
      list_and_target_deployment
      $BOSH instances --details --dns --ps > $OUTPUT_DIR/bosh_instances_"$BOSH_DEPLOYMENT".log
      $BOSH instances --vitals > $OUTPUT_DIR/bosh_instances_"$BOSH_DEPLOYMENT"_vitals.log
      ;;
    "6")
      if [[ ! -z $BOSH_DEPLOYMENT ]]; then
        read -r -n 1 -p "The current deployment is $BOSH_DEPLOYMENT. Still on it? [Yn]"
        echo
        if [[ ! -z $REPLY && ! $REPLY =~ ^[Yy]$ ]]; then
          list_and_target_deployment
        fi
      else
        setup_bosh
      fi
      echo "Available jobs and indexes:"
      $BOSH instances | awk '/\// { print $2 }'
      read -p "Enter job: " JOB
      read -p "Enter index: " JOB_INDEX
      $BOSH logs $JOB $JOB_INDEX --dir $OUTPUT_DIR
      ;;
    "x")
      tar czf $OUTPUT_DIR.tgz $OUTPUT_DIR
      echo "All reports have been packaged into $OUTPUT_DIR.tgz."
      exit 0
  esac
  echo "Finshed."
done

