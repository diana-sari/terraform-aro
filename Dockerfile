# Optional CI-like environment: Terraform + tflint + checkov for `make pr`.
# Usage:
#   docker build -t terraform-aro-ci .
#   docker run --rm -v "$PWD:/workspace" -w /workspace terraform-aro-ci make pr
#
# linux/amd64 URLs below; on Apple Silicon use: docker build --platform linux/amd64 ...

FROM python:3.12-slim-bookworm

RUN apt-get update \
  && apt-get install -y --no-install-recommends curl unzip ca-certificates make openssh-client git \
  && rm -rf /var/lib/apt/lists/*

ARG TERRAFORM_VERSION=1.12.2
RUN curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -o /tmp/tf.zip \
  && unzip /tmp/tf.zip -d /usr/local/bin \
  && rm /tmp/tf.zip

ARG TFLINT_VERSION=0.54.0
RUN curl -fsSL "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip" -o /tmp/tflint.zip \
  && unzip /tmp/tflint.zip -d /usr/local/bin \
  && rm /tmp/tflint.zip

RUN pip install --no-cache-dir --root-user-action=ignore checkov==3.2.495

RUN useradd --create-home --uid 1000 --shell /bin/bash tf
USER tf
WORKDIR /workspace
