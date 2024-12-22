FROM debian:bookworm AS builder

#ENV ASTERISK_VERSION=certified-20.7-cert3
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
#RUN \
#    contrib/scripts/install_prereq test
RUN \
    ./bootstrap.sh && ./configure --with-format-mp3 --with-musiconhold --with-odbc --with-config-odbc --with-cdr-adaptive-odbc
#    ./bootstrap.sh && ./configure CFLAGS=’-DPJ_HAS_IPV6=1’

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
        --enable app_db \
        --enable app_dial \
        --enable app_echo \
        --enable app_exec \
        --enable app_mixmonitor \
        --enable app_originate \
        --enable app_festival \
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
RUN \
    make dist-clean \
    && make clean

# Postinstall
RUN \
    addgroup --system --gid 1000 asterisk \
    && adduser --system --uid 1000 --ingroup asterisk --quiet -home /var/lib/asterisk --no-create-home --disabled-login --gecos "Asterisk PBX daemon" asterisk \
    && chown -R asterisk:dialout /var/*/asterisk \
    && chmod -R 750 /var/spool/asterisk
# Optional packages
RUN \
    && sed -i -e's/ main/ main contrib non-free non-free-firmware/g' /etc/apt/sources.list.d/debian.sources \
    && apt-get install -y --no-install-recommends \
        sendemail libnet-ssleay-perl \
        libio-socket-ssl-perl libcap2-bin
RUN \
	apt-get install -y --no-install-recommends \
        espeak-ng libespeak-ng-libespeak1 libespeak-ng-dev libespeak-ng-libespeak-dev espeak-ng-espeak speech-dispatcher-espeak-ng \
        libsamplerate0-dev libsamplerate0 libsndfile1 libsndfile1-dev
        # espeak libespeak-dev speech-dispatcher-espeak libespeak1 \



# Download src
RUN \
    git clone --branch v5.0 --single-branch --depth 1 https://github.com/zaf/Asterisk-eSpeak.git /usr/local/src/espeak

# Install asterisk
WORKDIR /usr/local/src/espeak

RUN \
    make && make install
RUN \
    make samples

RUN \
    rm -rf /var/lib/apt/lists/*

EXPOSE 5060/udp 5061/udp 5062/udp

STOPSIGNAL SIGTERM

WORKDIR /var/lib/asterisk/
HEALTHCHECK --interval=10s --timeout=10s --retries=3 CMD /usr/sbin/asterisk -rx "core show sysinfo"

ENTRYPOINT ["/usr/sbin/asterisk","-f","-n","-Uasterisk","-Gdialout"]
# ENTRYPOINT ["/usr/sbin/asterisk","-f","-n"]

CMD ["-v"]
