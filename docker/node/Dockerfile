FROM debian:bookworm-slim AS runtime

RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    curl \
    nano \
    jq \
    dnsutils \
    wget \
    unzip \
    lz4 \
    aria2 \
    pv \
    git \
    iputils-ping \
    iproute2 \
    bash-completion \
    && apt-get clean
WORKDIR /tmp
RUN wget https://github.com/FuelLabs/fuelup/releases/download/v0.27.0/fuelup-0.27.0-x86_64-unknown-linux-gnu.tar.gz -O fuelup.tar.gz && tar -xzvf fuelup.tar.gz && mv fuelup-*/* /usr/local/bin/fuelup && rm -rf /tmp/fuel*

# Create oeprator user
RUN useradd -m pilot

USER pilot
WORKDIR /home/pilot/
RUN fuelup toolchain install latest

ENV PATH=/home/pilot/.fuelup/bin:$PATH

RUN git clone https://github.com/FuelLabs/chain-configuration.git
RUN mkdir -p /home/pilot/.fuel-db

ENTRYPOINT ["fuel-core"]
CMD ["help"]