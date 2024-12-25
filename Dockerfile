FROM debian:bookworm AS builder

ENV ASTERISK_VERSION=22.1.0
ENV DEBIAN_FRONTEND=noninteractive

RUN    set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends git autoconf automake ca-certificates

# Download src
RUN \
    git clone --branch ${ASTERISK_VERSION} --single-branch --depth 1 https://github.com/asterisk/asterisk.git /usr/local/src/asterisk

# Install asterisk
WORKDIR /usr/local/src/asterisk
RUN \
    yes | contrib/scripts/install_prereq install
RUN \
    ./bootstrap.sh && ./configure --with-format-mp3 --with-musiconhold --with-odbc --with-config-odbc --with-cdr-adaptive-odbc

RUN \
        make menuselect.makeopts \
    && menuselect/menuselect --disable BUILD_NATIVE --disable-all \
        --enable chan_rtp \
        --enable chan_pjsip \
        --enable cdr_csv \
        --enable bridge_native_rtp \
        --enable bridge_simple \
        --enable codec_alaw \
        --enable codec_ulaw \
        --enable codec_speex \
        --enable codec_opus \
        --enable codec_resample \
        --enable format_gsm \
        --enable format_wav \
        --enable format_wav_gsm \
        --enable format_pcm \
        --enable format_ogg_vorbis \
        --enable format_h264 \
        --enable format_h263 \
        --enable func_callerid \
        --enable func_cdr \
        --enable func_channel \
        --enable func_curl \
        --enable func_cut \
        --enable func_db \
        --enable func_logic \
        --enable func_math \
        --enable func_sprintf \
        --enable func_strings \
        --enable func_base64 \
        --enable func_uri \
        --enable func_shell \
        --enable app_db \
        --enable app_dial \
        --enable app_echo \
        --enable app_exec \
        --enable app_mixmonitor \
        --enable app_originate \
        --enable app_playback \
        --enable app_playtones \
        --enable app_sendtext \
        --enable app_stack \
        --enable app_transfer \
        --enable app_system \
        --enable app_verbose \
        --enable pbx_config \
        --enable pbx_realtime \
        --enable pbx_spool \
        --enable res_ari \
        --enable res_ari_applications \
        --enable res_ari_asterisk \
        --enable res_ari_bridges \
        --enable res_ari_channels \
        --enable res_ari_device_states \
        --enable res_ari_endpoints \
        --enable res_ari_events \
        --enable res_ari_mailboxes \
        --enable res_ari_model \
        --enable res_ari_playbacks \
        --enable res_ari_recordings \
        --enable res_ari_sounds \
        --enable res_clioriginate \
        --enable res_pjproject \
        --enable res_pjsip \
        --enable res_pjsip_authenticator_digest \
        --enable res_pjsip_caller_id \
        --enable res_pjsip_config_wizard \
        --enable res_pjsip_dialog_info_body_generator \
        --enable res_pjsip_diversion \
        --enable res_pjsip_dlg_options \
        --enable res_pjsip_dtmf_info \
        --enable res_pjsip_empty_info \
        --enable res_pjsip_endpoint_identifier_anonymous \
        --enable res_pjsip_endpoint_identifier_ip \
        --enable res_pjsip_endpoint_identifier_user \
        --enable res_pjsip_exten_state \
        --enable res_pjsip_header_funcs \
        --enable res_pjsip_logger \
        --enable res_pjsip_messaging \
        --enable res_pjsip_mwi \
        --enable res_pjsip_mwi_body_generator \
        --enable res_pjsip_nat \
        --enable res_pjsip_notify \
        --enable res_pjsip_one_touch_record_info \
        --enable res_pjsip_outbound_authenticator_digest \
        --enable res_pjsip_outbound_publish \
        --enable res_pjsip_outbound_registration \
        --enable res_pjsip_path \
        --enable res_pjsip_pidf_body_generator \
        --enable res_pjsip_pidf_digium_body_supplement \
        --enable res_pjsip_pidf_eyebeam_body_supplement \
        --enable res_pjsip_publish_asterisk \
        --enable res_pjsip_refer \
        --enable res_pjsip_registrar \
        --enable res_pjsip_rfc3326 \
        --enable res_pjsip_sdp_rtp \
        --enable res_pjsip_send_to_voicemail \
        --enable res_pjsip_session \
        --enable res_pjsip_sips_contact \
        --enable res_pjsip_t38 \
        --enable res_pjsip_transport_websocket \
        --enable res_pjsip_xpidf_body_generator \
        --enable res_realtime \
        --enable res_rtp_asterisk \
        --enable res_sorcery_astdb \
        --enable res_sorcery_config \
        --enable res_sorcery_memory \
        --enable res_srtp \
        --enable res_corosync \
        --enable astcanary \
        --enable OPTIONAL_API \
        --enable MOH-OPSOUND-WAV \
        --enable CORE-SOUNDS-EN-WAV \
        --enable EXTRA-SOUNDS-EN-WAV \
        --enable CORE-SOUNDS-IT-WAV \
        menuselect.makeopts
