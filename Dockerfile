FROM ubuntu:18.04 as builder

# docker build arguments
ARG JANUS_WITH_POSTPROCESSING="1"
ARG JANUS_WITH_BORINGSSL="0"
ARG JANUS_WITH_REST="1"
ARG JANUS_WITH_DATACHANNELS="0"
ARG JANUS_WITH_WEBSOCKETS="1"
ARG JANUS_WITH_MQTT="0"
ARG JANUS_WITH_PFUNIX="1"
ARG JANUS_WITH_RABBITMQ="0"

ARG BUILD_PLUGIN_AUDIOBRIDGE="0"
ARG BUILD_PLUGIN_ECHOTEST="0"
ARG BUILD_PLUGIN_LUA="0"
ARG BUILD_PLUGIN_RECORDPLAY="0"
ARG BUILD_PLUGIN_SIP="0"
ARG BUILD_PLUGIN_SIPRE="0"
ARG BUILD_PLUGIN_NOSIP="0"
ARG BUILD_PLUGIN_STREAMING="0"
ARG BUILD_PLUGIN_TEXTROOM="0"
ARG BUILD_PLUGIN_VIDEOCALL="0"
ARG BUILD_PLUGIN_VIDEOROOM="1"
ARG BUILD_PLUGIN_VOICEMAIL="0"

ARG JANUS_CONFIG_OPTIONS="\
    --prefix=/opt/janus \
    "

ARG JANUS_CORE_DEP="\
  libconfig-dev \
  libcurl4-openssl-dev \
  libglib2.0-dev \
  libjansson-dev \
  libssl-dev \
  pkg-config \
  "

ARG JANUS_REST_DEP="libmicrohttpd-dev"

ARG PLUGIN_AUDIOBRIDGE_DEP="libopus-dev"
ARG PLUGIN_SIP_DEP="libsofia-sip-ua-dev"
ARG PLUGIN_VOICEMAIL_DEP="libogg-dev"
ARG PLUGIN_LUA_DEP="liblua5.3-dev"

ARG JANUS_PP_DEP="libogg-dev"

# cmake for libwebsocket
# gtk-doc-tools for libnice
ARG JANUS_BUILD_DEP_EXT="\
  automake \
  cmake \
  gengetopt \
  gtk-doc-tools \
  git \
  libavcodec-dev \
  libavutil-dev \
  libavformat-dev \
  libtool \
  wget \
  "

RUN \
# make a list of dependencies to install with apt, and janus configuration flag
  export DEPENDENCIES="${JANUS_CORE_DEP} ${JANUS_BUILD_DEP_EXT}" \
  && export JANUS_CONFIG_OPTIONS="${JANUS_CONFIG_OPTIONS}" \
  && if [ $JANUS_WITH_POSTPROCESSING = "1" ]; then \
      export JANUS_CONFIG_OPTIONS="$JANUS_CONFIG_OPTIONS --enable-post-processing" \
      && export DEPENDENCIES="$DEPENDENCIES $JANUS_PP_DEP"; \ 
    fi \
  && if [ $JANUS_WITH_REST = "0" ]; then \
      export JANUS_CONFIG_OPTIONS="$JANUS_CONFIG_OPTIONS --disable-rest"; \
    else export DEPENDENCIES="${DEPENDENCIES} ${JANUS_REST_DEP}"; \
    fi \
  && if [ $JANUS_WITH_DATACHANNELS = "0" ]; then \
      export JANUS_CONFIG_OPTIONS="$JANUS_CONFIG_OPTIONS --disable-data-channels"; \
    fi \
  && if [ $JANUS_WITH_WEBSOCKETS = "0" ]; then \
      export JANUS_CONFIG_OPTIONS="$JANUS_CONFIG_OPTIONS --disable-websockets"; \
    fi \
  && if [ $JANUS_WITH_MQTT = "0" ]; then \
      export JANUS_CONFIG_OPTIONS="$JANUS_CONFIG_OPTIONS --disable-mqtt"; \
    fi \
  && if [ $JANUS_WITH_PFUNIX = "0" ]; then \
      export JANUS_CONFIG_OPTIONS="$JANUS_CONFIG_OPTIONS --disable-unix-sockets"; \
    fi \
  && if [ $JANUS_WITH_RABBITMQ = "0" ]; then \
      export JANUS_CONFIG_OPTIONS="$JANUS_CONFIG_OPTIONS --disable-rabbitmq"; \
    fi \
  && if [ $BUILD_PLUGIN_AUDIOBRIDGE = "0" ]; then \
      export JANUS_CONFIG_OPTIONS="$JANUS_CONFIG_OPTIONS --disable-plugin-audiobridge"; \
    else export DEPENDENCIES="$DEPENDENCIES ${PLUGIN_AUDIOBRIDGE_DEP}"; \ 
    fi \
  && if [ $BUILD_PLUGIN_ECHOTEST = "0" ]; then \
      export JANUS_CONFIG_OPTIONS="$JANUS_CONFIG_OPTIONS --disable-plugin-echotest"; \
    fi \
  && if [ $BUILD_PLUGIN_LUA = "1" ]; then \
      export JANUS_CONFIG_OPTIONS="$JANUS_CONFIG_OPTIONS --enable-plugin-lua" \
      && DEPENDENCIES="$DEPENDENCIES ${PLUGIN_LUA_DEP}"; \
    fi \
  && if [ $BUILD_PLUGIN_RECORDPLAY = "0" ]; then \
      export JANUS_CONFIG_OPTIONS="$JANUS_CONFIG_OPTIONS --disable-plugin-recordplay"; \
    fi \
  && if [ $BUILD_PLUGIN_SIP = "0" ]; then \
      export JANUS_CONFIG_OPTIONS="$JANUS_CONFIG_OPTIONS --disable-plugin-sip"; \
      else DEPENDENCIES="$DEPENDENCIES ${PLUGIN_SIP_DEP}"; \
    fi \
  && if [ $BUILD_PLUGIN_SIP = "0" ]; then \
      export JANUS_CONFIG_OPTIONS="$JANUS_CONFIG_OPTIONS --disable-plugin-sipre"; \
      else DEPENDENCIES="$DEPENDENCIES ${PLUGIN_SIP_DEP}"; \
    fi \
  && if [ $BUILD_PLUGIN_SIP = "0" ]; then \
      export JANUS_CONFIG_OPTIONS="$JANUS_CONFIG_OPTIONS --disable-plugin-nosip"; \
      else DEPENDENCIES="$DEPENDENCIES ${PLUGIN_SIP_DEP}"; \
    fi \
  && if [ $BUILD_PLUGIN_STREAMING = "0" ]; then \
      export JANUS_CONFIG_OPTIONS="$JANUS_CONFIG_OPTIONS --disable-plugin-streaming"; \
    fi \
  && if [ $BUILD_PLUGIN_VIDEOCALL = "0" ]; then \
      export JANUS_CONFIG_OPTIONS="$JANUS_CONFIG_OPTIONS --disable-plugin-videocall"; \
    fi \
  && if [ $BUILD_PLUGIN_VIDEOROOM = "0" ]; then \
      export JANUS_CONFIG_OPTIONS="$JANUS_CONFIG_OPTIONS --disable-plugin-streaming"; \
    fi \
  && if [ $BUILD_PLUGIN_VOICEMAIL = "0" ]; then \
      export JANUS_CONFIG_OPTIONS="$JANUS_CONFIG_OPTIONS --disable-plugin-voicemail"; \
    else DEPENDENCIES="$DEPENDENCIES ${PLUGIN_VOICEMAIL_DEP}"; \
    fi \
  && apt-get update \
  && apt-get install -y ${DEPENDENCIES} \
