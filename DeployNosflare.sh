#!/bin/bash
# Please update variables below before running the script
##################################################################################################
# You can create your API token from your Cloudflare account here: https://dash.cloudflare.com/profile/api-tokens
# Use template "Edit Cloudflare Workers" or create a custom one for workers
CLOUDFLARE_API_TOKEN=""
relayInfo_name=""
# Full domain of the relay. Ex: relay.domain.tld. You need to have the domain.tld zone available in your Cloudflare domain list.
relayURL=""
relayInfo_description=""
#pubkey hex format, you can use damus convertor to convert your npub to hex : https://damus.io/key/
relayInfo_pubkey=""
relayInfo_contact=""
relayIcon_URL=""
# Set to 1 if you need to hide your info during the wrangler whoami & CF API KEY display (maybe you want to record your session script?)
hide_whoami_infos=1
debug=0
##################################################################################################
# Script variables, please do not modify if you don't know what you are doing
pwd=$(pwd)
path_nosflare="$pwd/nosflare"
path_node_modules_bin="$path_nosflare/node_modules/.bin"
path_esbuild="$path_node_modules_bin/esbuild"
path_wrangler="$path_node_modules_bin/wrangler"
path_wrangler_toml="$path_nosflare/wrangler.toml"
path_worker_js="$path_nosflare/worker.js"
path_dist_worker_js="$path_nosflare/dist/worker.js"
nosflare_remote_gh_repo="https://github.com/PastaGringo/nosflare"
nosflare_gh_repo_owner=$(echo $nosflare_remote_gh_repo | cut -d"/" -f 4)
nosflare_remote_gh_repo_git="$nosflare_remote_gh_repo.git"
nosflare_kv_title="nosflare-kvdb"
relayDOMAIN=$(echo $relayURL | cut -d"." -f 2,3)
##################################################################################################
function echolor()
{
    YELLOW="\e[33m"
    ENDCOLOR="\e[0m"
    string=$(echo $1)
    echo -e "${YELLOW}${string}${ENDCOLOR}"
}
function HideWhoamiInfos
{
cat << EOF
 ⛅️ wrangler 3.39.0
-------------------
Getting User settings...
👋 You are logged in with an API Token, associated with the email Satoshi.Nakamoto@nostr.love!
┌─────────────────────────────────────┬──────────────────────────────────┐
│ Account Name                        │ Account ID                       │
├─────────────────────────────────────┼──────────────────────────────────┤
│ HIDDEN                              │ HIDDEN                           │
└─────────────────────────────────────┴──────────────────────────────────┘
🔓 To see token permissions visit https://dash.cloudflare.com/profile/api-tokens
EOF
}
##################################################################################################
clear
today=$(date +%Y-%m-%d)
echo 
echo "-------------------------- NosflareDeploy v1.0 ---------------------------"
echo "    _   __           ______                ____             __           ";
echo "   / | / /___  _____/ __/ /___  ____ ___  / __ \___  ____  / /___  __  __";
echo "  /  |/ / __ \/ ___/ /_/ / __ \/ __// _ \/ / / / _ \/ __ \/ / __ \/ / / /";
echo " / /|  / /_/ (__  ) __/ / /_/ / /  /  __/ /_/ /  __/ /_/ / / /_/ / /_/ / ";
echo "/_/ |_/\____/____/_/ /_/\__,_/_/   \___/_____/\___/ .___/_/\____/\__, /  ";
echo "                                                 /_/            /____/   ";
echo "-------------------------- NosflareDeploy v1.0 ---------------------------"
echo "                                                                $today    "
echo
echolor "Checking if basic depedencies are available ..."
echo
echolor "Checking git ..."
if command -v git &> /dev/null; then
    echo "git is installed ✅"
    echo
else
    echo "git is not installed ❌ Please install git and run the script again."
    echo
    exit 1
fi
echolor "Checking npm ..."
if command -v npm &> /dev/null; then
    echo "npm is installed ✅"
else
    echo "npm is not installed ❌ Please install npm and run the script again."
    echo
    exit 1
fi
echo
echolor "Basic depedencies satisfied. Starting the script ..."
echo
echo "Current dir: $pwd"
if [[ $hide_whoami_infos -eq 1 ]]; then
    echo "Hide my infos: enabled"
else
    echo "Hide my infos: disabled"
fi
echo
echolor "Checking if variables have been set INTO the script (how-to: nano ./DeployNosflare.sh) ..."
var_missing=0
echo
###
if [ -z "${CLOUDFLARE_API_TOKEN}" ]; then
    echo '❌ VAR $CLOUDFLARE_API_TOKEN    :'
    var_missing=1
else
    if [[ $hide_whoami_infos -eq 1 ]]; then
        echo '✅ VAR $CLOUDFLARE_API_TOKEN    : HIDDEN' 
    else
        echo '✅ VAR $CLOUDFLARE_API_TOKEN    :' $CLOUDFLARE_API_TOKEN
    fi
fi
###
if [ -z "${relayURL}" ]; then
    echo '❌ VAR $relayURL                :'
    var_missing=1
else
    echo '✅ VAR $relayURL                :' $relayURL
