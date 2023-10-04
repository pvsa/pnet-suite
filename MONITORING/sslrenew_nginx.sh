#!/bin/sh

certbot renew -nvv --nginx > /var/log/letsencrypt/renew.log 2>&1
LE_STATUS=$?

/etc/init.d/nginx reload
LE_STATUS2=$?

if [ "$LE_STATUS" != 0 ] ; then
    echo Automated renewal failed:
    cat /var/log/letsencrypt/renew.log
fi

if [ $LE_STATUS2 != 0 ] ; then
    echo Nginx Reload failed.
    tail -n 20 /var/log/nginx/error_log
fi

if [ "$LE_STATUS" != 0 ] || [ $LE_STATUS2 != 0 ]; then
        exit 1
fi