# build libnice
  && git clone https://gitlab.freedesktop.org/libnice/libnice $HOME/libnice \
  && cd $HOME/libnice \
  && ./autogen.sh \
  && ./configure --prefix=/usr \
  && make && make install \
# build libsrtp
  && wget https://github.com/cisco/libsrtp/archive/v2.2.0.tar.gz -P $HOME/libsrtp \
  && cd $HOME/libsrtp \
  && tar xfv v2.2.0.tar.gz \
  && cd libsrtp-2.2.0 \
  && ./configure --prefix=/usr --enable-openssl \
  && make shared_library && make install \
# build libwebsockets
  # if [ $JANUS_WITH_WEBSOCKETS = "1" ]; then git clone https://libwebsockets.org/repo/libwebsockets $HOME/libwebsockets \
  && if [ $JANUS_WITH_WEBSOCKETS = "1" ]; then git clone https://github.com/warmcat/libwebsockets.git $HOME/libwebsockets \
  && cd $HOME/libwebsockets \
  && git checkout v2.4-stable \
  && mkdir build \
  && cd build \
  && cmake -DLWS_MAX_SMP=1 -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_C_FLAGS="-fpic" .. \
  && make && make install \
  ; fi \
# build janus
  && git clone https://github.com/meetecho/janus-gateway.git $HOME/janus-gateway \
  && cd $HOME/janus-gateway \
  && ./autogen.sh \
  && ./configure ${JANUS_CONFIG_OPTIONS} \
  && make && make install \
# folder ownership
  && /usr/sbin/groupadd -r janus && /usr/sbin/useradd -r -g janus janus \
  && chown -R janus:janus /opt/janus

RUN ls /opt/janus/bin

USER janus

CMD ["/opt/janus/bin/janus-pp-rec", "-h"]

FROM ubuntu:18.04

ARG JANUS_PP_DEP="\
  libglib2.0-dev \
  "
COPY --from=builder /opt/janus /opt/janus

RUN \
  apt-get update && apt-get install -y ${JANUS_PP_DEP} \
# folder ownership
  && /usr/sbin/groupadd -r janus && /usr/sbin/useradd -r -g janus janus \
  && chown -R janus:janus /opt/janus
RUN \
  apt-get install -y libjansson-dev

RUN \
  apt-get install -y libavcodec-dev \
  libavutil-dev \
  libavformat-dev
USER janus

CMD ["/opt/janus/bin/janus-pp-rec", "-h"]
