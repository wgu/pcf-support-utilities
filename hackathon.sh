#!/bin/bash
OUTPUT_DIR="pcf_support_`date +%Y%m%d%H%M%S`"

if !command -v bosh > /dev/null 2>&1; then
  echo "Error: bosh command not found"
  exit 1
fi

# Parse argument
while [[ $# > 1 ]]; do
  key="$1"
  case $key in
    -t|--target)
      TARGET="$2"
      shift
      ;;
    -u|--username)
      USERNAME="$2"
      shift
      ;;
    -p|--password)
      PASSWORD="$2"
      shift
      ;;
    -j|--job)
        JOB = "$2"
        shift;;
    -l|--upload)
      UPLOAD="$2"
      shift
      ;;
    *)
      echo "Error: Invalid argument: $key"
      exit 1
      ;;
  esac
  shift
done

if [[ -z $TARGET ]]; then
  echo "Error: Missing bosh target"
  exit 1
fi

# Login
bosh target $TARGET
bosh login $USERNAME $PASSWORD

mkdir -p $OUTPUT_DIR

# Run Bosh commands
echo "Fetching Bosh status..."
bosh status > $OUTPUT_DIR/status.log 2>&1
echo "Fetching releases..."
bosh releases > $OUTPUT_DIR/releases.log 2>&1
echo "Fetching stemcells..."
bosh stemcells > $OUTPUT_DIR/stemcells.log 2>&1
echo "Fetching available deployments..."
bosh deployments 2>$OUTPUT_DIR/deployments.log | tee $OUTPUT_DIR/deployments.log

read -p "Select deployment: " DEPLOYMENT
DEPLOYMENT_YAML=$OUTPUT_DIR/$DEPLOYMENT.yml
if [[ -n $DEPLOYMENT ]]; then
  bosh download manifest $DEPLOYMENT $DEPLOYMENT_YAML > $OUTPUT_DIR/download_manifest.log 2>&1
  while [[ $? != 0 ]]; do
    echo "Wrong deployment: $DEPLOYMENT"
    read -p "Select deployment: " DEPLOYMENT
    if [[ -n $DEPLOYMENT ]]; then
      bosh download manifest $DEPLOYMENT $DEPLOYMENT_YAML > $OUTPUT_DIR/download_manifest.log 2>&1
    fi
  done
else
  echo "Skipped fetching deployment information."
fi

if [[ -s $DEPLOYMENT_YAML ]]; then
  echo "Setting deployment..."
  bosh deployment $DEPLOYMENT_YAML > $OUTPUT_DIR/deployment.log 2>&1
  echo "Fetching process information..."
  bosh instances --ps > $OUTPUT_DIR/instances.ps.log 2>&1
  echo "Fetching instance details..."
  bosh instances --details 2>$OUTPUT_DIR/instances.details.log | tee $OUTPUT_DIR/instances.details.log 2>&1
  read -p "Select job: " JOB
  if [[ -n $JOB ]]; then
    read -p "Select index: " JOB_INDEX
    while [[ -z $JOB_INDEX ]]; do
      read -p "Select index: " JOB_INDEX
    done
    echo "Fetching job logs..."
    bosh logs $JOB $JOB_INDEX --dir $OUTPUT_DIR > $OUTPUT_DIR/$JOB.$JOB_INDEX.log 2>&1
  else
    echo "Skipped fetching job logs."
  fi
fi

echo "Fetching 100 most recent bosh task records..."
bosh tasks recent 100 --no-filter > $OUTPUT_DIR/tasks.log 2>&1
read -p "Task ID: " TASK_ID
if [[ -n $TASK_ID ]]; then
  echo "Fetching task debug log..."
  bosh task $TASK_ID --debug > $OUTPUT_DIR/task.$TASK_ID.debug.log 2>&1
  echo "Fetching task event log..."
  bosh task $TASK_ID --event > $OUTPUT_DIR/task.$TASK_ID.event.log 2>&1
  echo "Fetching task cpi log..."
  bosh task $TASK_ID --cpi > $OUTPUT_DIR/task.$TASK_ID.cpi.log 2>&1
else
  echo "Skipped fetching task logs."
fi

# Package into a tarball
echo "Packaging logs..."
tar czf $OUTPUT_DIR.tgz $OUTPUT_DIR

# Upload

echo "Done."
