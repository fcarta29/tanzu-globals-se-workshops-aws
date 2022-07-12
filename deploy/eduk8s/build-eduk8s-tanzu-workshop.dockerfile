FROM quay.io/eduk8s/base-environment:master as base
LABEL maintainer="Frank Carta <fcarta@vmware.com>"

USER root

RUN HOME=/root

# Install System libraries
#RUN echo "Installing System Libraries" \
 #   && apt-get update \
 #   && apt-get install -y build-essential python3.6 python3-pip python3-dev groff bash-completion git curl unzip wget findutils jq vim tree docker.io moreutils

# Install System libraries
RUN echo "Installing System Libraries" \
    && dnf install -y bash-completion tree git-all moreutils wget curl findutils jq vim moreutils

FROM base as k8sbase
ENV KUBECTL_VERSION=v1.19.6

# Install Kubectl
RUN echo "Installing Kubectl" \
    && wget -q https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl \
    && mv kubectl /usr/local/bin/kubectl \
    && which kubectl \
    && mkdir -p /etc/bash_completion.d \
    && kubectl completion bash > /etc/bash_completion.d/kubectl \
    && kubectl version --short --client

# Install Krew - needed for kubectx and kubens
RUN echo "Installing Krew" \
    && set -x; cd "$(mktemp -d)" \
    && OS="$(uname | tr '[:upper:]' '[:lower:]')" \
    && ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" \
    && KREW="krew-${OS}_${ARCH}" \
    && curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" \
    && tar zxvf "${KREW}.tar.gz" \
    && ./"${KREW}" install krew \
    && echo "export PATH=${KREW_ROOT:-$HOME/.krew}/bin:$PATH" >> /root/.bashrc

# Install Kubectx - need the PATH here because export above doesnt seem to take in effect yet here?
RUN echo "Installing kubectx" \
    && PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH" \
    && kubectl krew install ctx

# Install Kubens - need the PATH here because export above doesnt seem to take in effect yet here?
RUN echo "Installing kubens" \
    && PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH" \
    kubectl krew install ns

# Create Aliases
RUN echo "alias k=kubectl" >> /root/.profile \
    && echo "alias kubectx='kubectl ctx'" >> /root/.profile \
    && echo "alias kubens='kubectl ns'" >> /root/.profile

FROM k8sbase as clibase
ENV BAT_VERSION=v0.18.1
ENV ARGOCD_CLI_VERSION=v1.7.7
ENV ARGOCD_VERSION=v2.0.1
ENV KPACK_VERSION=0.5.0
ENV ISTIO_VERSION=1.7.4
ENV TKN_VERSION=0.17.2
ENV KUBESEAL_VERSION=v0.15.0

# Install bat
RUN echo "Installing bat" \  
    && curl -L https://github.com/sharkdp/bat/releases/download/${BAT_VERSION}/bat-${BAT_VERSION}-x86_64-unknown-linux-gnu.tar.gz --output bat-${BAT_VERSION}-x86_64-unknown-linux-gnu.tar.gz \
    && tar -zxvf bat-${BAT_VERSION}-x86_64-unknown-linux-gnu.tar.gz \
    && mv bat-${BAT_VERSION}-x86_64-unknown-linux-gnu /usr/local/bin/. \
    && ln -s /usr/local/bin/bat-${BAT_VERSION}-x86_64-unknown-linux-gnu/bat /usr/local/bin/bat

# Install AWS CLI
RUN echo "Installing AWS CLI" \
    && pip3 install --upgrade awscli

# Install Carvel tools
RUN echo "Installing K14s Carvel tools" \
    && wget -O- https://carvel.dev/install.sh | bash

# Install TMC CLI
COPY bin/tmc .
RUN echo "Installing TMC CLI" \
    && chmod +x tmc \
    && mv tmc /usr/local/bin/tmc \
    && which tmc \
    && tmc version

# Install Kubectl vSphere Plugin
COPY bin/kubectl-vsphere .
RUN echo "Installing Kubectl vSphere Plugin" \
    && mv kubectl-vsphere  /usr/local/bin/kubectl-vsphere  \
    && chmod +x /usr/local/bin/kubectl-vsphere

# Install Kustomize
RUN echo "Installing Kustomize" \
    && curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash \
    && mv kustomize /usr/local/bin/kustomize \
    && kustomize version

# Install Helm3
RUN echo "Installing Helm3" \
    && curl https://get.helm.sh/helm-v3.3.0-rc.2-linux-amd64.tar.gz --output helm.tar.gz \
    && tar -zxvf helm.tar.gz \
    && mv linux-amd64/helm /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm \
    && helm version

# Install KPACK CLI
COPY bin/kp-linux-${KPACK_VERSION} .
RUN echo "Installing kpack CLI" \
    && chmod +x kp-linux-${KPACK_VERSION} \
    && mv kp-linux-${KPACK_VERSION} /usr/local/bin/kp \
    && which kp \
    && kp version

# Install Istioctl
RUN echo "Installing Istioctl" \
    && curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} TARGET_ARCH=x86_64 sh - \
    && cd istio-${ISTIO_VERSION} \
    && cp $PWD/bin/istioctl /usr/local/bin/istioctl \
    && istioctl version

# Install ArgoCD
RUN echo "Installing ArgoCD" \
    && curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/$ARGOCD_VERSION/argocd-linux-amd64 \
    && chmod +x /usr/local/bin/argocd 
#&& argocd version

# Install Bitnami Sealed Secrets
RUN echo "Installing Bitnami Sealed Secrets" \
    && wget https://github.com/bitnami-labs/sealed-secrets/releases/download/$KUBESEAL_VERSION/kubeseal-linux-amd64 -O kubeseal \
    && install -m 755 kubeseal /usr/local/bin/kubeseal

# Install Tekton CLI
RUN echo "Installing Tekton CLI" \
    && curl -LO https://github.com/tektoncd/cli/releases/download/v${TKN_VERSION}/tkn_${TKN_VERSION}_Linux_x86_64.tar.gz --output tkn_${TKN_VERSION}_Linux_x86_64.tar.gz \
    && tar xvzf tkn_${TKN_VERSION}_Linux_x86_64.tar.gz -C /usr/local/bin/ tkn \
    && chmod +x /usr/local/bin/tkn \
    && tkn version

FROM clibase AS tanzucli
ENV TKG_VERSION=v1.5.4
ENV TANZU_CLI_VERSION=v0.11.6

# Install Tanzu CLI
COPY bin/tanzu-cli-bundle-${TKG_VERSION}-linux-amd64.tar .
RUN echo "Installing Tanzu CLI" \
    && mkdir -p tanzu \
    && tar xvf tanzu-cli-bundle-${TKG_VERSION}-linux-amd64.tar -C tanzu \
    && cd tanzu/cli \
    && install core/${TANZU_CLI_VERSION}/tanzu-core-linux_amd64 /usr/local/bin/tanzu \
    && tanzu init \
    && tanzu version 

# Install Tanzu CLI Plugins
RUN echo "Installing Tanzu CLI Plugins" \
    && cd tanzu \
    && tanzu plugin sync \
    #&& tanzu plugin install --local cli all \
    && tanzu plugin list

COPY bin/deploy.sh .
RUN echo "Copying Deploy Script" \
    && chmod +x deploy.sh

USER 1001

COPY --chown=1001:0 . /home/eduk8s/

RUN mv workshop /opt/workshop

RUN fix-permissions /home/eduk8s

# Leave Container Running for SSH Access - SHOULD REMOVE
#ENTRYPOINT ["tail", "-f", "/dev/null"]
