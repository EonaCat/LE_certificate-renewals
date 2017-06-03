#!/bin/sh

### BEGIN INIT INFO
# Provides: certificate renewal for domains
# Required-Start: $all
# Required-Stop: $all
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Certificaterenewal for domains
# Description: This script provides automatic domain certificate renewal
### END INIT INFO

# parse the arguments.
COUNTER=0
ARGS=("$@")
while [ $COUNTER -lt $# ]
do
    arg=${ARGS[$COUNTER]}
    let COUNTER=COUNTER+1
    nextArg=${ARGS[$COUNTER]}

    if [[ $skipNext -eq 1 ]]; then
        skipNext=0
        continue
    fi

    argKey=""
    argVal=""
    if [[ "$arg" =~ ^\- ]]; then
        # if the format is: -key=value
        if [[ "$argKey" =~ \= ]]; then
            argVal=$(echo "$argKey" | cut -d'=' -f2)
            argKey=$(echo "$argKey" | cut -d'=' -f1)
            skipNext=0

        # if the format is: -key value
        elif [[ ! "$nextArg" =~ ^\- ]]; then
            argKey="$arg"
            argVal="$nextArg"
            skipNext=1

        # if the format is: -key (a boolean flag)
        elif [[ "$nextArg" =~ ^\- ]] || [[ -z "$nextArg" ]]; then
            argKey="$arg"
            argVal=""
            skipNext=0
        fi
    # if the format has not flag, just a value.
    else
        argKey=""
        argVal="$arg"
        skipNext=0
    fi
done

> /var/log/letsencrypt/letsencrypt.log
webroot="/var/www"
domain="saey.me"
email=""

function showusage
{
        echo "You can give the following parameters to the certificate script:
        --email         : emailaddress that will be used to sent the confirmation mail
        --webroot       : webroot directory that will be used for the website root
        --domain        : domain that needs to be used for the certifcate generation"
}


case "$argKey" in
        --email)
            email="$argVal"
        ;;
        --webroot)
            webroot="$argVal"
        ;;
        --domain)
            domain="$argVal"
        ;;
        -h|--help|-help|--h)
            showusage
            exit
        ;;
    esac

certbot certonly --webroot --webroot-path=$webroot -d $domain
if [ $? -ne 0 ]; then
    errorlog="$(cat /var/log/letsencrypt/letsencrypt.log)"
    sleep 1; echo -e "The Lets Encrypt SSL Certificate for $domain has not been renewed! \n \n" $errorlog | mail -s "NightBits SSL Certification Renewals" info@saey.me $email
    exit 1
  else
    /etc/init.d/nginx restart
fi
exit 0
