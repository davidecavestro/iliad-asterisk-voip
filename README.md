# iliad-asterisk-voip

A container image based on [asterisk](https://github.com/asterisk/asterisk) and [opentts](https://github.com/synesthesiam/opentts) preconfigured to automate VOIP calls from Iliad FTTH.


## Project status

Please note this project is in alpha state.

At the moment the following features are available:
- registration to Iliad VOIP provider
- starting outbound calls from callfiles
- starting outbound calls from Asterisk REST api
- using TTS on outbound calls

Next steps:
- review for security the generated config and image
- optimize the generated image - just include used stuff
- optimize the generated image - as of now it uses many layers for ease of debugging, but wastes a lot of space
- publish the optimised image
- test support for incoming calls


## Project contents

| File/Folder | Description |
| --- | --- |
| `compose_build.yml` | a docker compose file for building the image |
| `compose_cfg.yml` | a docker compose file for generating the config from templates |
| `compose_tts.yml` | a docker compose file for enabling TTS |
| `compose.yml` | the main docker compose file |
| `config` | a dir bind mounted hosting actual config generated from templates |
| `Dockerfile` | a Dockerfile for building the asterisk image |
| `Dockerfile_cfg` | a Dockerfile for building image to generate config from templates |
| `generate_tts.sh` | a script bind mounted for text-to-speech |
| `inject_cfg` | a script for injecting config in the container |
| `LICENSE` | a markdown file with the license |

## Example usage

Currently the project has been tested just to dial mobile phones to provide an automatically generated messsage at answer.
In order to place calls:
- prepare the env vars
- build the images
- start containers


### Prepare the env vars

```.env
# filename: .env_cfg

# Iliad VOIP phone number
SECRET_PHONE_NUMBER=***********
# Iliad VOIP password
SECRET_PASSWORD=*********
SECRET_PHONE_NAME=Casa
SECRET_CALLME_NUMBER=********
SECRET_ARI_ALLOWED_ORIGINS=0.0.0.0:8088
# Asterisk REST api username
SECRET_ARI_USERNAME=asterisk
# Asterisk REST api password
SECRET_ARI_PASSWORD=*******
```


### Build the container images

Build the asterisk image along with the one for injecting env vars into config templates 

```bash
docker compose \
  -f compose.yml \
  -f compose_build.yml \
  -f compose_cfg.yml \
  build
```

### Start the containers

Launch the container mounting the profile folder and the directory where
you want to download your stuff

```bash
docker compose \
  -f compose.yml \
  -f compose_cfg.yml \
  -f compose_tts.yml \
  up
```

### Initiate an outgoing call from ARI REST api (use TTS)

This command is used to initiate an outgoing call to _callee_number_ using the Asterisk REST api.
In order to use it you have to replace the variables denoted by square brackets with your own values.

```bash
curl -u [ari_usrname]:[ari_password] \
  -X POST "http://0.0.0.0:8088/ari/channels" \
  -H "Content-Type: application/json" \
  -d '{
        "endpoint": "PJSIP/[callee_number]@Iliad",
        "extension": "s",
        "context": "ttsme",
        "callerId": "Casa <[caller_number]>",
        "priority": 1,
        "variables": {
          "TTS_STRING": "This is an automatically generated alarm message"
        }
      }'
```


### Initiate an outgoing call from .call file (use TTS)

In order to initiate an outgoing call to _callee_number_ using the .call file
you have to replace the variables denoted by square brackets with your own values.

When the file is ok, copy it into the dir bind mounted in the container,
then move into the spool directory

```bash
cp .call-tts spool/.call && mv spool/.call spool/outgoing/.call
```

#### Using TTS

```.call
# filename: .call-tts
Channel: PJSIP/[callee_number]@Iliad
CallerID: "Casa" <[caller_number]>
Context: ttsme
Extension: s
Priority: 1
MaxRetries: 1
RetryTime: 60
WaitTime: 30
SetVar: TTS_TEXT=This is an automatically generated alarm message
```

#### Using a sound

```.call .call-sound
# filename: .call-sound
Channel: PJSIP/[callee_number]@Iliad
CallerID: "Casa" <[caller_number]>
Application: Playback
Data: hello-world
Extension: s
Priority: 1
MaxRetries: 1
RetryTime: 60
WaitTime: 30
```

## Image project home

https://github.com/davidecavestro/iliad-asterisk-voip


## Credits

Most of the config comes from info [shared on](https://forum.fibra.click/d/48277-voip-fibra-iliad-su-asterisk-con-freepbx/21) fibraclick forum.

The Dockerfile is inspired by [docker-asterisk-rpi](https://github.com/aivus/docker-asterisk-rpi) 
