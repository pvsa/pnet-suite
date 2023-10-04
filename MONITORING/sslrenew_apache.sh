#!/bin/sh

certbot renew -nvv --apache > /var/log/letsencrypt/renew.log 2>&1
LE_STATUS=$?

if [ /etc/init.d/httpd ]; then
        /etc/init.d/httpd reload
elif [ /etc/init.d/apache2 ]; then
        /etc/init.d/apache2 reload
elif [ systemctl is-active httpd ]
        systemctl reload httpd
else
        echo "no Apache webserver service for reload found"
fi

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
