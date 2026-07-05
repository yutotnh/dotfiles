FROM mcr.microsoft.com/devcontainers/base:jammy

# Install Nix requirements
# https://nix.dev/manual/nix/stable/installation/installing-binary#linux
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends curl \
                                                  xz-utils \
                                                  git