fi
###
if [ -z "${relayInfo_name}" ]; then
    echo '❌ VAR $relayInfo_name          :'
    var_missing=1
else
    echo '✅ VAR $relayInfo_name          :' $relayInfo_name
fi
###
if [ -z "${relayInfo_description}" ]; then
    echo '❌ VAR $relayInfo_description   :'
    var_missing=1
else
    echo '✅ VAR $relayInfo_description   :' $relayInfo_description
fi
###
if [ -z "${relayInfo_pubkey}" ]; then
    echo '❌ VAR $relayInfo_pubkey        :'
    var_missing=1
else
    echo '✅ VAR $relayInfo_pubkey        :' $relayInfo_pubkey
fi
###
if [ -z "${relayInfo_contact}" ]; then
    echo '❌ VAR $relayInfo_contact       :'
    var_missing=1
else
    echo '✅ VAR $relayInfo_contact       :' $relayInfo_contact
fi
###
if [ -z "${relayIcon_URL}" ]; then
    echo '❌ VAR $relayInfo_pubkey        :'
    var_missing=1
else
    echo '✅ VAR $relayIcon_URL           :' $relayIcon_URL
fi
###
#exit
###
if [ $var_missing -eq 1 ];then
    echo
    echolor '[ERROR] At least one variable is missing. You need to set all the variables before starting the script. Exiting. Bye'
    echo
    exit
else
    echo
    echo "All variables has been set ✅"
fi
echo
echolor "Checking if Nosflare has already been built here ..."
if test -d $path_nosflare; then
    echo "=> $path_nosflare has been found ✅"
    echo
    echolor "Getting nosflare cloned version..."
    echo
    version_cloned=$(grep version $path_worker_js | cut -d '"' -f 2)
    version_cloned_last_commit=$(git -C $path_nosflare rev-parse HEAD)
    echo "Local cloned version found        : $version_cloned"
    echo "Local cloned latest commit found  : $nosflare_remote_gh_repo/commit/$version_cloned_last_commit"
    echo
    echolor "Getting nosflare latest version from github..."
    echo
    nosflare_latest_version=$(curl -s "https://raw.githubusercontent.com/$nosflare_gh_repo_owner/nosflare/main/worker.js" | grep version | cut -d '"' -f 2)
    echo "Remote latest version found       : $nosflare_latest_version"
    nosflare_remote_latest_commit=$(git ls-remote $nosflare_remote_gh_repo | grep HEAD | cut -f 1)
    echo "Remote latest commit              : $nosflare_remote_gh_repo/commit/$nosflare_remote_latest_commit"
    echo
    if [ "$version_cloned" = "$nosflare_latest_version" ]; then
        echo "You already have the latest version."
        echolor "Would you like to deploy Nosflare anyway?"
        echo
        echo "Press any key to continue or CTRL+C to quit this script."
        read
        echo "Sure?"
        read
    else
        echo "New release available!"
        echolor "Would you like to update nosflare and rebuild it with your info?"
        echo "You'll have a functional worker.js file with your infos but if you made some code changes that WILL DELETE THEM"
        echo
        echo "Press any key to continue or CTRL+C to quit this script."
        read
        echo "Sure?"
        read
        echolor "Updating local folder with latest github changes from $nosflare_remote_gh_repo (MAIN branche) ..."
        echolor "Getting latest changes and overwriting local files..."
        git -C $path_nosflare reset --hard HEAD
        git -C $path_nosflare pull
        echo "Done ✅"
    fi
else
    echo ">>> $path_nosflare not found ⚠️ (first time install?)"
    echo
    echolor "Would you like to clone nosflare from $nosflare_remote_gh_repo to $path_nosflare ?"
    echo
    echo "Press any key to continue or CTRL+C to exit."
    read
    echolor "Cloning Nosflare from $nosflare_remote_gh_repo to $path_nosflare ... "
    git clone --quiet $nosflare_remote_gh_repo_git
    echo ">>> Done ✅"
    echo
    echolor "Installing @noble/curves ..."
    npm install --silent --prefix $path_nosflare @noble/curves
    echo ">>> Installation done ✅"
    echo
    echolor "Installing wrangler ..."
    npm install --silent --prefix $path_nosflare wrangler
    echo ">>> Installation done ✅"
fi
echo
echolor "Verifying if depedencies are locally installed ..."
echo
echolor "Checking wrangler ..."
#if ! command -v $path_wrangler &> /dev/null
if command -v $path_wrangler &> /dev/null
then
   #echo ">>> wrangler could not be found in bash source."
   #echolor "Looking into ./node_modules/.bin/ ... "
   wrangler_version=$($path_wrangler --version)
   if [ -z "${wrangler_version}" ]; then
       echo "❌ An error occured during the get version of $path_wrangler. Exiting. Bye"
       echo
       exit 1
   else
       echo ">>> Found wrangler v$wrangler_version ✅ "
   fi
