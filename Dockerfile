ARG BASE_TAG=2.57.0

ARG TARGETOS=linux
ARG TARGETARCH=amd64

ARG KUBELOGIN_TAG=v0.1.1
ARG DUMB_INIT_VERSION=1.2.5

ARG KUBECTL_VERSION

FROM curlimages/curl AS bins

ARG TARGETOS
ARG TARGETARCH

ARG KUBELOGIN_TAG
ARG DUMB_INIT

ARG KUBECTL_VERSION

USER root
RUN curl -fLo kubelogin.zip \
  https://github.com/Azure/kubelogin/releases/download/${KUBELOGIN_TAG}/kubelogin-${TARGETOS}-${TARGETARCH}.zip && \
  unzip kubelogin.zip && \
  find bin -name kubelogin -type f -exec mv {} /usr/local/bin/kubelogin \; && \
  chmod +x /usr/local/bin/kubelogin && \
  curl -fLo /usr/local/bin/dumb-init "https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_x86_64" && \
  chmod +x /usr/local/bin/dumb-init && \
  curl -fLo /usr/local/bin/kubectl \
  "https://dl.k8s.io/release/$(test ! -z "${KUBECTL_VERSION}" && echo ${KUBECTL_VERSION} || curl -L -s https://dl.k8s.io/release/stable.txt)/bin/${TARGETOS}/${TARGETARCH}/kubectl" && \
  chmod +x /usr/local/bin/kubectl


FROM --platform=$TARGETOS/$TARGETARCH mcr.microsoft.com/azure-cli:${BASE_TAG}

RUN addgroup -S licenseware && adduser -S licenseware -G licenseware

COPY --from=bins /usr/local/bin/kubelogin /usr/local/bin/kubelogin
COPY --from=bins /usr/local/bin/dumb-init /usr/local/bin/dumb-init
COPY --from=bins /usr/local/bin/kubectl /usr/local/bin/kubectl

USER licenseware:licenseware

ENTRYPOINT [ "dumb-init", "--" ]
CMD [ "az", "--help" ]
