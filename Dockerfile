ARG BASE_TAG=2.65.0

FROM curlimages/curl AS bins

ARG TARGETOS
ARG TARGETARCH

ARG KUBELOGIN_TAG=v0.1.1
ARG DUMB_INIT_VERSION=1.2.5

ARG KUBECTL_VERSION=v1.29.3

USER root
RUN if [ "$(uname -m)" = "x86_64" ]; then \
      curl -sSLo /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_x86_64; \
    elif [ "$(uname -m)" = "aarch64" ]; then \
      curl -sSLo /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_aarch64; \
    elif [ "$(uname -m)" = "arm64" ]; then \
      curl -sSLo /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_arm64.deb; \
    elif [ "$(uname -m)" = "ppc64le" ]; then \
      curl -sSLo /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_ppc64le; \
    elif [ "$(uname -m)" = "s390x" ]; then \
      curl -sSLo /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_s390x; \
    else \
      echo "Unsupported architecture: $(uname -m)"; exit 1; \
    fi && \
    chmod +x /usr/local/bin/dumb-init && \
    curl -fLo kubelogin.zip https://github.com/Azure/kubelogin/releases/download/${KUBELOGIN_TAG}/kubelogin-${TARGETOS}-${TARGETARCH}.zip && \
    unzip kubelogin.zip && \
    find bin -name kubelogin -type f -exec mv {} /usr/local/bin/kubelogin \; && \
    chmod +x /usr/local/bin/kubelogin && \
    curl -fLo /usr/local/bin/kubectl \
    "https://dl.k8s.io/release/$(test ! -z "${KUBECTL_VERSION}" && echo ${KUBECTL_VERSION} || curl -L -s https://dl.k8s.io/release/stable.txt)/bin/${TARGETOS}/${TARGETARCH}/kubectl" && \
    chmod +x /usr/local/bin/kubectl


FROM mcr.microsoft.com/azure-cli:${BASE_TAG}

RUN addgroup -S licenseware && adduser -S licenseware -G licenseware

COPY --from=bins /usr/local/bin/kubelogin /usr/local/bin/kubelogin
COPY --from=bins /usr/local/bin/dumb-init /usr/local/bin/dumb-init
COPY --from=bins /usr/local/bin/kubectl /usr/local/bin/kubectl

USER licenseware:licenseware

ENTRYPOINT [ "dumb-init", "--" ]
CMD [ "az", "--help" ]