RUN \
    make all
RUN \
    make install \
# Create samples and move them to the /opt/asterisk-samples/
    && make samples
RUN \
    make install-headers \
    && mkdir -p /opt/asterisk-samples/ \
    && mv /etc/asterisk/* /opt/asterisk-samples/

# Cleanup
# RUN \
#     make dist-clean \
#     && make clean

FROM debian:bookworm

COPY --from=builder /etc/asterisk /etc/asterisk
COPY --from=builder /run/asterisk /run/asterisk
COPY --from=builder /run/asterisk /run/asterisk
COPY --from=builder /usr/lib/asterisk /usr/lib/asterisk
COPY --from=builder /usr/lib/libasterisk* /usr/lib/
COPY --from=builder /usr/sbin /usr/sbin
COPY --from=builder /usr/share/man /usr/share/man
COPY --from=builder /var/cache/asterisk /var/cache/asterisk
COPY --from=builder /var/lib/asterisk /var/lib/asterisk
COPY --from=builder /var/log/asterisk /var/log/asterisk
COPY --from=builder /var/spool/asterisk /var/spool/asterisk
COPY --from=builder /opt/asterisk-samples /opt/asterisk-samples

# Postinstall
RUN \
    addgroup --system --gid 1000 asterisk \
    && adduser --system --uid 1000 --ingroup asterisk --quiet -home /var/lib/asterisk --no-create-home --disabled-login --gecos "Asterisk PBX daemon" asterisk \
    && chown -R asterisk:dialout /var/*/asterisk \
    && chmod -R 750 /var/spool/asterisk
# Optional packages
RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        sendemail libnet-ssleay-perl \
        libio-socket-ssl-perl libcap2-bin curl sox \
        uuid libxml2 libxslt1.1 libresample1 libc-client2007e binutils libgsm1 doxygen zlib1g libsndfile1 \
        libunbound8 libfftw3-bin libfftw3-single3 libcodec2-1.0 libsrtp2-1 libc-client2007e libspandsp2 gir1.2-ical-3.0 libical3 \
        libpopt0 libnewt0.52 libcfg7 libcorosync-common4 libiksemel3 libcap2 libjack-jackd2-0 libradcli4 libbluetooth3 libssl3 \
        liburiparser1 liblua5.2-0 libgmime-3.0-0 gir1.2-gmime-3.0 libneon27 libpq5 xmlstarlet bison flex \
        libcurl4 libportaudio2 libportaudiocpp0 libasound2 libvorbis0a libvorbisenc2 libvorbisfile3 libogg0 libspeexdsp1 libspeex1 \
    && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 5060/udp 5061/udp 5062/udp

STOPSIGNAL SIGTERM

WORKDIR /var/lib/asterisk/

ENTRYPOINT ["/usr/sbin/asterisk","-f","-n","-Uasterisk","-Gdialout"]

CMD ["-v"]
