#!/bin/bash
set -e

## Execute a command as user zammad
exec_as_zammad() {
  sudo -HEu zammad "$@"
}

[[ -n $DEBUG_ENTRYPOINT ]] && set -x

DB_HOST=${DB_HOST:-localhost}
DB_USER=${DB_USER:-dbuser}
DB_NAME=${DB_NAME:-zammad}
DB_PASSWORD=${DB_PASSWORD:-}
ZAMMAD_SERVER_NAME=${ZAMMAD_SERVER_NAME:-}

POSTFIX_MYHOSTNAME=${POSTFIX_MYHOSTNAME:-}
POSTFIX_RELAY_HOST=${POSTFIX_RELAY_HOST:-}
POSTFIX_RELAY_USER=${POSTFIX_RELAY_USER:-}
POSTFIX_RELAY_PASSWORD=${POSTFIX_RELAY_PASSWORD:-}

sudo -HEu zammad sed 's,{{DB_HOST}},'"${DB_HOST}"',g' -i config/database.yml
sudo -HEu zammad sed 's,{{DB_USER}},'"${DB_USER}"',g' -i config/database.yml
sudo -HEu zammad sed 's,{{DB_NAME}},'"${DB_NAME}"',g' -i config/database.yml
sudo -HEu zammad sed 's,{{DB_PASSWORD}},'"${DB_PASSWORD}"',g' -i config/database.yml
sed 's,{{ZAMMAD_SERVER_NAME}},'"${ZAMMAD_SERVER_NAME}"',g' -i /etc/nginx/sites-available/zammad.conf

if [ -n "${POSTFIX_RELAY_USER}" ] &&  [ -n "${POSTFIX_RELAY_PASSWORD}" ] ; then
    echo "${POSTFIX_RELAY_HOST}		${POSTFIX_RELAY_USER}:${POSTFIX_RELAY_PASSWORD}" > /etc/postfix/sasl/saslpass
    cd /etc/postfix/sasl/
    postmap saslpass
    postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl/saslpass"
fi

if [ -n "${POSTFIX_MYHOSTNAME}" ]; then
    postconf -e "myhostname = ${POSTFIX_MYHOSTNAME}"
fi

if [ -n "${POSTFIX_RELAY_HOST}" ]; then
    postconf -e "relayhost = ${POSTFIX_RELAY_HOST}"
fi

postconf -e "smtp_sasl_auth_enable = yes"
postconf -e "smtp_sasl_security_options = noanonymous"
postconf -e "smtp_use_tls = yes"



appStart () {
    
  # start supervisord
  echo "Starting supervisord..."
  exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
}


appInit () {
  echo "Initializing Zammad..."

   exec_as_zammad /bin/bash -c "cd /opt/zammad && source /opt/zammad/.rvm/scripts/rvm && /init.sh"
  
}


appHelp () {
  echo "Available options:"
  echo " app:start          - Starts the Zammad app and Nginx server (default)"
  echo " app:init           - Initializes Database and Elasticsearch config"
  echo " [command]          - Execute the specified linux command eg. bash."
}


case ${1} in
  app:start)
    appStart
    ;;
  app:help)
    appHelp
    ;;   
  *)
    if [[ -x $1 ]]; then
      $1
    else
      prog=$(which $1)
      if [[ -n ${prog} ]] ; then
        shift 1
        $prog $@
      else
        appHelp
      fi
    fi
    ;;
esac

exit 0
