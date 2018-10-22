################################################################################
### FUNCTIONS ##################################################################

function env_up {
    ns=$1
    currentenv=$2
    img=$3
    cppolicy=$4
    imode=$5
    pport=$6
    pod=$(kubectl -n $ns get po -l=run=$currentenv --output=jsonpath={.items[*].metadata.name})
    # create a dedicated service account:
    kubectl -n $ns create sa $currentenv > /dev/null
    # launch environment depending on mode:
    if [[ $imode = "interactive" ]]
    then
        # launch interactive environment that stays up for 24h:
        kubectl -n $ns run $currentenv --image=$img --serviceaccount=$currentenv > /dev/null 2>&1 -- sleep 86400
        # make sure the pod is running so that we can copy stuff in there:
        while true 
        do
            isrunning=$(kubectl -n $ns get po -l=run=$currentenv --output=jsonpath={.items[*].status.phase})
            printf "."
            if [[ $isrunning == "Running" ]]
            then
            break
            fi
            sleep 3
        done
        # if enabled, copy contents of current directory into environment at /tmp/work
        if [[ $cppolicy = "true" ]]
        then
            srcdir=$(pwd)
            p=$(kubectl -n $ns get po -l=run=$currentenv --output=jsonpath={.items[*].metadata.name})
            kubectl -n $ns cp $srcdir $ns/$p:/tmp/work
            printf "\nCopied content of $(pwd) to /tmp/work in the environment\n"
        fi    
        printf "The environment [$currentenv] is now ready!\nTo get into your environment, do: kn connect $currentenv\n"
    else # daemon mode
        if [[ -z "${pport}" ]]; then
            printf "No port given, use: KN_MODE=daemon kn up NAME PORT"
            exit 1
        fi
        # launch a daemon environment:
        kubectl -n $ns run $currentenv --image=$img --serviceaccount=$currentenv --port=$pport > /dev/null 2>&1
    fi
}

function env_connect {
    ns=$1
    currentenv=$2
    pod=$(kubectl -n $ns get po -l=run=$currentenv --output=jsonpath={.items[*].metadata.name})
    printf "connecting to $pod"
    kubectl -n $ns exec -it $pod -- sh
}


function env_down {
    ns=$1
    currentenv=$2
    kubectl -n $ns delete deployment $currentenv > /dev/null
    kubectl -n $ns delete sa $currentenv > /dev/null
    # TODO: fix the port-forward clean up:
    # pfpid=$(ps | grep '[9]898' | awk '{ print $1 }')
    # if [[ $pfpid != "" ]]; then
    #     # kill $pfpid
    #     printf "$pfpid"
    # fi
    printf "The environment [$currentenv] has been destroyed, all data is gone the way of the dodo\n"
}

function env_publish {
    ns=$1
    currentenv=$2
    ppolicy=$3
    pport=$4
    if [[ -z "${pport}" ]]; then
        printf "No port given, use: kn publish NAME PORT"
        exit 1
    fi
    kubectl -n $ns port-forward deployment/$currentenv 9898:$pport &
    # if enabled, publish environment to public
    if [[ $ppolicy = "public" ]]
    then
        if ! [ -x "$(command -v git)" ]; then
            printf "Sorry, need https://ngrok.com installed to publish the environment"
        else
            ngrok http 9898
        fi
    fi
}

function env_ls {
    ns=$1
    kubectl -n $ns get deploy -o=custom-columns=NAME:.metadata.name,SINCE:.metadata.creationTimestamp
}

function print_help {
    printf "I currently only know about the following commands:\n[up], [connect], [down], [publish], [ls]\n"
}

function print_cfg {
    baseimage=$1
    synccwd=$2
    policy=$3
    printf "kn is using the following settings\n"
    printf "==================================\n"
    printf "  Base image: [$baseimage] (set with KN_BASE_IMAGE)\n"
    printf "  Sync current directory: [$synccwd] (set KN_SYNC=true to enable)\n"
    printf "  Publishing policy: [$policy] (set KN_POLICY=public to expose publicy)\n"
}