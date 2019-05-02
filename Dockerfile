FROM ubuntu:18.04 as builder

# docker build arguments
ARG BUILD_SRC="/usr/local/src"
ARG JANUS_WITH_POSTPROCESSING="1"
ARG JANUS_WITH_BORINGSSL="0"
ARG JANUS_WITH_REST="1"
ARG JANUS_WITH_DATACHANNELS="0"
ARG JANUS_WITH_WEBSOCKETS="1"
ARG JANUS_WITH_MQTT="0"
ARG JANUS_WITH_PFUNIX="1"
ARG JANUS_WITH_RABBITMQ="0"

ARG JANUS_CONFIG_OPTIONS="\
    --prefix=/opt/janus \
    "

# dependencies of janus
ARG JANUS_BUILD_DEPS_DEV="\
  automake \
  gengetopt \
  git \
  libavcodec-dev \
  libavutil-dev \
  libavformat-dev \
  libconfig-dev \
  libcurl4-openssl-dev \
  libglib2.0-dev \
  libjansson-dev \
  liblua5.3-dev \
  libmicrohttpd-dev \
  libogg-dev \
  libopus-dev \
  libsofia-sip-ua-dev \
  libsrtp-dev \
  libssl-dev \
  libtool \
  pkg-config \
  wget \
  "

# dependency for libnice
ARG JANUS_BUILD_DEP_LIBNICE="gtk-doc-tools"

# dependency for libwebsocket
ARG JANUS_BUILD_DEP_LIBWEBSOCKET="cmake"

RUN \
  export JANUS_WITH_POSTPROCESSING="${JANUS_WITH_POSTPROCESSING}"\
  && export JANUS_WITH_BORINGSSL="${JANUS_WITH_BORINGSSL}"\
  && export JANUS_WITH_DOCS="${JANUS_WITH_DOCS}"\
  && export JANUS_WITH_REST="${JANUS_WITH_REST}"\
  && export JANUS_WITH_DATACHANNELS="${JANUS_WITH_DATACHANNELS}"\
  && export JANUS_WITH_WEBSOCKETS="${JANUS_WITH_WEBSOCKETS}"\
  && export JANUS_WITH_MQTT="${JANUS_WITH_MQTT}"\
  && export JANUS_WITH_PFUNIX="${JANUS_WITH_PFUNIX}"\
  && export JANUS_WITH_RABBITMQ="${JANUS_WITH_RABBITMQ}"\
  && export JANUS_BUILD_DEPS_DEV="${JANUS_BUILD_DEPS_DEV}"\
  && export JANUS_CONFIG_OPTIONS="${JANUS_CONFIG_OPTIONS}"\
  && export DEPENDENCIES="${JANUS_BUILD_DEPS_DEV} ${JANUS_BUILD_DEP_LIBNICE} ${JANUS_BUILD_DEP_LIBWEBSOCKET}"\
  && if [ $JANUS_WITH_POSTPROCESSING = "1" ]; then export JANUS_CONFIG_OPTIONS="$JANUS_CONFIG_OPTIONS --enable-post-processing"; fi \
  && if [ $JANUS_WITH_REST = "0" ]; then export JANUS_CONFIG_OPTIONS="$JANUS_CONFIG_OPTIONS --disable-rest"; fi \
  && if [ $JANUS_WITH_DATACHANNELS = "0" ]; then export JANUS_CONFIG_OPTIONS="$JANUS_CONFIG_OPTIONS --disable-data-channels"; fi \
  && if [ $JANUS_WITH_WEBSOCKETS = "0" ]; then export JANUS_CONFIG_OPTIONS="$JANUS_CONFIG_OPTIONS --disable-websockets"; fi \
  && if [ $JANUS_WITH_MQTT = "0" ]; then export JANUS_CONFIG_OPTIONS="$JANUS_CONFIG_OPTIONS --disable-mqtt"; fi \
  && if [ $JANUS_WITH_PFUNIX = "0" ]; then export JANUS_CONFIG_OPTIONS="$JANUS_CONFIG_OPTIONS --disable-unix-sockets"; fi \
  && if [ $JANUS_WITH_RABBITMQ = "0" ]; then export JANUS_CONFIG_OPTIONS="$JANUS_CONFIG_OPTIONS --disable-rabbitmq"; fi \
  && apt-get update \
  && apt-get install -y ${DEPENDENCIES}

RUN \
# build libnice
  git clone https://gitlab.freedesktop.org/libnice/libnice $HOME/libnice \
  && cd $HOME/libnice \
  && ./autogen.sh \
  && ./configure --prefix=/usr \
  && make && make install

RUN \
# build libsrtp
  wget https://github.com/cisco/libsrtp/archive/v2.2.0.tar.gz -P $HOME/libsrtp \
  && cd $HOME/libsrtp \
  && tar xfv v2.2.0.tar.gz \
  && cd libsrtp-2.2.0 \
  && ./configure --prefix=/usr --enable-openssl \
  && make shared_library && make install

RUN \
# build libwebsockets
  # if [ $JANUS_WITH_WEBSOCKETS = "1" ]; then git clone https://libwebsockets.org/repo/libwebsockets $HOME/libwebsockets \
  if [ $JANUS_WITH_WEBSOCKETS = "1" ]; then git clone https://github.com/warmcat/libwebsockets.git $HOME/libwebsockets \
  && cd $HOME/libwebsockets \
  && git checkout v2.4-stable \
  && mkdir build \
  && cd build \
  && cmake -DLWS_MAX_SMP=1 -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_C_FLAGS="-fpic" .. \
  && make && make install \
  ; fi

RUN \
# build janus
  git clone https://github.com/meetecho/janus-gateway.git $HOME/janus-gateway \
  && cd $HOME/janus-gateway \
  && ./autogen.sh \
  && ./configure ${JANUS_CONFIG_OPTIONS} \
  && make && make install

RUN \
# folder ownership
  /usr/sbin/groupadd -r janus && /usr/sbin/useradd -r -g janus janus \
  && chown -R janus:janus /opt/janus

USER janus

CMD ["/opt/janus/bin/janus", "-h"]

FROM ubuntu:18.04

COPY --from=builder /opt/janus /opt/janus

RUN \
  apt-get update && apt-get install -y libconfig-dev \
# folder ownership
  && /usr/sbin/groupadd -r janus && /usr/sbin/useradd -r -g janus janus \
  && chown -R janus:janus /opt/janus

USER janus

CMD ["/opt/janus/bin/janus", "-h"]
