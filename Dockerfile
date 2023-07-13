FROM php:8.2-fpm

# Arguments defined in docker-compose.yml
ARG user
ARG uid

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    wget \
    libaio1

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# RUN chown -R $user:$user /var/www/storage \
#     chown -R $user:$user /var/www/bootstrap/cache 
# chmod -R ugo+rw storage

# Config Oracle Client
ENV LD_LIBRARY_PATH="/opt/oracle/instantclient/"
ENV ORACLE_HOME="/opt/oracle/instantclient/"
ENV OCI_HOME="/opt/oracle/instantclient/"
ENV OCI_LIB_DIR="/opt/oracle/instantclient/"
ENV OCI_INCLUDE_DIR="/opt/oracle/instantclient/sdk/include"
ENV OCI_VERSION=19

# Download Oracle
RUN mkdir -p /opt/oracle/instantclient \
    chown $user:$user /opt/oracle/instantclient \
    cd /opt/oracle/instantclient

RUN wget https://download.oracle.com/otn_software/linux/instantclient/1919000/instantclient-basic-linux.arm64-19.19.0.0.0dbru.zip -P /opt/oracle/instantclient
RUN wget https://download.oracle.com/otn_software/linux/instantclient/1919000/instantclient-sdk-linux.arm64-19.19.0.0.0dbru.zip -P /opt/oracle/instantclient

RUN unzip /opt/oracle/instantclient/instantclient-basic-linux.arm64-19.19.0.0.0dbru.zip  -x -d /opt/oracle/instantclient
RUN unzip /opt/oracle/instantclient/instantclient-sdk-linux.arm64-19.19.0.0.0dbru.zip -x -d /opt/oracle/instantclient

RUN mv /opt/oracle/instantclient/instantclient_19_19/* /opt/oracle/instantclient

RUN ln -f /opt/oracle/instantclient/libclntsh.so.19.1 /opt/oracle/instantclient/libclntsh.so
RUN ln -f /opt/oracle/instantclient/libocci.so.19.1 /opt/oracle/instantclient/libocci.so

# Config Oci8 and Enbale Extension
RUN echo 'instantclient,/opt/oracle/instantclient' | pecl install oci8

RUN docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/opt/oracle/instantclient
RUN docker-php-ext-install pdo_oci
RUN docker-php-ext-enable oci8

RUN echo /opt/oracle/instantclient/ > /etc/ld.so.conf.d/oracle-insantclient.conf
RUN ldconfig

# Enable Extension Sockets
RUN docker-php-ext-install sockets
RUN docker-php-ext-enable sockets

# Set working directory
WORKDIR /var/www

USER $user
