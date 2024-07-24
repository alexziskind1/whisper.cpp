#!/bin/bash

# Usage message for incorrect invocation
usage() {
    echo "Usage: $0 directory [language] [model]"
    echo "  directory: Path to the directory containing MP4 files."
    echo "  language : Language option for the main program. Default: english."
    echo "  model    : Model file path for the main program. Default: ./models/ggml-small.bin."
    exit 1
}

# Check if at least one argument (the directory) has been passed
if [ $# -lt 1 ]; then
    echo "Error: No directory provided."
    usage
fi

# Assigning passed arguments to variables
DIRECTORY=$1
LANGUAGE=${2:-english} # Default language is 'english' if not provided
MODEL=${3:-./models/ggml-small.bin} # Default model if not provided

# Validate directory existence
if [ ! -d "$DIRECTORY" ]; then
    echo "Error: Directory does not exist."
    exit 1
fi

# Loop through all MP4 files in the directory
for FILE in "${DIRECTORY}"/*.mp4; do
    if [ ! -f "$FILE" ]; then
        continue # Skip if no files are found
    fi

    DIRNAME=$(dirname "$FILE")
    BASENAME=$(basename "$FILE")
    EXTENSION="${BASENAME##*.}"
    FILENAME="${BASENAME%.*}"

    # Convert MP4 to WAV format
    echo "Converting $FILE to .wav..."
    ffmpeg -y -i "$FILE" -ar 16000 -ac 1 -c:a pcm_s16le "${DIRNAME}/${FILENAME}.wav"
    if [ $? -ne 0 ]; then
        echo "Error converting file to .wav."
        continue # Skip this file on error
    fi

    WAV_FILE="${DIRNAME}/${FILENAME}.wav"

    # Removing existing output files to avoid errors if './main' does not support overwriting
    if [ -f "${DIRNAME}/${FILENAME}.output" ]; then
        rm "${DIRNAME}/${FILENAME}.output"
    fi

    # Running the main program with dynamic parameters
    echo "Transcribing ${FILENAME}.wav..."
    ./main -f "$WAV_FILE" -m "$MODEL" -l "$LANGUAGE" -otxt -of "${DIRNAME}/${FILENAME}"
    if [ $? -ne 0 ]; then
        echo "Error running the main program on ${FILENAME}.wav."
        continue # Skip this file on error
    fi

    echo "Transcription of ${FILENAME}.wav completed successfully."
done

echo "All applicable files have been processed."
