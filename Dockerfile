ARG ALPINE_VERSION="3.10"

FROM golang:alpine as build

ARG CFSSL_VERSION="v1.4.1"

RUN apk update && \
    apk add --no-cache gcc git make musl-dev && \
    git clone https://github.com/cloudflare/cfssl.git && \
    cd cfssl && \
    git checkout ${CFSSL_VERSION} && \
    make

FROM alpine:${ALPINE_VERSION}

ARG KUBECTL_VERSION="v1.15.6"
ARG BUILD_DATE=""

# see: http://label-schema.org/rc1/
LABEL org.label-schema.build-date="${BUILD_DATE}" \
      org.label-schema.description="Alpine Linux image with kubectl and cfssl." \
      org.label-schema.docker.cmd="docker run -it --rm cjmach/kubessl" \
      org.label-schema.name="cjmach/kubessl" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.url="https://github.com/cjmach/kubessl" \
      org.label-schema.vcs-ref="${SOURCE_COMMIT}" \
      org.label-schema.vcs-url="https://github.com/cjmach/kubessl" \
      org.label-schema.vendor="cjmach" \
      org.label-schema.version="${SOURCE_BRANCH}"

COPY --from=build /go/cfssl/bin /usr/local/bin
COPY scripts/* /usr/local/bin/

RUN chmod +x /usr/local/bin/gen* && \
    apk update && \
    apk add --no-cache ca-certificates curl && \
    rm -rfv /var/cache/apk && \
    curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

WORKDIR /mnt
