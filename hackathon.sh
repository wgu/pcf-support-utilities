#!/bin/bash
OUTPUT_DIR="bosh_logs_`date +%Y%m%d%H%M%S.%N`"

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
    # -j|--job)
      #   JOB = "$2"
      #   shift;;
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
bosh status > $OUTPUT_DIR/status.log
bosh releases > $OUTPUT_DIR/releases.log
bosh stemcells > $OUTPUT_DIR/stemcells.log
bosh deployments > $OUTPUT_DIR/deployments.log

# bosh instances —-details > $OUTPUT_DIR/instances.details.log
# bosh instances —ps > $OUTPUT_DIR/instances.ps.log

# bosh logs <job> <index> [—only filters]
# bosh tasks recent <50> —no-filter [—deployment deployment_name]
# bosh task <num> —debug/cpi

# Package into a tarball

# Upload
