FROM quay.io/eduk8s/base-environment:master

USER root

# Install System libraries
RUN echo "Installing System Libraries" \
    && apt-get update \
    && apt-get install -y build-essential python3.6 python3-pip python3-dev groff bash-completion git curl unzip wget findutils jq vim tree docker.io moreutils

USER 1001

COPY --chown=1001:0 . /home/eduk8s/

RUN mv /home/eduk8s/workshop /opt/workshop

RUN fix-permissions /home/eduk8s
