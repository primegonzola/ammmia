#!/bin/bash

COMMAND="${1}"
PROJECT="ammmia"
LOCATION="westeurope"
UNIQUE_FIX=${RANDOM}
UNIQUE_FIX=$(date +%s)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
pushd ../.. && ROOT_DIR=$(pwd -P) && popd
OUTPUT_DIR=${ROOT_DIR}/output
SDK_DIR=${ROOT_DIR}/src/apps/sdk

# override here
if [ "${COMMAND}" == "update" ]; then
    UNIQUE_FIX="${2}"
fi

SUBSCRIPTION_ID=$(az account show | jq -r .id)
RESOURCE_GROUP=${PROJECT}-${UNIQUE_FIX}
SB_NAMESPACE=${PROJECT}-sbns-${UNIQUE_FIX}
SB_SEND_TOPIC="send-topic"-${UNIQUE_FIX}
SB_DISPATCH_TOPIC="dispach-topic"-${UNIQUE_FIX}
SB_RECEIVE_TOPIC="receive-topic"-${UNIQUE_FIX}
SB_PROCESS_TOPIC="process-topic"-${UNIQUE_FIX}
SB_TRANSFORM_TOPIC="transform-topic"-${UNIQUE_FIX}
SB_CONNECTION_ID=""
SB_CONNECTION_STRING=""
SB_CONNECTION_NAME=${PROJECT}-sbc-${UNIQUE_FIX}
SB_CONNECTION_DEPLOYMENT=${PROJECT}-sbc-deployment-${UNIQUE_FIX}
SB_SEND_SUBSCRIPTION="send-subscription"-${UNIQUE_FIX}
SB_DISPATCH_SUBSCRIPTION="dispatch-subscription"-${UNIQUE_FIX}
SB_RECEIVE_SUBSCRIPTION="receive-subscription"-${UNIQUE_FIX}
SB_PROCESS_SUBSCRIPTION="process-subscription"-${UNIQUE_FIX}
SB_TRANSFORM_SUBSCRIPTION="transform-subscription"-${UNIQUE_FIX}
CONTAINER_REGISTRY=${PROJECT}acr${UNIQUE_FIX}
CONTAINER_REGISTRY_ID="<unkown-registry-id>"
FUNCTIONS_IMAGE=${PROJECT}-functions:v1.0
FUNCTIONS_REMOTE_IMAGE="<unknown-image>"
FUNCTIONS_APP=${PROJECT}-fn-app-${UNIQUE_FIX}
FUNCTIONS_APP_PLAN=${PROJECT}-fn-asp-${UNIQUE_FIX}
FUNCTIONS_STORAGE_ACCOUNT=${PROJECT}sa${UNIQUE_FIX}
LOGIC_TRANSFORM=${PROJECT}-lg-app-${UNIQUE_FIX}
PROCESS_API_IMAGE=${PROJECT}-process-api:v1.0
PROCESS_API_REMOTE_IMAGE="<unknown-image>"
PROCESS_API_APP=${PROJECT}-api-app-${UNIQUE_FIX}
PROCESS_API_APP_PLAN=${PROJECT}-api-asp-${UNIQUE_FIX}

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
    echo "creating service bus topic: ${SB_DISPATCH_TOPIC}"
    az servicebus topic create \
        --resource-group ${RESOURCE_GROUP} \
        --namespace-name ${SB_NAMESPACE} \
        --name ${SB_DISPATCH_TOPIC}

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

    # echo "waiting to stabilize"
    # sleep 60    
    # create topic subscription
    echo "creating topic subscription: ${SB_SEND_TOPIC}"
    az servicebus topic subscription create \
        --resource-group ${RESOURCE_GROUP} \
        --namespace-name ${SB_NAMESPACE} \
        --topic-name ${SB_SEND_TOPIC} \
        --max-delivery-count 10 \
        --default-message-time-to-live PT10M \
        --name ${SB_SEND_SUBSCRIPTION}

    echo "creating topic subscription: ${SB_DISPATCH_TOPIC}"
    az servicebus topic subscription create \
        --resource-group ${RESOURCE_GROUP} \
        --namespace-name ${SB_NAMESPACE} \
        --topic-name ${SB_DISPATCH_TOPIC} \
        --max-delivery-count 10 \
        --default-message-time-to-live PT10M \
        --name ${SB_DISPATCH_SUBSCRIPTION}

    echo "creating topic subscription: ${SB_RECEIVE_TOPIC}"
    az servicebus topic subscription create \
        --resource-group ${RESOURCE_GROUP} \
        --namespace-name ${SB_NAMESPACE} \
        --topic-name ${SB_RECEIVE_TOPIC} \
        --max-delivery-count 10 \
        --default-message-time-to-live PT10M \
        --name ${SB_RECEIVE_SUBSCRIPTION}

    echo "creating topic subscription: ${SB_PROCESS_TOPIC}"
    az servicebus topic subscription create \
        --resource-group ${RESOURCE_GROUP} \
        --namespace-name ${SB_NAMESPACE} \
        --topic-name ${SB_PROCESS_TOPIC} \
        --max-delivery-count 10 \
        --default-message-time-to-live PT10M \
        --name ${SB_PROCESS_SUBSCRIPTION}

   echo "creating topic subscription: ${SB_TRANSFORM_TOPIC}"
    az servicebus topic subscription create \
        --resource-group ${RESOURCE_GROUP} \
        --namespace-name ${SB_NAMESPACE} \
        --topic-name ${SB_TRANSFORM_TOPIC} \
        --max-delivery-count 10 \
        --default-message-time-to-live PT10M \
        --name ${SB_TRANSFORM_SUBSCRIPTION}

    # replace
    sed \
        -e "s|<SB_CONNECTION_NAME>|${SB_CONNECTION_NAME}|" \
        -e "s|<SB_CONNECTION_STRING>|${SB_CONNECTION_STRING}|" \
        parameters.template.json > parameters.json

    # deploy connection
    echo "creating api connection for service bus: ${SB_CONNECTION_NAME}"
    az deployment group create \
        -g ${RESOURCE_GROUP} \
        -f ./connection.json \
        -n ${SB_CONNECTION_DEPLOYMENT} \
        --parameters @parameters.json

    # extract location
    SB_CONNECTION_ID=$(az resource show \
        --resource-group ${RESOURCE_GROUP} \
        --resource-type "Microsoft.Web/connections" \
        --name ${SB_CONNECTION_NAME} | jq -r .id)
}

