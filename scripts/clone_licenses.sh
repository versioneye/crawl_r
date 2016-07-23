#!/bin/sh

#Clones Opensource licenses repo, which includes plain license text and licenses.json

REPO_URL="https://github.com/OpenSourceOrg/licenses.git"
REPO_BRANCH="master"
DATA_PATH=data/licenses
JSON_URL="http://api.opensource.org.s3.amazonaws.com/licenses/licenses.json"
JSON_SAVE_PATH=data/licenses.json

echo "init data folder"
mkdir data || echo "Data folder already exists."

echo "Downloading licenses.json"
curl -o $JSON_SAVE_PATH $JSON_URL

echo "Cloning Licenses text"
git clone --depth 1 --branch $REPO_BRANCH $REPO_URL $DATA_PATH
