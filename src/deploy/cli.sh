#!/bin/bash

COMMAND="${1}"
PROJECT="ammmia"
LOCATION="westeurope"
UNIQUE_FIX=${RANDOM}
UNIQUE_FIX=$(date +%s)
RESOURCE_GROUP=${PROJECT}-${UNIQUE_FIX}
SB_NAMESPACE=${PROJECT}-sbns-${UNIQUE_FIX}
SB_SEND_TOPIC="send-topic"-${UNIQUE_FIX}
SB_RECEIVE_TOPIC="receive-topic"-${UNIQUE_FIX}
SB_PROCESS_TOPIC="process-topic"-${UNIQUE_FIX}
SB_TRANSFORM_TOPIC="transform-topic"-${UNIQUE_FIX}
SB_CONNECTION_STRING=""
SB_SEND_TOPIC_SUBSCRIPTION="send-topic-subscription"-${UNIQUE_FIX}
SB_RECEIVE_TOPIC_SUBSCRIPTION="receive-topic-subscription"-${UNIQUE_FIX}
SB_PROCESS_TOPIC_SUBSCRIPTION="process-topic-subscription"-${UNIQUE_FIX}
SB_TRANSFORM_TOPIC_SUBSCRIPTION="transform-topic-subscription"-${UNIQUE_FIX}
CONTAINER_REGISTRY=${PROJECT}acr${UNIQUE_FIX}
CONTAINER_REGISTRY_ID="<unkown-registry-id>"
FUNCS_IMAGE=${PROJECT}-funcs:v1.0
FUNCS_REMOTE_IMAGE="<unknown-image>"
FUNCS_APP=${PROJECT}-fn-app-${UNIQUE_FIX}
FUNCS_APP_PLAN=${PROJECT}-fn-asp-${UNIQUE_FIX}
FUNCS_STORAGE_ACCOUNT=${PROJECT}sa${UNIQUE_FIX}

function deploy_resource_group() {
    # create resource group
    echo "creating resource group: ${RESOURCE_GROUP}"
    az group create --location ${LOCATION} --name ${RESOURCE_GROUP}
}

function deploy_service_bus() {
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
    # retrieve and save connection string
    echo "retrieving connection string for service bus: ${SB_NAMESPACE}"
    SB_CONNECTION_STRING=$(az servicebus namespace authorization-rule keys list \
        --namespace-name ${SB_NAMESPACE} \
        --resource-group ${RESOURCE_GROUP} \
        --name RootManageSharedAccessKey \
        --query primaryConnectionString | jq -r .)
    
    # create topic subscription
    echo "creating topic subscription: ${SB_SEND_TOPIC}"
    az servicebus topic subscription create \
        --resource-group ${RESOURCE_GROUP} \
        --namespace-name ${SB_NAMESPACE} \
        --topic-name ${SB_SEND_TOPIC} \
        --max-delivery-count 10 \
        --name ${SB_SEND_TOPIC_SUBSCRIPTION}

    # echo "creating topic subscription filter: ${SB_SEND_TOPIC}"
    # az servicebus topic subscription rule create \
    #     --resource-group ${RESOURCE_GROUP} \
    #     --namespace-name ${SB_NAMESPACE} \
    #     --topic-name ${SB_SEND_TOPIC} \
    #     --subscription-name ${SB_SEND_TOPIC_SUBSCRIPTION} \
    #     --name "all" \
    #     --filter-sql-expression 1=1
}

function deploy_container_registry() {
    # create container registry
    echo "creating container registry: ${CONTAINER_REGISTRY}"
    az acr create \
        -n ${CONTAINER_REGISTRY} \
        -g ${RESOURCE_GROUP} \
        --admin-enabled true \
        --sku Basic
    # login
    echo "logging in container registry: ${CONTAINER_REGISTRY}"
    az acr login --name ${CONTAINER_REGISTRY}
    # get login server
    echo "getting login info for container registry: ${CONTAINER_REGISTRY}"
    # extract 
    ACR_LOGIN_SERVER=$(az acr list \
        --resource-group ${RESOURCE_GROUP} \
        --query "[].{acrLoginServer:loginServer}" \
        --output json | jq -r ".[].acrLoginServer")
    # extract 
    FUNCS_REMOTE_IMAGE=${ACR_LOGIN_SERVER}/${FUNCS_IMAGE};
    # extract 
    CONTAINER_REGISTRY_ID=$(az acr show --name ${CONTAINER_REGISTRY} | jq -r ".id")
}