fi
echo
echolor "Updating $path_worker_js with given ENV variables..."
sed -i 's/name: "Nosflare"/name: "'"$relayInfo_name"'"/g' $path_worker_js
sed -i 's/description: "A serverless Nostr relay through Cloudflare Worker and KV store"/description: "'"$relayInfo_description"'"/g' $path_worker_js
sed -i 's/pubkey: "d49a9023a21dba1b3c8306ca369bf3243d8b44b8f0b6d1196607f7b0990fa8df"/pubkey: "'"$relayInfo_pubkey"'"/g' $path_worker_js
sed -i 's/contact: "lucas@censorship.rip"/contact: "'"$relayInfo_contact"'"/g' $path_worker_js
sed -i 's#const relayIcon = "https://workers.cloudflare.com/resources/logo/logo.svg"#const relayIcon = "'"$relayIcon_URL"'"#g' $path_worker_js
echo ">>> Done ✅"
echo
export CLOUDFLARE_API_TOKEN
echolor "Verifying who you are ..."
echo
if [[ $hide_whoami_infos -eq 1 ]]; then
    HideWhoamiInfos
else
    $path_wrangler whoami
fi
echo
echolor "Checking existing KV(s) from your Cloudflare account ..."
kvs_json=$($path_wrangler kv:namespace list)
kvs_count=$(echo $kvs_json | jq length)
if [[ $kvs_count -gt 0 ]]
    then
        echo ">>> Found $kvs_count KV(s)"
    else
        echo ">>> Found $kvs_count KV(s)"
        echo
        echolor "Creating Nosflare KV ... "
        echo
        $path_wrangler kv:namespace create kvdb
fi
echo
echolor "Looking for the KV-ID for KV with title $nosflare_kv_title ..."
kvs_json=$($path_wrangler kv:namespace list)
nosflare_cf_kv_id=$(echo $kvs_json | jq -r '.[] | select(.title | startswith("'"$nosflare_kv_title"'"))' | jq -r .id)
nosflare_cf_kv_title=$(echo $kvs_json | jq -r '.[] | select(.title | startswith("'"$nosflare_kv_title"'"))' | jq -r .title)
if [[ $debug -eq 1 ]]; then
    echo "[DEBUG] Listing KV namespace:"
    $path_wrangler kv:namespace list
    echo "[DEBUG] $nosflare_cf_kv_title -> $nosflare_cf_kv_id"
    echo "[DEBUG] End, Bye."
    exit 1
fi
if [ -z "${nosflare_cf_kv_id}" ]; then
    echo '❌ Cannot get the KV namespace ID'
    echo "Please, run the script one more time in case of Cloudflare timeout (good excuse, chief)."
    echo "If still not working, open a github issue!"
    echo
    exit 1
else
    echo ">>> ✅ Nosflare KVdb id : $nosflare_cf_kv_id"
fi
#exit
echo
echolor "Updating wrangler.toml file with given ENV variables... "
sed -i 's/"KV_ID"/"'"$nosflare_cf_kv_id"'"/g' $path_wrangler_toml
sed -i 's/"FULL_DOMAIN"/"'"$relayURL"'"/g' $path_wrangler_toml
sed -i 's/"DOMAIN"/"'"$relayDOMAIN"'"/g' $path_wrangler_toml
sed -i 's/"DATE"/"'"$today"'"/g' $path_wrangler_toml
echo ">>> Done ✅"
echo
echolor "Deploying your Nosflare Nostr relay to Cloudflare ..."
echo
$path_wrangler deploy $path_worker_js
echo
echo ">>> Done ✅"
echo
echolor "##################################### NOSFLARE DEPLOYMENT COMPLETE #####################################"
echo
echo "  Your Nosflare Nostr relay is available here   : https://$relayURL"
echo "  Your Nosflare Nostr websocket                 : wss://$relayURL"
echo "  Your can check your relay state here          : https://nostr.watch/relay/$relayURL"
echo
echolor "########################################################################################################"
echo
echo "                                              Happy Zaps ⚡"
echo
echo
echo
echo
echo
echo
echolor "############################################## DANGER ZONE #############################################"
echo
echolor "Press any key if you want to begin the process to delete your Cloudflare Worker, your Cloudflare KV and the local cloned Nosflare directory."
echo "Btw, you saw how quickly you can rebuild your Nosflare nostr relay, don't worry so much :)"
echo
echo "CTRL+C to quit."
read
echolor "Delete everything?"
read
echolor "Sure?"
read
echolor "REALLY Sure? Last chance to abort!"
read
echolor "Deleting the Cloudflare KV namespace ..."
echo
$path_wrangler kv:namespace delete --namespace-id $nosflare_cf_kv_id
echo ">>> Done ✅"
echo
echolor "Deleting the Cloudflare Worker ..."
echo
$path_wrangler delete --config $path_wrangler_toml --force
echo ">>> Done ✅"
echo
echolor "Checking if $path_nosflare still exists ..."
if test -d $path_nosflare; then
    echo ">>> Directory $path_nosflare exists."
    echolor "Removing it ..."
    rm -rf $path_nosflare
    echo "Removed ✅"
else
    echo "Weird, $path_nosflare is missing?!"
    echo "Nevermind, less to do."
fi
echo
echo ">>> Everything has been deleted ✅"
echo
echo "Bye!"
echo
