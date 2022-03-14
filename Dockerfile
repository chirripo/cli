FROM ubuntu:20.04

RUN apt-get clean -y && apt-get update -y && apt-get install -y locales

# Set env vars.
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV PHP_VERSION=8.1
ENV NVM_VERSION 0.39.1
ENV NODE_VERSION 16.14.0
ENV NVM_DIR $HOME/.nvm

EXPOSE 22

RUN \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --allow-downgrades \
    --allow-remove-essential --allow-change-held-packages \
    install software-properties-common

RUN add-apt-repository ppa:ondrej/php

# Basic packages
RUN \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes install \
    supervisor \
    curl \
    wget \
    zip \
    unzip \
    git \
    mysql-client \
    pv \
    apt-transport-https \
    vim \
    patch \
    openssh-server \
    --no-install-recommends && \
    # Cleanup
    DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# PHP packages
RUN \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --allow-downgrades \
    --allow-remove-essential --allow-change-held-packages install \
    php${PHP_VERSION}-common \
    php${PHP_VERSION}-cli \
    php-pear \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-sqlite \
    php${PHP_VERSION}-memcache \
    php${PHP_VERSION}-intl \
    php-xdebug \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-bcmath \
    --no-install-recommends && \
    # Cleanup
    DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# Install nvm and a default node version
RUN \
    mkdir $NVM_DIR && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash && \
    . $NVM_DIR/nvm.sh && \
    nvm install $NODE_VERSION && \
    nvm alias default $NODE_VERSION && \
    # Install global node packages
    npm install -g npm yarn gulp-cli

ENV PATH /.npm/versions/node/$NODE_VERSION/bin:$PATH

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Drush Launcher.
RUN wget -O /tmp/drush.phar https://github.com/drush-ops/drush-launcher/releases/download/0.6.0/drush.phar
RUN chmod +x /tmp/drush.phar
RUN mv /tmp/drush.phar /usr/local/bin/drush

# Install Robo
RUN wget https://robo.li/robo.phar
RUN chmod +x robo.phar && mv robo.phar /usr/local/bin/robo

# PHP settings changes
RUN sed -i 's/memory_limit = .*/memory_limit = 512M/' /etc/php/${PHP_VERSION}/cli/php.ini && \
    sed -i 's/max_execution_time = .*/max_execution_time = 300/' /etc/php/${PHP_VERSION}/cli/php.ini

WORKDIR /var/www/html

# Add Composer bin directory to PATH
ENV PATH /root/.composer/vendor/bin:$PATH

# SSH settigns
COPY config/.ssh /root/.ssh
RUN mkdir /var/run/sshd

# Startup script
COPY ./startup.sh /opt/startup.sh
RUN chmod +x /opt/startup.sh

# Starter script
ENTRYPOINT ["/opt/startup.sh"]

# By default, launch ssh to keep the container running.
CMD /usr/sbin/sshd -D