function deploy_container_registry() {
    # create container registry
    echo "creating container registry: ${CONTAINER_REGISTRY}"
    az acr create \
        -n ${CONTAINER_REGISTRY} \
        -g ${RESOURCE_GROUP} \
        --admin-enabled true \
        --sku Basic
}

function set_container_context() {
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
    FUNCTIONS_REMOTE_IMAGE=${ACR_LOGIN_SERVER}/${FUNCTIONS_IMAGE};
    PROCESS_API_REMOTE_IMAGE=${ACR_LOGIN_SERVER}/${PROCESS_API_IMAGE};
    # extract 
    CONTAINER_REGISTRY_ID=$(az acr show --name ${CONTAINER_REGISTRY} | jq -r ".id")
}

function deploy_logic_handlers() {
    pushd ../apps/logic-apps

    # replace where needed
    pushd ./transform-handler

    # Transform logic app
    echo "creating logic app: ${LOGIC_TRANSFORM}"
    az logic workflow create \
        -g ${RESOURCE_GROUP} \
        -l ${LOCATION} \
        -n ${LOGIC_TRANSFORM} \
        --definition "./definition.json"
    popd
    
    # all done
    popd
}


function build_logic_handlers() {
    pushd ../apps/logic-apps

    # replace where needed
    pushd ./transform-handler
    # replace
    sed \
        -e "s|<SB_DISPATCH_TOPIC>|${SB_DISPATCH_TOPIC}|" \
        -e "s|<SB_TRANSFORM_TOPIC>|${SB_TRANSFORM_TOPIC}|" \
        -e "s|<SB_DISPATCH_SUBSCRIPTION>|${SB_DISPATCH_SUBSCRIPTION}|" \
        -e "s|<SB_TRANSFORM_SUBSCRIPTION>|${SB_TRANSFORM_SUBSCRIPTION}|" \
        -e "s|<CONNECTION_ID>|${SB_CONNECTION_ID}|" \
        -e "s|<SUBSCRIPTION_ID>|${SUBSCRIPTION_ID}|" \
        -e "s|<LOCATION>|${LOCATION}|" \
        definition.template.json > definition.json
    popd
    # all done
    popd
}

function publish_logic_handlers() {
    echo "publishing logic handlers"
}

