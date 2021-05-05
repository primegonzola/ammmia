#!/bin/bash
# get setings
RESOURCE_GROUP="${1}"
WEB_APP="${2}"
SOURCE_DIR="${3}"
OUTPUT_DIR=${4}

echo "./publish.sh ${RESOURCE_GROUP} ${WEB_APP} ${SOURCE_DIR} ${OUTPUT_DIR}" > ./publish_${WEB_APP}.sh
chmod +x ./publish_${WEB_APP}.sh

# extract git info
GIT_URI=$(az webapp deployment source config-local-git \
    -g ${RESOURCE_GROUP} \
    -n ${WEB_APP} | jq -r .url)
GIT_USER=$(az webapp deployment list-publishing-credentials \
    -g ${RESOURCE_GROUP} \
    -n ${WEB_APP} | jq -r .publishingUserName)
GIT_PASSWORD=$(az webapp deployment list-publishing-credentials \
    -g ${RESOURCE_GROUP} \
    -n ${WEB_APP} | jq -r .publishingPassword)

mkdir -vp ${OUTPUT_DIR}
pushd ${OUTPUT_DIR}

# clone repo
git clone https://${GIT_USER}:${GIT_PASSWORD}@${WEB_APP}.scm.azurewebsites.net/${WEB_APP}.git

# go into dir
cd ${WEB_APP}

# configure
git config user.name ${GIT_USER}
git config user.email ${GIT_USER}@${WEB_APP}

# set simple push model
git config push.default simple

# copy all
cp -R ${SOURCE_DIR}/* .

# override git ignore
cat <<-EOF > ./.gitignore
npm-debug.log
package-lock.json
node_modules
*/doc
*/test
**/*.sh
**/*.config.js
EOF
# install
npm install

# build site
npm run publish

# add changes to repo
git add .

# commit
git commit -m "New deployment"

# push it
git push https://${GIT_USER}:${GIT_PASSWORD}@${WEB_APP}.scm.azurewebsites.net/${WEB_APP}.git

# all done    
popd
