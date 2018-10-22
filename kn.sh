#!/usr/bin/env bash

################################################################################
### Michael Hausenblas, (c) 2018
### https://mhausenblas.info

set -o errexit
set -o errtrace
set -o pipefail

################################################################################
### INIT #######################################################################

### include all the functions we gonna need
source knlib.sh

### command line arguments
COMMAND="${1:-ls}"           # if no command given, default to list environments
CURRENTENV="${2:-sandbox}"   # if no environment given, default to 'sandbox'
PPORT="${3}"                 # must be provided for expose

### globals
KN_NAMESPACE=kn

### pick up environment variables, if present
if [[ -z "${KN_BASE_IMAGE}" ]]; then
  KN_BASE_IMAGE="centos:7"
else
  KN_BASE_IMAGE="${KN_BASE_IMAGE}"
fi

if [[ -z "${KN_SYNC}" ]]; then
  KN_SYNC="true"
else
  KN_SYNC="${KN_SYNC}"
fi

if [[ -z "${KN_POLICY}" ]]; then
  KN_POLICY="local"
else
  KN_POLICY="${KN_POLICY}"
fi

if [[ -z "${KN_MODE}" ]]; then
  KN_MODE="interactive"
else
  KN_MODE="${KN_MODE}"
fi

### make sure the namespace exists before we proceed
kubectl get ns | \
        grep $KN_NAMESPACE > /dev/null || (kubectl create ns $KN_NAMESPACE)

################################################################################
### MAIN #######################################################################

case $COMMAND in
ls)
  env_ls $KN_NAMESPACE
  ;;
up)
  env_up $KN_NAMESPACE $CURRENTENV $KN_BASE_IMAGE $KN_SYNC $KN_MODE $PPORT
  ;;
connect)
  env_connect $KN_NAMESPACE $CURRENTENV
  ;;
down)
  env_down $KN_NAMESPACE $CURRENTENV
  ;;
publish)
  env_publish $KN_NAMESPACE $CURRENTENV $KN_POLICY $PPORT
  ;;
help)
  print_help
  printf "\n\n"
  print_cfg $KN_BASE_IMAGE $KN_SYNC $KN_POLICY
  ;;
*)
  printf "The [$COMMAND] command is not (yet) supported!\n\n"
  print_help
esac