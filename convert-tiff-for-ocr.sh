#!/bin/bash
#
# convert-tiff-for-ocr.sh
# Converts 16-bit TIFF files with alpha channels to 8-bit grayscale TIFFs
# compatible with OCR software like ABBYY FineReader.
#
# Problem: Some TIFF files have 16-bit depth and/or alpha channels that
# OCR software cannot process, resulting in "image file format is not
# supported" errors.
#
# Solution: This script converts TIFFs to standard 8-bit grayscale with
# LZW compression, which is widely supported by OCR applications.
#
# Requirements: ImageMagick (brew install imagemagick)
#
# Usage: ./convert-tiff-for-ocr.sh <input_directory> [output_directory]
#
# If output_directory is not specified, creates <input_directory>_converted

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for ImageMagick
if ! command -v magick &> /dev/null; then
    echo -e "${RED}Error: ImageMagick is not installed.${NC}"
    echo "Install with: brew install imagemagick"
    exit 1
fi

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <input_directory> [output_directory]"
    echo ""
    echo "Converts 16-bit TIFF files to 8-bit grayscale for OCR compatibility."
    echo ""
    echo "Arguments:"
    echo "  input_directory   Directory containing TIFF files to convert"
    echo "  output_directory  (Optional) Output directory for converted files"
    echo "                    Default: <input_directory>_converted"
    exit 1
fi

INPUT_DIR="$1"
OUTPUT_DIR="${2:-${INPUT_DIR}_converted}"

# Validate input directory
if [ ! -d "$INPUT_DIR" ]; then
    echo -e "${RED}Error: Input directory does not exist: $INPUT_DIR${NC}"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Count TIFF files
shopt -s nullglob nocaseglob
tiff_files=("$INPUT_DIR"/*.tiff "$INPUT_DIR"/*.tif)
shopt -u nullglob nocaseglob

total=${#tiff_files[@]}

if [ $total -eq 0 ]; then
    echo -e "${YELLOW}No TIFF files found in $INPUT_DIR${NC}"
    exit 0
fi

echo "=============================================="
echo "TIFF Converter for OCR"
echo "=============================================="
echo "Input:  $INPUT_DIR"
echo "Output: $OUTPUT_DIR"
echo "Files:  $total"
echo "=============================================="
echo ""

# Convert files
count=0
failed=0

for f in "${tiff_files[@]}"; do
    count=$((count + 1))
    filename=$(basename "$f")

    echo -ne "\r[$count/$total] Converting: ${filename:0:60}..."

    if magick "$f" -alpha off -depth 8 -compress lzw "$OUTPUT_DIR/$filename" 2>/dev/null; then
        echo -ne "\r[$count/$total] ${GREEN}Done${NC}: ${filename:0:60}     \n"
    else
        echo -ne "\r[$count/$total] ${RED}FAILED${NC}: ${filename:0:60}     \n"
        failed=$((failed + 1))
    fi
done

echo ""
echo "=============================================="
echo "Conversion Complete"
echo "=============================================="
echo -e "Converted: ${GREEN}$((count - failed))${NC} files"
if [ $failed -gt 0 ]; then
    echo -e "Failed:    ${RED}$failed${NC} files"
fi
echo "Output:    $OUTPUT_DIR"
echo "=============================================="

# Show before/after comparison for first file
if [ $((count - failed)) -gt 0 ]; then
    echo ""
    echo "Sample conversion result:"
    first_output=$(ls "$OUTPUT_DIR"/*.tif* 2>/dev/null | head -1)
    if [ -n "$first_output" ]; then
        tiffinfo "$first_output" 2>&1 | grep -E "(Bits/Sample|Samples/Pixel|Compression)" | head -3
    fi
fi
