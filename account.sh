#!/bin/bash
set -ex
HOST=192.168.19.38

LOG(){
    date=`date "+%Y-%m-%d %H:%M:%S"`
    func=$1
    msg=$2
    echo -e "\033[32m$date ${func}:${msg}\033[0m"
}

function _ssh_gerrit(){
    ssh -p 29418 -i ~/.ssh/id_rsa $HOST -l admin gerrit $*
}

function group_create(){
    set +e
    LOG group_create "Creating GROUP $GROUP ..."
    _ssh_gerrit create-group $GROUP
    set -e
}

function account_create(){
    #PASSWD
    LOG account_create "Creating USER $USERNAME ..."
    htpasswd -mb /etc/nginx/auth_basic_user_files/passwd $USERNAME $PASSWORD
    cat /etc/nginx/auth_basic_user_files/passwd | grep $USERNAME
    #LOGIN
    LOG account_create "Testing USER $USERNAME http login ..."
    curl -I -m 10 -o /dev/null -s -w %{http_code} --user $USERNAME:$PASSWORD  http://$HOST:8080/login/
    echo ""
}

function account_update(){
    LOG account_update "Updating USER $USERNAME info & activing ..."
    _ssh_gerrit set-account --add-email $EMAIL --full-name $FULLNAME $USERNAME --active
    LOG account_update "ADD USER $USERNAME to GROUP $GROUP members ..."
    _ssh_gerrit set-members --add $FULLNAME $GROUP
}


for line in `cat ./users.txt`
do
    INFO=(${line//&/ })
    GROUP=${INFO[0]}
    FULLNAME=${INFO[1]}
    EMAIL=${INFO[2]}

    EMAIL_LIST=(${EMAIL//@/ })
    USERNAME=${EMAIL_LIST[0]}
    PASSWORD=${FULLNAME^}!@#123
    LOG  "" "-------- INFO --------"
    echo "USERNAME: $USERNAME"
    echo "EMAIL   : $EMAIL"
    echo "FULLNAME: $FULLNAME"
    echo "PASSWORD: $PASSWORD"
    LOG  "" "----------------------"

    read -p "USER Information is OK?(y/n): " ok
    if [[ $ok == "y" ]] || [[ $ok == "Y" ]];then
        group_create
        account_create
        account_update
    else
        exit 0
    fi
    echo ""
done
