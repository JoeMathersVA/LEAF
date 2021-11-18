# FROM pelentan/leaf-app-base:1.1 as base
FROM leaf-app-base:1.3 as base

ARG SMTP_HOST 

RUN sed -i  "s/LEAF_EMAIL_SERVER/$SMTP_HOST/g" /etc/ssmtp/ssmtp.conf
RUN sed -i  "s/MAIL_HUB/$SMTP_HOST/g" /etc/ssmtp/ssmtp.conf
#temp to just make sure it's working
RUN sed -i  "s/smtp/$SMTP_HOST/g" /etc/ssmtp/ssmtp.conf
RUN sed -i  "s/localhost/$SMTP_HOST/g" /etc/ssmtp/ssmtp.conf

FROM base as dev 
# xdebug
# RUN pecl config-set php_ini "$PHP_INI_DIR/php.ini"
# RUN pecl install xdebug && docker-php-ext-enable xdebug
# COPY /docker/php/etc/xdebug.ini "$PHP_INI_DIR/conf.d/xdebug.ini"

FROM base as prod
COPY ./LEAF_Nexus /var/www/html/LEAF_Nexus
COPY ./LEAF_Request_Portal /var/www/html/LEAF_Request_Portal
COPY ./libs /var/www/html/libs
COPY ./health_checks /var/www/html/health_checks
RUN chmod +x /var/www/html/
RUN chown -R www-data:www-data /var/www
RUN chmod -R g+rwX /var/www
