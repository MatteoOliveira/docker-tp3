FROM php:8.2-fpm

# Installer et activer l'extension mysqli
RUN docker-php-ext-install mysqli \
 && docker-php-ext-enable mysqli

WORKDIR /app
