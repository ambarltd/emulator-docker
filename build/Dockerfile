FROM alpine:3.19 AS haskell-base

RUN apk update
RUN apk add libffi-dev
RUN apk add ncurses-dev
RUN apk add libpq-dev
RUN apk add gmp-dev
RUN apk add zlib-dev
RUN apk add libc-dev
RUN apk add musl-dev
RUN apk add mariadb-connector-c-dev
RUN apk add pcre-dev

##################################################################################
##################################################################################
##################################################################################

FROM haskell-base AS haskell-build

RUN apk add git
RUN apk add curl
RUN apk add binutils-gold
RUN apk add gcc
RUN apk add g++
RUN apk add make
RUN apk add perl
RUN apk add pkgconfig
RUN apk add tar
RUN apk add xz

RUN curl --proto '=https' --tlsv1.3 -sSf https://get-ghcup.haskell.org | \
    BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
    BOOTSTRAP_HASKELL_GHC_VERSION="9.10.1" \
    BOOTSTRAP_HASKELL_INSTALL_NO_STACK=1 \
    sh

ENV PATH="/root/.ghcup/bin:$PATH"
ENV PATH="/root/.cabal/bin:$PATH"

WORKDIR /tmp
RUN git clone --recurse-submodules https://github.com/ambarltd/emulator.git
RUN mv /tmp/emulator /opt/emulator

WORKDIR /opt/emulator
RUN git fetch # just in case we have cached git clone
RUN git checkout v1.12
RUN cabal build exe:emulator
RUN cp $(cabal list-bin emulator) /tmp/emulator

##################################################################################
##################################################################################
##################################################################################

FROM haskell-base AS final

COPY --from=haskell-build /tmp/emulator /opt/emulator/emulator
RUN mkdir -p /opt/emulator/config

ENTRYPOINT ["sh", "-c", "rm -Rf /root/.local/share/ambar-emulator/queues/*.lock /root/.local/share/ambar-emulator/queues/**/*.lock && /opt/emulator/emulator $0 $@"]

CMD ["run", "--config", "/opt/emulator/config/config.yaml"]
