#!/bin/bash

COMMAND="${1}"
PROJECT="ammmia"
LOCATION="westeurope"
UNIQUE_FIX=${RANDOM}
RESOURCE_GROUP=${PROJECT}-${UNIQUE_FIX}
SB_NAME=${PROJECT}-sb-${UNIQUE_FIX}
SB_NAMESPACE=${PROJECT}-sbns-${UNIQUE_FIX}
SB_SEND_TOPIC="send"
SB_RECEIVE_TOPIC="receive"
SB_PROCESS_TOPIC="process"
SB_TRANSFORM_TOPIC="transform"

function create_resource_group() {
    # create resource group
    echo "creating resource group: ${RESOURCE_GROUP}"
    az group create --location ${LOCATION} --name ${RESOURCE_GROUP}
}

function create_service_bus() {
    # create namespace in service bus
    echo "creating service bus namespace: ${SB_NAMESPACE}"
    az servicebus namespace create \
        --resource-group ${RESOURCE_GROUP} \
        --name ${SB_NAMESPACE} \

    # create topics in service bus
    echo "creating service bus topic: ${SB_SEND_TOPIC}"
    az servicebus topic create \
        --resource-group ${RESOURCE_GROUP} \
        --namespace-name ${SB_NAMESPACE} \
        --name ${SB_SEND_TOPIC}

    # create topics in service bus
    echo "creating service bus topic: ${SB_RECEIVE_TOPIC}"
    az servicebus topic create \
        --resource-group ${RESOURCE_GROUP} \
        --namespace-name ${SB_NAMESPACE} \
        --name ${SB_RECEIVE_TOPIC}

    # create topics in service bus
    echo "creating service bus topic: ${SB_PROCESS_TOPIC}"
    az servicebus topic create \
        --resource-group ${RESOURCE_GROUP} \
        --namespace-name ${SB_NAMESPACE} \
        --name ${SB_PROCESS_TOPIC}

    # create topics in service bus
    echo "creating service bus topic: ${SB_TRANSFORM_TOPIC}"
    az servicebus topic create \
        --resource-group ${RESOURCE_GROUP} \
        --namespace-name ${SB_NAMESPACE} \
        --name ${SB_TRANSFORM_TOPIC}    
}

# check command
if [ "${COMMAND}" == "clean" ]; then
    echo "cleaning up all ${PROJECT} related resources"
    # loop all groups
    RESOURCE_GROUPS=$(az group list | jq -r ".[].name");
    for RG in ${RESOURCE_GROUPS}
    do
        # check if project name is there
        if [[ ${RG} = ${PROJECT}-* ]]; then 
            echo "deleting resource group: ${RG}"
            az group delete --name ${RG} --yes --no-wait
        fi
    done
elif [ "${COMMAND}" == "deploy" ]; then
    # create resource group
    create_resource_group
    # # create service bus
    create_service_bus
fi
