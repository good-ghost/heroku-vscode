FROM debian:buster-slim

RUN apt-get update \
 && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    dirmngr \
    dumb-init \
    htop \
    locales \
    man \
    nano \
    git \
    lsb-release \
    procps \
    ssh \
    sudo \
    vim \
    wget \
    xz-utils \
  && mkdir -p /usr/share/man/man1 \
  && apt-get install -y \
    default-jre-headless \
    openjdk-11-jre \
  && rm -rf /var/lib/apt/lists/*

# https://wiki.debian.org/Locale#Manually
RUN sed -i "s/# en_US.UTF-8/en_US.UTF-8/" /etc/locale.gen \
  && locale-gen
ENV LANG=en_US.UTF-8

RUN chsh -s /bin/bash
ENV SHELL=/bin/bash

RUN adduser --gecos '' --disabled-password coder && \
  echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

RUN curl -SsL https://github.com/boxboat/fixuid/releases/download/v0.4/fixuid-0.4-linux-amd64.tar.gz | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: coder\ngroup: coder\n" > /etc/fixuid/config.yml
    
RUN cd /tmp && \
  curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash - && \
  apt-get install -y nodejs && \
  mkdir -p /tmp/sfdx && \
  wget https://developer.salesforce.com/media/salesforce-cli/sfdx-linux-amd64.tar.xz && \
  tar xJf sfdx-linux-amd64.tar.xz -C sfdx --strip-components 1 && \
  /tmp/sfdx/install

RUN cd /tmp && \
  curl -L --silent \
  `curl --silent "https://api.github.com/repos/cdr/code-server/releases/latest" \
    | grep '"browser_download_url":' \
    | grep "linux-amd64" \
    |  sed -E 's/.*"([^"]+)".*/\1/' \
  `| tar -xzf - && \
  mv code-server* /usr/local/lib/code-server && \
  ln -s /usr/local/lib/code-server/code-server /usr/local/bin/code-server

RUN cd /tmp && \
  wget https://marketplace.visualstudio.com/_apis/public/gallery/publishers/salesforce/vsextensions/salesforcedx-vscode-expanded/50.8.0/vspackage && \
  code-server --install-extension salesforce.salesforcedx-vscode-expanded-50.8.0.vsix &&
  wget https://marketplace.visualstudio.com/_apis/public/gallery/publishers/HugoOM/vsextensions/sfdx-autoheader/0.7.1/vspackage && \
  code-server --install-extension HugoOM.sfdx-autoheader-0.7.1.vsix

ENV PORT=8080
EXPOSE 8080
USER coder
WORKDIR /home/coder
CMD sleep 5 && cat /home/coder/.config/code-server/config.yaml & /usr/local/bin/code-server --host 0.0.0.0 --port $PORT .