function build_function_handlers() {
    pushd ../apps/functions

    # install sdk
    mkdir -vp common
    cp ${SDK_DIR}/sdk.ts ./common

    # replace where needed
    pushd ./send-handler
    sed \
        -e "s|<SB_SEND_TOPIC>|${SB_SEND_TOPIC}|" \
        -e "s|<SB_SEND_SUBSCRIPTION>|${SB_SEND_SUBSCRIPTION}|" \
        function.template.json > function.json
    popd
    pushd ./dispatch-handler
    sed \
        -e "s|<SB_DISPATCH_TOPIC>|${SB_DISPATCH_TOPIC}|" \
        -e "s|<SB_DISPATCH_SUBSCRIPTION>|${SB_DISPATCH_SUBSCRIPTION}|" \
        function.template.json > function.json
    popd
    # build container hosting our functions
    docker build -t ${FUNCTIONS_IMAGE} .
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
    echo "creating storage account: ${FUNCTIONS_STORAGE_ACCOUNT}"
    az storage account create \
        --name ${FUNCTIONS_STORAGE_ACCOUNT} \
        --location ${LOCATION} \
        --resource-group ${RESOURCE_GROUP} \
        --sku Standard_LRS

    echo "retrieving storage account connection string: ${FUNCTIONS_STORAGE_ACCOUNT}"
    FUNCTIONS_STORAGE_ACCOUNT_CONNECTION=$(az storage account show-connection-string \
        --resource-group ${RESOURCE_GROUP} \
        --name ${FUNCTIONS_STORAGE_ACCOUNT} \
        --query connectionString \
        --output tsv)

    # create plan
    echo "creating app plan: ${FUNCTIONS_APP_PLAN}"
    az functionapp plan create \
        --resource-group ${RESOURCE_GROUP} \
        --name ${FUNCTIONS_APP_PLAN} \
        --location ${LOCATION} \
        --number-of-workers 1 \
        --sku EP1 \
        --is-linux
    
    # create function app running a system owned identity 
    echo "creating app: ${FUNCTIONS_APP}"
    az functionapp create \
        --name ${FUNCTIONS_APP} \
        --assign-identity [system] \
        --storage-account ${FUNCTIONS_STORAGE_ACCOUNT} \
        --resource-group ${RESOURCE_GROUP} \
        --plan ${FUNCTIONS_APP_PLAN} \
        --os-type Linux \
        --runtime node \
        --functions-version 3 \
        --runtime-version 12 \
        --deployment-container-image-name ${FUNCTIONS_REMOTE_IMAGE} \
        --docker-registry-server-user ${ACR_USER} \
        --docker-registry-server-password ${ACR_PASSWORD}
        
    # setting configuration
    echo "applying settings to app: ${FUNCTIONS_APP_PLAN}"
    # storage connection string
    az functionapp config appsettings set \
        --name ${FUNCTIONS_APP} \
        --resource-group ${RESOURCE_GROUP} \
        --settings \
        AzureWebJobsStorage=${FUNCTIONS_STORAGE_ACCOUNT_CONNECTION} \
        SB_CONNECTION_STRING=${SB_CONNECTION_STRING} \
        SB_SEND_TOPIC=${SB_SEND_TOPIC} \
        SB_DISPATCH_TOPIC=${SB_DISPATCH_TOPIC} \
        SB_RECEIVE_TOPIC=${SB_RECEIVE_TOPIC} \
        SB_PROCESS_TOPIC=${SB_PROCESS_TOPIC} \
        SB_TRANSFORM_TOPIC=${SB_TRANSFORM_TOPIC} \
        SB_SEND_SUBSCRIPTION=${SB_SEND_SUBSCRIPTION} \
        SB_DISPATCH_SUBSCRIPTION=${SB_DISPATCH_SUBSCRIPTION} \
        SB_RECEIVE_SUBSCRIPTION=${SB_RECEIVE_SUBSCRIPTION} \
        SB_PROCESS_SUBSCRIPTION=${SB_PROCESS_SUBSCRIPTION} \
        SB_TRANSFORM_SUBSCRIPTION=${SB_TRANSFORM_SUBSCRIPTION}

    # getting additional info from newly created function  app
    echo "enabling function diagnostics: ${FUNCTIONS_APP}"
    az webapp log config \
        --resource-group ${RESOURCE_GROUP} \
        --name ${FUNCTIONS_APP} \
        --docker-container-logging filesystem \
        --application-logging filesystem

    # getting additional info from newly created function  app
    echo "getting additionals settings from app: ${FUNCTIONS_APP_PLAN}"
    FUNCTIONS_PRINCIPAL_ID=$(az functionapp show \
        --resource-group ${RESOURCE_GROUP} \
        --name ${FUNCTIONS_APP} \
        --output json | jq -r ".identity.principalId")

    echo "setting security for app: ${FUNCTIONS_APP_PLAN}"
    az role assignment create \
        --role AcrPull \
        --assignee-principal-type ServicePrincipal \
        --assignee-object-id ${FUNCTIONS_PRINCIPAL_ID} \
        --scope ${CONTAINER_REGISTRY_ID}  
}

