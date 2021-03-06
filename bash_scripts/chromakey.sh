#!/usr/bin/env bash

# Combine two files using a chromakey effects

_usage(){
cat <<EOF
$(basename "${0}")
  Usage
   $(basename "${0}") [OPTIONS] OVERLAY_FILE BACKGROUND_FILE KEY SIM BLEND
  Options
   -h  display this help
   -p  previews in FFplay
   -s  saves to file with FFmpeg

  Notes
  Colorkey value [default: 0000FF]
  Colorkey similarity value [default: 0.6]. Between 0.01 and 1.
    The closer to 1 more tolerance
  Colorkey blend value [default: 0.1]

  Outcome
   Combine two files using a chromakey effects
   dependencies: ffmpeg 4.3 or later
EOF
}

function filter_complex()
{
  local key="${1:-00FF00}"    # Colorkey colour - default vaue is 0000FF or green
  local colorSim="${2:-0.2}"    # Colorkey similarity level - default value is 0.2
  local colorBlend="${3:-0.1}"  # Colorkey blending level - default value is 0.1

   # Update color variable according to user input
   # This makes the matching case insensitive
  if [[ $1 =~ ^[0-9A-F]{6}$ ]]
  then
    key=$1
elif [[ $(tr "[:upper:]" "[:lower:]" <<<"$1")  = "blue" ]]
  then
    key="0000FF"
elif [[ $(tr "[:upper:]" "[:lower:]" <<<"$1")  = "green" ]]
  then
    key="00FF00"
elif [[ $(tr "[:upper:]" "[:lower:]" <<<"$1")  = "red" ]]
  then
    key="FF0000"
elif [[ $(tr "[:upper:]" "[:lower:]" <<<"$1")  = "purple" ]]
  then
    key="0000FF"
elif [[ $(tr "[:upper:]" "[:lower:]" <<<"$1")  = "orange" ]]
  then
    key="ff9900"
elif [[ $(tr "[:upper:]" "[:lower:]" <<<"$1")  = "yellow" ]]
  then
    key="FFFF00"
  fi

  # Build filter string
filterString="[1:v][0:v]scale2ref[v1][v0];[v1]chromakey=0x$key:$colorSim:$colorBlend[1v];[v0][1v]overlay,format=yuv422p10le[v]"

  # Return full filter string, with necessary prefix and suffix filterchains
  printf '%s%s%s' $filterString
}

while getopts "hps" OPT ; do
    case "${OPT}" in
      h) _usage ; exit 0
        ;;
      p)
      ffmpeg -hide_banner -i "${3}" -i "${2}" -c:v prores -filter_complex "$(filter_complex "${@:4}")" -map '[v]' -f matroska - | ffplay -
      printf "\n\n*******START FFPLAY COMMANDS*******\n" >&2
      printf "ffmpeg -hide_banner -i '$3' -i '$2' -c:v prores -filter_complex $(filter_complex ${@:4}) -map '[v]' -f matroska - | ffplay - \n" >&2
      printf "********END FFPLAY COMMANDS********\n\n " >&2
        ;;
      s)
      ffmpeg -hide_banner -i "${3}" -i "${2}" -c:v prores -profile:v 3 -filter_complex "$(filter_complex "${@:4}")" -map '[v]' "${2%.*}_chromakey.mov"
      printf "\n\n*******START FFMPEG COMMANDS*******\n" >&2
      printf "ffmpeg -hide_banner -i '$3' -i '$2' -c:v prores -filter_complex $(filter_complex ${@:4}) -map '[v]' -f matroska - | ffplay - \n" >&2
      printf "********END FFMPEG COMMANDS********\n\n " >&2
        ;;
      *) echo "bad option -${OPTARG}" ; _usage ; exit 1 ;
    esac
  done
