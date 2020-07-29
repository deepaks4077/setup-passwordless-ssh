#! /bin/bash

##
#
# CREDIT TO guioconnor for https://github.com/guioconnor/Passwordless-SSH/
#
##

# saner programming env: these switches turn some bugs into errors
set -o errexit -o pipefail -o noclobber -o nounset

# -allow a command to fail with !’s side effect on errexit
# -use return value from ${PIPESTATUS[0]}, because ! hosed $?
! getopt --test > /dev/null 
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo 'I’m sorry, `getopt --test` failed in this environment.'
    exit 1
fi

OPTIONS=d:
LONGOPTS=hostname:,username:,filename:,path:

# -regarding ! and PIPESTATUS see above
# -temporarily store output to be able to check for errors
# -activate quoting/enhanced mode (e.g. by writing out “--options”)
# -pass arguments only via   -- "$@"   to separate them correctly

! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")

# ! PARSED=$(getopt --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # e.g. return value is 1
    #  then getopt has complained about wrong arguments to stdout
    exit 2
fi
# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

hostname="myhost"
username="$USER"
filename="id_rsa"
path="$HOME/.ssh"

# d=n f=n v=n outFile=- appFile=-
while true; do
    case "$1" in
        --hostname)
            hostname="$2"
            shift 2
            ;;
        --username)
            username="$2"
            shift 2
            ;;
        --filename)
            filename="$2"
            shift 2
            ;;
        --path)
            path="$2"
            shift 2
            ;;
        -d)
            dummy_var="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Programming error"
            exit 3
            ;;
    esac
done

# Generate rsa files
if [ -f $path/$filename ]
then
    echo "RSA key exists on $path/$filename, using existing file"
else
    ssh-keygen -t rsa -f "$path/$filename"
    echo RSA key pair generated
fi

echo "We need to log into $hostname as $username to set up your public key (hopefully last time you'll use password from this computer)" 
cat "$path/$filename.pub" | ssh "$hostname" -l "$username" '[ -d .ssh ] || mkdir .ssh; cat >> .ssh/authorized_keys; chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys'
status=$?

if [ $status -eq 0 ]
then
    echo "Set up complete, try to ssh to $hostname now"
    exit 0
else
    echo "an error has occured"
    exit 255
fi
