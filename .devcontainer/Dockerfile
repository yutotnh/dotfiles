FROM mcr.microsoft.com/devcontainers/base:jammy

# Install Homebrew requirements
# https://docs.brew.sh/Homebrew-on-Linux#requirements
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends build-essential \
                                                  procps \
                                                  curl \
                                                  file \
                                                  git
