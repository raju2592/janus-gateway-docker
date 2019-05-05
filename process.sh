#!/bin/bash
/opt/janus/bin/janus-pp-rec /recording/audio.mjr /files/audio.opus \
&& /opt/janus/bin/janus-pp-rec /recording/video.mjr /files/video.webm \
&& ffmpeg -i /files/audio.opus -i /files/video.webm -c copy /files/output.webm