function build_function_handlers() {
    pushd ../apps/funcs
    # replace where needed
    pushd ./send-handler
    sed \
        -e "s|<SB_SEND_TOPIC>|${SB_SEND_TOPIC}|" \
        -e "s|<SB_SEND_TOPIC_SUBSCRIPTION>|${SB_SEND_TOPIC_SUBSCRIPTION}|" \
        function.template.json > function.json
    popd
    # build container hosting our functions
    docker build -t ${FUNCS_IMAGE} .
    popd
}

function deploy_function_handlers() {
    # get acr credentials
    echo "retrieving container register credentials: ${CONTAINER_REGISTRY}"
    ACR_USER=$(az acr credential show \
        --name ${CONTAINER_REGISTRY} \
        --output json | jq -r ".username")
    ACR_PASSWORD=$(az acr credential show \
        --name ${CONTAINER_REGISTRY} \
        --output json | jq -r ".passwords[0].value")
    
    # create the storage account
    echo "creating storage account: ${FUNCS_STORAGE_ACCOUNT}"
    az storage account create \
        --name ${FUNCS_STORAGE_ACCOUNT} \
        --location ${LOCATION} \
        --resource-group ${RESOURCE_GROUP} \
        --sku Standard_LRS

    echo "retrieving storage account connection string: ${FUNCS_STORAGE_ACCOUNT}"
    FUNCS_STORAGE_ACCOUNT_CONNECTION=$(az storage account show-connection-string \
        --resource-group ${RESOURCE_GROUP} \
        --name ${FUNCS_STORAGE_ACCOUNT} \
        --query connectionString \
        --output tsv)

    # create plan
    echo "creating functions app plan: ${FUNCS_APP_PLAN}"
    az functionapp plan create \
        --resource-group ${RESOURCE_GROUP} \
        --name ${FUNCS_APP_PLAN} \
        --location ${LOCATION} \
        --number-of-workers 1 \
        --sku EP1 \
        --is-linux
    
    # create function app running a system owned identity 
    echo "creating functions app: ${FUNCS_APP}"
    az functionapp create \
        --name ${FUNCS_APP} \
        --assign-identity [system] \
        --storage-account ${FUNCS_STORAGE_ACCOUNT} \
        --resource-group ${RESOURCE_GROUP} \
        --plan ${FUNCS_APP_PLAN} \
        --os-type Linux \
        --runtime node \
        --functions-version 3 \
        --runtime-version 12 \
        --deployment-container-image-name ${FUNCS_REMOTE_IMAGE} \
        --docker-registry-server-user ${ACR_USER} \
        --docker-registry-server-password ${ACR_PASSWORD}
        
    # setting configuration
    echo "applying settings to functions app: ${FUNCS_APP_PLAN}"
    # storage connection string
    az functionapp config appsettings set \
        --name ${FUNCS_APP} \
        --resource-group ${RESOURCE_GROUP} \
        --settings AzureWebJobsStorage=${FUNCS_STORAGE_ACCOUNT_CONNECTION}
    # service bus connection string
    az functionapp config appsettings set \
        --name ${FUNCS_APP} \
        --resource-group ${RESOURCE_GROUP} \
        --settings SB_CONNECTION_STRING=${SB_CONNECTION_STRING}
        
    # getting additional info from newly created function  app
    echo "getting additionals settings from functions app: ${FUNCS_APP_PLAN}"
    FUNCS_PRINCIPAL_ID=$(az functionapp show \
        --resource-group ${RESOURCE_GROUP} \
        --name ${FUNCS_APP} \
        --output json | jq -r ".identity.principalId")

    echo "setting security for functions app: ${FUNCS_APP_PLAN}"
    az role assignment create \
        --role AcrPull \
        --assignee-principal-type ServicePrincipal \
        --assignee-object-id ${FUNCS_PRINCIPAL_ID} \
        --scope ${CONTAINER_REGISTRY_ID}  
}

