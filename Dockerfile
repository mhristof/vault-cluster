FROM vault

RUN apk add jq bash curl
RUN curl -sSL -o /usr/bin/bombardier https://github.com/codesenberg/bombardier/releases/download/v1.2.5/bombardier-linux-amd64 &&\
        chmod +x /usr/bin/bombardier
RUN mkdir /mikewashere/ && chown -R vault:vault /mikewashere/