function publish_function_handlers() {
    
    # tag
    echo "tagging container image ${FUNCTIONS_IMAGE} with: ${FUNCTIONS_REMOTE_IMAGE}"
    docker tag ${FUNCTIONS_IMAGE} ${FUNCTIONS_REMOTE_IMAGE}

    # push
    echo "pushing container image ${FUNCTIONS_REMOTE_IMAGE} to ${CONTAINER_REGISTRY}"
    docker push ${FUNCTIONS_REMOTE_IMAGE}
}

function save_configuration() {
    echo "saving configuration for in ${RESOURCE_GROUP}"
   # replace where needed
    pushd ../config
    sed \
        -e "s|<SB_SEND_TOPIC>|${SB_SEND_TOPIC}|" \
        -e "s|<SB_RECEIVE_TOPIC>|${SB_RECEIVE_TOPIC}|" \
        -e "s|<SB_DISPATCH_TOPIC>|${SB_DISPATCH_TOPIC}|" \
        -e "s|<SB_PROCESS_TOPIC>|${SB_PROCESS_TOPIC}|" \
        -e "s|<SB_TRANSFORM_TOPIC>|${SB_TRANSFORM_TOPIC}|" \
        -e "s|<SB_CONNECTION_STRING>|${SB_CONNECTION_STRING}|" \
        -e "s|<SB_SEND_SUBSCRIPTION>|${SB_SEND_SUBSCRIPTION}|" \
        -e "s|<SB_RECEIVE_SUBSCRIPTION>|${SB_RECEIVE_SUBSCRIPTION}|" \
        -e "s|<SB_DISPATCH_SUBSCRIPTION>|${SB_DISPATCH_SUBSCRIPTION}|" \
        -e "s|<SB_PROCESS_SUBSCRIPTION>|${SB_PROCESS_SUBSCRIPTION}|" \
        -e "s|<SB_TRANSFORM_SUBSCRIPTION>|${SB_TRANSFORM_SUBSCRIPTION}|" \
        configuration.template.js > configuration.js
    popd    
}

function build_api_handlers() {
    pushd ../apps/apis
    # replace where needed
    pushd ./api-handler

    # install sdk
    cp ${SDK_DIR}/sdk.ts .

    # sed \
    #     -e "s|<SB_SEND_TOPIC>|${SB_SEND_TOPIC}|" \
    #     -e "s|<SB_SEND_SUBSCRIPTION>|${SB_SEND_SUBSCRIPTION}|" \
    #     function.template.json > function.json

        # build container hosting our functions
        # docker build -t ${PROCESS_API_IMAGE} .
    popd
    popd
}

