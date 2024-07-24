#!/bin/bash

# Usage message for incorrect invocation
usage() {
    echo "Usage: $0 file [language] [model]"
    echo "  file    : Path to the input file."
    echo "  language: Language option for the main program. Default: english."
    echo "  model   : Model file path for the main program. Default: ./models/ggml-small.bin."
    exit 1
}

# Check if at least one argument (the file) has been passed
if [ $# -lt 1 ]; then
    echo "Error: No file provided."
    usage
fi

# Assigning passed arguments to variables
FILE=$1
LANGUAGE=${2:-english} # Default language is 'english' if not provided
MODEL=${3:-./models/ggml-small.bin} # Default model if not provided

# Validate file existence
if [ ! -f "$FILE" ]; then
    echo "Error: File does not exist."
    exit 1
fi

DIRNAME=$(dirname "$FILE")
BASENAME=$(basename "$FILE")
EXTENSION="${BASENAME##*.}"
FILENAME="${BASENAME%.*}"

# Check if the file extension is not .wav and convert if necessary
if [ "$EXTENSION" != "wav" ]; then
    echo "File is not a .wav file. Converting to .wav..."
    ffmpeg -y -i "$FILE" -ar 16000 -ac 1 -c:a pcm_s16le "${DIRNAME}/${FILENAME}.wav"
    if [ $? -ne 0 ]; then
        echo "Error converting file to .wav."
        exit 1
    fi
    FILE="${DIRNAME}/${FILENAME}.wav"
fi

# Removing existing output files to avoid errors if './main' does not support overwriting
# Adjust the output file extension as necessary
if [ -f "${DIRNAME}/${FILENAME}.output" ]; then
    rm "${DIRNAME}/${FILENAME}.output"
fi

# Running the main program with dynamic parameters
./main -f "$FILE" -m "$MODEL" -l "$LANGUAGE" -otxt -of "${DIRNAME}/${FILENAME}"
if [ $? -ne 0 ]; then
    echo "Error running the main program."
    exit 1
fi

echo "Program executed successfully."
