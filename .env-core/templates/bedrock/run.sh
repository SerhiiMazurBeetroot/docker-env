#!/bin/sh

rm -rf /var/www/html/

composer create-project roots/bedrock .

if ! $(wp core is-installed); then
    if [ -n "$SITE_TITLE" ] && [ -n "$WP_USER" ] && [ -n "$WP_PASSWORD" ] && [ -n "$WP_SITEURL" ]; then
        echo "============================================="
        echo "=> WordPress is alread configured.";
        echo "============================================="

        wp core install \
            --title="Site ${SITE_TITLE}" \
            --admin_user="${WP_USER}" \
            --admin_password="${WP_PASSWORD}" \
            --admin_email="admin@example.com" \
            --url="${WP_SITEURL}" \
            --skip-email \
            --allow-root
    fi
else
    echo "============================================="
    echo "=> WordPress is alread configured.";
    echo "============================================="
fi

# Remove plugins and themes
wp plugin delete hello akismet --allow-root
wp theme delete twentynineteen twentytwenty twentytwentyone --allow-root

echo "=> Apache started..."
/usr/sbin/apache2ctl -D FOREGROUND
