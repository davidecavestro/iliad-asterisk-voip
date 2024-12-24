#!/bin/bash

# Configurable variables
SOUNDS_DIR="/var/lib/asterisk/sounds"
DEFAULT_LANG="it"
DEFAULT_VOICE="nanotts:it-IT"

# Input arguments
TEXT="$1"
LANG="${2:-$DEFAULT_LANG}"   # Use provided language or default
VOICE="${3:-$DEFAULT_VOICE}" # Use provided voice or default

# Generate a unique hash for the text
DIGEST=$(echo -n "${TEXT}-${LANG}-${VOICE}" | md5sum | awk '{print $1}')
TTS_SOUND="tts-${LANG}-${VOICE}-${DIGEST}"
TTS_FILE="${SOUNDS_DIR}/${TTS_SOUND}.wav"

# Check if file exists
if [[ ! -f "${TTS_FILE}" ]]; then
  curl -s "http://0.0.0.0:5500/api/tts" -G \
    --data-urlencode "voice=${VOICE}"\
    --data-urlencode "lang=${LANG}" \
    --data-urlencode "text=${TEXT}" \
    -o - | sox -t wav - -r 8000 "${TTS_FILE}"

  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to generate TTS file" >&2
    exit 1
  fi
fi

# Output the generated or cached file name without path and extension
echo "${TTS_SOUND}"
