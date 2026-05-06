#!/bin/bash
# --------------------------------------------------------

DLIB_DETECTOR_PATH=sign_language_translation/ssvp_slt/examples/sonar/mmod_human_face_detector.dat

if [ -z $DLIB_DETECTOR_PATH ]; then
    echo "Please provide a local path to the appropriate face detector model."
    exit 1
fi

DOWNLOAD_CACHE=$HOME/.cache/asl
BASE_URL=https://dl.fbaipublicfiles.com/SONAR/asl

if [ ! -d $DOWNLOAD_CACHE ]; then mkdir -p $DOWNLOAD_CACHE; fi

function download {
    file_name=$1
    if [ -f ${DOWNLOAD_CACHE}/${file_name} ] ; then
       :;
    else
        echo " - Downloading ${file_name}";
        wget -q $BASE_URL/${file_name} -P $DOWNLOAD_CACHE;
    fi
}

# Download model weights
FEATURE_EXTRACTOR=dm_70h_ub_signhiera.pth
download $FEATURE_EXTRACTOR

SONAR_ENCODER=dm_70h_ub_sonar_encoder.pth
download $SONAR_ENCODER

# Select target languages from FLORES200 (https://github.com/facebookresearch/flores/blob/main/flores200/README.md)
TGT_LANGS='[eng_Latn]'

# Use provided video paths as arguments, or fall back to sample video
if [ $# -eq 0 ]; then
    SAMPLE_VIDEO=0043626-2023.1.4.mp4
    download $SAMPLE_VIDEO
    VIDEO_PATHS="[$DOWNLOAD_CACHE/$SAMPLE_VIDEO]"
else
    # Build a hydra list from all arguments: [path1,path2,...]
    VIDEO_LIST=$(printf ",%s" "$@")
    VIDEO_PATHS="[${VIDEO_LIST:1}]"
fi

python sign_language_translation/ssvp_slt/examples/sonar/run.py \
    "video_paths=$VIDEO_PATHS" \
    preprocessing.detector_path=$DLIB_DETECTOR_PATH \
    feature_extraction.pretrained_model_path=$DOWNLOAD_CACHE/$FEATURE_EXTRACTOR \
    translation.pretrained_model_path=$DOWNLOAD_CACHE/$SONAR_ENCODER \
    translation.tgt_langs="$TGT_LANGS"