function publish_function_handlers() {
    
    # tag
    echo "tagging container image ${FUNCS_IMAGE} with: ${FUNCS_REMOTE_IMAGE}"
    docker tag ${FUNCS_IMAGE} ${FUNCS_REMOTE_IMAGE}

    # push
    echo "pushing container image ${FUNCS_REMOTE_IMAGE} to ${CONTAINER_REGISTRY}"
    docker push ${FUNCS_REMOTE_IMAGE} -q
}

function save_configuration() {
    echo "saving configuration for in ${RESOURCE_GROUP}"
   # replace where needed
    pushd ../config
    sed \
        -e "s|<SB_SEND_TOPIC>|${SB_SEND_TOPIC}|" \
        -e "s|<SB_RECEIVE_TOPIC>|${SB_RECEIVE_TOPIC}|" \
        -e "s|<SB_PROCESS_TOPIC>|${SB_PROCESS_TOPIC}|" \
        -e "s|<SB_TRANSFORM_TOPIC>|${SB_TRANSFORM_TOPIC}|" \
        -e "s|<SB_CONNECTION_STRING>|${SB_CONNECTION_STRING}|" \
        -e "s|<SB_SEND_TOPIC_SUBSCRIPTION>|${SB_SEND_TOPIC_SUBSCRIPTION}|" \
        -e "s|<SB_RECEIVE_TOPIC_SUBSCRIPTION>|${SB_RECEIVE_TOPIC_SUBSCRIPTION}|" \
        -e "s|<SB_PROCESS_TOPIC_SUBSCRIPTION>|${SB_PROCESS_TOPIC_SUBSCRIPTION}|" \
        -e "s|<SB_TRANSFORM_TOPIC_SUBSCRIPTION>|${SB_TRANSFORM_TOPIC_SUBSCRIPTION}|" \
        configuration.template.js > configuration.js
    popd    
}

function test_deployment() {
    echo "testing deployment in ${RESOURCE_GROUP}"
    # command to execute
    FUNCS_APP_CODE=$(az functionapp keys list --resource-group ${RESOURCE_GROUP} --name ${FUNCS_APP} | jq -r ".functionKeys.default")
    TEST_URI="https://${FUNCS_APP}.azurewebsites.net/api/test-handler?code=${FUNCS_CODE}&name=test"
    curl ${TEST_URI}

    while [ $? -ne 0 ]; do
        echo "waiting for retry"
        sleep 10
        echo "testing at ${TEST_URI}"
        FUNCS_APP_CODE=$(az functionapp keys list --resource-group ${RESOURCE_GROUP} --name ${FUNCS_APP} | jq -r ".functionKeys.default")
        TEST_URI="https://${FUNCS_APP}.azurewebsites.net/api/test-handler?code=${FUNCS_CODE}&name=test"
        curl ${TEST_URI}
    done   
}

# check command
if [ "${COMMAND}" == "install" ]; then
    echo "setting up ${PROJECT} related resources"
    # check for darwin
    if [[ $(uname) == "Darwin" ]]; then
        echo "setting up Darwin platform"
        # install function core tools
        brew tap azure/functions
        brew install azure-functions-core-tools@3
        # if upgrading on a machine that has 2.x installed
        brew link --overwrite azure-functions-core-tools@3
    fi
elif [ "${COMMAND}" == "generate" ]; then
    # clean up
    pushd ../apps
    rm -rf funcs
    func init funcs --worker-runtime node --language typescript --docker
    cd funcs
    func new --name test-handler --template "HTTP trigger"
    func new --name send-handler --template "Azure Service Bus Topic trigger"
    popd
elif [ "${COMMAND}" == "clean" ]; then
    echo "cleaning up all ${PROJECT} related resources"
    # clean images
    DOCKER_IMAGES=$(docker images -a -q)
    for DI in ${DOCKER_IMAGES}
    do
        echo "deleting docker image: ${DI}"
        docker rmi ${DI} --force
    done
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
    deploy_resource_group
    # deploy container registry
    deploy_container_registry
    # deploy service bus
    deploy_service_bus
    # build function handlers
    build_function_handlers
    # deploy function handlers
    deploy_function_handlers
    # publish function handlers
    publish_function_handlers
  
    # all completed lock down security
    save_configuration
    # test deployment
    # test_deployment
fi
