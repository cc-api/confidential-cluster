#!/bin/bash

PROJECT_ID=""
VM_NAME="vm_test"
EXTERNAL_IP=""
PUB_KEY=""


function usage {
    cat << EOM
usage: $(basename "$0") [OPTION]...
    -i <project id> the GCP project id
    -n <vm name> the VM name
    -e <external IP> external IP of the VM
    -k <public key> ssh public key
EOM
    exit 1
}

function process_args {
while getopts ":i:n:e:k:" option; do
        case "${option}" in
            i) PROJECT_ID=${OPTARG};;
            n) VM_NAME=${OPTARG};;
            e) EXTERNAL_IP=${OPTARG};;
            k) PUB_KEY=${OPTARG};;
            h) usage;;
            *) echo "Invalid option: -${OPTARG}" >&2
               usage
               ;;
        esac
    done

    if [[ -z "$EXTERNAL_IP" ]]; then
        echo "Warning: Please set external IP or you won't be able to ssh the VM."
            exit 1
    fi

    if [[ -z "$PROJECT_ID" ]]; then
        echo "ERROR: Please pass project ID."
            exit 1
    fi

    if [[ -z "$PUB_KEY" ]]; then
        echo "ERROR: Please pass public key."
            exit 1
    fi
}
process_args "$@"

curl -X POST \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -H "Content-Type: application/json" \
     -d '{
            "machineType": "zones/us-central1-a/machineTypes/c3-standard-4",
            "metadata": {
                "items": [
                    {
                        "key": "ssh-keys",
                        "value": "$PUB_KEY"
                    }
                ]
            },
           "name": "'$VM_NAME'",
           "confidentialInstanceConfig": {
                "confidentialInstanceType": "TDX"
            },
            "disks": [
                {
                    "boot": true,
                    "initializeParams": {
                        "diskSizeGb": "100",
                        "sourceImage": "projects/tdx-guest-images/global/images/ubuntu-2204-jammy-v20240501"
                    }
                }
           ],
            "networkInterfaces": [
                {
                    "accessConfigs": [
                        {
                            "name": "External NAT",
                            "natIP": "'$EXTERNAL_IP'",
                        }
                    ],
                    "stackType": "IPV4_ONLY",
                    "subnetwork": "projects/'$PROJECT_ID'/regions/us-central1/subnetworks/default"
                }
           ],
           "scheduling": {
                "automaticRestart": true,
                "nodeAffinities": [],
                "onHostMaintenance": "TERMINATE",
                "preemptible": false
            }
        }' \
    https://compute.googleapis.com/compute/beta/projects/$PROJECT_ID/zones/us-central1-a/instances