function deploy_api_handlers() {
    # get acr credentials
    echo "retrieving container register credentials: ${CONTAINER_REGISTRY}"
    ACR_USER=$(az acr credential show \
        --name ${CONTAINER_REGISTRY} \
        --output json | jq -r ".username")
    ACR_PASSWORD=$(az acr credential show \
        --name ${CONTAINER_REGISTRY} \
        --output json | jq -r ".passwords[0].value")
    
    # create plan
    echo "creating api app plan: ${PROCESS_API_APP_PLAN}"
    az appservice plan create \
        --resource-group ${RESOURCE_GROUP} \
        --name ${PROCESS_API_APP_PLAN} \
        --location ${LOCATION} \
        --number-of-workers 1 \
        --sku P2V3 \
        --is-linux
    
    # create function app running a system owned identity 
    echo "creating api app: ${PROCESS_API_APP}"
    # az webapp create \
    #     --name ${PROCESS_API_APP} \
    #     --assign-identity [system] \
    #     --resource-group ${RESOURCE_GROUP} \
    #     --plan ${PROCESS_API_APP_PLAN} \
    #     --deployment-container-image-name ${PROCESS_API_REMOTE_IMAGE} \
    #     --docker-registry-server-user ${ACR_USER} \
    #     --docker-registry-server-password ${ACR_PASSWORD}

    az webapp create \
        --name ${PROCESS_API_APP} \
        --assign-identity [system] \
        --resource-group ${RESOURCE_GROUP} \
        --plan ${PROCESS_API_APP_PLAN} \
        --runtime "node|12-lts" \
        --deployment-local-git

    # settings
    echo "setting app diagnostics: ${PROCESS_API_APP}"
    az webapp config appsettings set \
        --name ${PROCESS_API_APP} \
        --resource-group ${RESOURCE_GROUP} \
        --settings \
        SB_CONNECTION_STRING=${SB_CONNECTION_STRING} \
        SB_SEND_TOPIC=${SB_SEND_TOPIC} \
        SB_DISPATCH_TOPIC=${SB_DISPATCH_TOPIC} \
        SB_RECEIVE_TOPIC=${SB_RECEIVE_TOPIC} \
        SB_PROCESS_TOPIC=${SB_PROCESS_TOPIC} \
        SB_TRANSFORM_TOPIC=${SB_TRANSFORM_TOPIC} \
        SB_SEND_SUBSCRIPTION=${SB_SEND_SUBSCRIPTION} \
        SB_DISPATCH_SUBSCRIPTION=${SB_DISPATCH_SUBSCRIPTION} \
        SB_RECEIVE_SUBSCRIPTION=${SB_RECEIVE_SUBSCRIPTION} \
        SB_PROCESS_SUBSCRIPTION=${SB_PROCESS_SUBSCRIPTION} \
        SB_TRANSFORM_SUBSCRIPTION=${SB_TRANSFORM_SUBSCRIPTION}
    # getting additional info from newly created function  app
    echo "enabling app diagnostics: ${PROCESS_API_APP}"
    az webapp log config \
        --resource-group ${RESOURCE_GROUP} \
        --name ${PROCESS_API_APP} \
        --docker-container-logging filesystem \
        --application-logging filesystem

    # getting additional info from newly created function  app
    echo "getting additionals settings from app: ${PROCESS_API_APP_PLAN}"
    PROCESS_API_PRINCIPAL_ID=$(az webapp show \
        --resource-group ${RESOURCE_GROUP} \
        --name ${PROCESS_API_APP} \
        --output json | jq -r ".identity.principalId")

    echo "setting security for app: ${PROCESS_API_APP_PLAN}"
    az role assignment create \
        --role AcrPull \
        --assignee-principal-type ServicePrincipal \
        --assignee-object-id ${PROCESS_API_PRINCIPAL_ID} \
        --scope ${CONTAINER_REGISTRY_ID}  
}

function publish_api_handlers() {   
    # publish 
    ./publish.sh \
        ${RESOURCE_GROUP} \
        ${PROCESS_API_APP} \
        ${ROOT_DIR}/src/apps/apis/api-handler \
        ${OUTPUT_DIR}
}

function do_api_handlers(){
    # build api handlers
    build_api_handlers
    # deploy api handlers
    deploy_api_handlers
    # publish api handlers
    publish_api_handlers
}

function do_function_handlers(){
    # build function handlers
    build_function_handlers
    # deploy function handlers
    deploy_function_handlers
    # publish function handlers
    publish_function_handlers
}

function do_logic_handlers(){
    # build logic handlers
    build_logic_handlers
    # deploy logic handlers
    deploy_logic_handlers
    # publish logic handlers
    publish_logic_handlers
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
    rm -rf functions
    func init functions --worker-runtime node --language typescript --docker
    cd functions
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
    # remove output dir
    rm -rf ${OUTPUT_DIR}
    # remove output dir
    rm -rf ./publish_*.sh

elif [ "${COMMAND}" == "deploy" ]; then
    # setup
    mkdir -vp ${OUTPUT_DIR}

    # install sdk
    cp ${SDK_DIR}/sdk.ts ../apps/client/src

    # create resource group
    deploy_resource_group
    # deploy container registry
    deploy_container_registry
    # set proper context
    set_container_context
    # deploy service bus
    deploy_service_bus
    # do api handlers
    do_api_handlers &
    # do function handlers
    do_function_handlers &
      # do logic handlers
    do_logic_handlers &
    # all completed lock down security
    save_configuration
    
elif [ "${COMMAND}" == "update" ]; then
    # set proper context
    set_container_context
    # build function handlers
    build_function_handlers
    # publish function handlers
    publish_function_handlers
fi
