#!/bin/zsh

################################################################
# O P T I O N S
################################################################

# -m    Use the mock endpoints
mock=false

# -v    be noisy. Only partially implemented as needed, to help diagnose problems.
verbose=false


# parse options
while getopts "mv" OPTION
do
     case $OPTION in
         m)
             mock=true
             ;;         
         v)
             verbose=true
             ;;
         ?)
             exit
             ;;
     esac
done


################################################################
# C O N S T A N T S
################################################################
CLIENT_ID=a436b2284fc0722ab6b4c968b47f896f
CLIENT_SECRET=0a3c42456c58d29d3adadd73e74a6dbe

USER_NAME=izzy+pvp@winkapp.com
PASSWORD=izzy

MOCK_API_URL=https://private-anon-9528e8852-wink.apiary-mock.com
WINK_API_URL=https://winkapi.quirky.com

MOCK_TOKEN=example_access_token_like_135fhn80w35hynainrsg0q824hyn



################################################################
# S E R V I C E   H E L P E R   F U N C T I O N S
################################################################


function get_api_url() {
    if [ $mock = true ]; then
        echo $MOCK_API_URL
    else
        echo $WINK_API_URL
    fi
}

function get_curl_verbosity() {
    if [ $verbose = true ]; then
        echo "--verbose"
    else
        echo "-s"
    fi
}

function extract_access_token() {
    local response=$1

    # grep the json-formatted line(s) with the token, then
    # use only the first one and
    # sed out the token
    echo $response \
        | grep "^[ ]*\"access_token" \
        | head -n 1 \
        | sed 's/.* \"\([^\"]*\)\",/\1/'
}

function make_user_token_request() {

    post_data="{
        \"client_id\": \"$CLIENT_ID\",
        \"client_secret\": \"$CLIENT_SECRET\",
        \"username\": \"$USER_NAME\",
        \"password\": \"$PASSWORD\",
        \"grant_type\": \"password\"
    }"

    # #remove whitespace
    # post_data=$(echo $post_data | tr -d ' \t\n')

    curl $(get_curl_verbosity) -X POST \
        -H "Content-Type: application/json" \
        -d "$post_data" \
        $(get_api_url)/oauth2/token | python -m json.tool
}

function get_user_token() {
    if [ $mock = true ]; then
        echo $MOCK_TOKEN
    else
        response=$(make_user_token_request 2>/dev/null)
        user_token=$(extract_access_token $response)
        echo $user_token
    fi
}

function api_get_request() {
    local endpoint=$1

    token=$(get_user_token)

    curl $(get_curl_verbosity) \
        -H "Authorization: Bearer $token" \
        $(get_api_url)${endpoint}
}

function api_put_post_request() {
    local endpoint=$1
    local post_data=$2
    local method=POST

    [ -n "$3" ] && method=$3

    token=$(get_user_token)

    [ $verbose = true ] && echo "posting: $post_data"

    curl $(get_curl_verbosity) -X $method \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $token" \
        -d "$post_data" \
        $(get_api_url)${endpoint}
}

################################################################
# S E R V I C E   F U N C T I O N S
################################################################

function get_outlet() {
    local outlet_id=$1

    api_get_request /outlets/$outlet_id
}

function set_outlet() {
    local outlet_id=$1
    local is_powered=$2

    post_data="{\"powered\":$is_powered}"

    api_put_post_request /outlets/$outlet_id $post_data PUT
}

function set_outlet_name() {
    local device_id=$1
    local device_name=$2

    set_device_name outlets $device_id $device_name
}

function set_powerstrip_name() {
    local device_id=$1
    local device_name=$2

    set_device_name powerstrips $device_id $device_name
}

function set_device_name() {
    local device_type=$1
    local device_id=$2
    local device_name=$3

    post_data="{\"name\":\"$device_name\"}"

    api_put_post_request /$device_type/$device_id $post_data PUT
}

################################################################
# S C R A T C H   S P A C E 
################################################################

# api_get_request /users/me/linked_services
# api_get_request /users/me/wink_devices | python -m json.tool
# api_get_request /powerstrips/1

# api_put_post_request /outlets/u59h-654fee_ih17afg '{"powered":true}' PUT
# get_outlet 15400
# set_outlet 15400 false


# get_outlet agh1ity-876f00
# make_user_token_request

# get_user_token

# get_outlet agh1ity-876f00

# api_get_request /users/me/wink_devices\?page=2 

# set_outlet_name 15400 "Living Room TV"
set_powerstrip_name 7699 "LivingRoom"

