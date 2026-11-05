#!/bin/sh
# Builds shaders2.zip with the `shaders` folder at the archive root (what Iris/OptiFine expect)
cd "$(dirname "$0")" && rm -f shaders2.zip && zip -r -q shaders2.zip shaders && echo "built shaders2.zip"
