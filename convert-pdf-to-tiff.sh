#!/bin/bash
#
# convert-pdf-to-tiff.sh
# Converts PDF files to multi-page 8-bit grayscale TIFF files
# compatible with OCR software like ABBYY FineReader.
#
# Output format:
# - 8-bit grayscale
# - LZW compression
# - 300 DPI resolution
# - Multi-page TIFF (all PDF pages in single file)
#
# Requirements: ImageMagick (brew install imagemagick)
#               Ghostscript (brew install ghostscript) - for PDF rendering
#
# Usage: ./convert-pdf-to-tiff.sh <input_directory> [output_directory]
#
# Preserves folder structure from input to output directory.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check for ImageMagick
if ! command -v magick &> /dev/null; then
    echo -e "${RED}Error: ImageMagick is not installed.${NC}"
    echo "Install with: brew install imagemagick"
    exit 1
fi

# Check for Ghostscript (needed for PDF rendering)
if ! command -v gs &> /dev/null; then
    echo -e "${RED}Error: Ghostscript is not installed.${NC}"
    echo "Install with: brew install ghostscript"
    exit 1
fi

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <input_directory> [output_directory]"
    echo ""
    echo "Converts PDF files to multi-page 8-bit grayscale TIFFs for OCR."
    echo ""
    echo "Arguments:"
    echo "  input_directory   Directory containing PDF files to convert"
    echo "  output_directory  (Optional) Output directory for converted files"
    echo "                    Default: <input_directory>_tiffs_converted"
    echo ""
    echo "Output format: 8-bit grayscale, LZW compression, 300 DPI"
    exit 1
fi

INPUT_DIR="$1"
OUTPUT_DIR="${2:-${INPUT_DIR}_tiffs_converted}"

# Validate input directory
if [ ! -d "$INPUT_DIR" ]; then
    echo -e "${RED}Error: Input directory does not exist: $INPUT_DIR${NC}"
    exit 1
fi

# Get absolute paths
INPUT_DIR=$(cd "$INPUT_DIR" && pwd)
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR=$(cd "$OUTPUT_DIR" && pwd)

# Count PDF files first
total=$(find "$INPUT_DIR" -type f -iname "*.pdf" | wc -l | tr -d ' ')

if [ "$total" -eq 0 ]; then
    echo -e "${YELLOW}No PDF files found in $INPUT_DIR${NC}"
    exit 0
fi

echo "=============================================="
echo "PDF to TIFF Converter for OCR"
echo "=============================================="
echo "Input:      $INPUT_DIR"
echo "Output:     $OUTPUT_DIR"
echo "Files:      $total PDFs"
echo "Format:     8-bit grayscale, LZW, 300 DPI"
echo "=============================================="
echo ""

# Convert files - use temp files for counters (subshell workaround)
TMPDIR_STATS=$(mktemp -d)
echo "0" > "$TMPDIR_STATS/count"
echo "0" > "$TMPDIR_STATS/failed"
echo "0" > "$TMPDIR_STATS/skipped"

find "$INPUT_DIR" -type f -iname "*.pdf" -print0 | sort -z | while IFS= read -r -d '' pdf_file; do
    count=$(cat "$TMPDIR_STATS/count")
    count=$((count + 1))
    echo "$count" > "$TMPDIR_STATS/count"

    # Get relative path from input directory
    rel_path="${pdf_file#$INPUT_DIR/}"
    rel_dir=$(dirname "$rel_path")
    filename=$(basename "$pdf_file" .pdf)
    filename="${filename%.PDF}"  # Handle uppercase extension too

    # Create output directory structure
    out_dir="$OUTPUT_DIR/$rel_dir"
    mkdir -p "$out_dir"

    out_file="$out_dir/${filename}.tiff"

    # Skip if already converted
    if [ -f "$out_file" ]; then
        echo -e "[$count/$total] ${YELLOW}SKIP${NC}: $rel_path (already exists)"
        skipped=$(cat "$TMPDIR_STATS/skipped")
        echo "$((skipped + 1))" > "$TMPDIR_STATS/skipped"
        continue
    fi

    echo -ne "[$count/$total] Converting: ${rel_path:0:70}..."

    # Convert PDF to multi-page TIFF
    # -density 300: render at 300 DPI
    # -colorspace Gray: convert to grayscale
    # -depth 8: 8-bit depth
    # -compress lzw: LZW compression
    # -alpha off: remove alpha channel
    if magick -density 300 "$pdf_file" -colorspace Gray -depth 8 -alpha off -compress lzw "$out_file" 2>/dev/null; then
        echo -e "\r[$count/$total] ${GREEN}Done${NC}: ${rel_path:0:70}          "
    else
        echo -e "\r[$count/$total] ${RED}FAILED${NC}: ${rel_path:0:70}          "
        failed=$(cat "$TMPDIR_STATS/failed")
        echo "$((failed + 1))" > "$TMPDIR_STATS/failed"
    fi
done

# Read final counts
count=$(cat "$TMPDIR_STATS/count")
failed=$(cat "$TMPDIR_STATS/failed")
skipped=$(cat "$TMPDIR_STATS/skipped")
rm -rf "$TMPDIR_STATS"

echo ""
echo "=============================================="
echo "Conversion Complete"
echo "=============================================="
converted=$((count - failed - skipped))
echo -e "Converted: ${GREEN}$converted${NC} files"
if [ $skipped -gt 0 ]; then
    echo -e "Skipped:   ${YELLOW}$skipped${NC} files (already exist)"
fi
if [ $failed -gt 0 ]; then
    echo -e "Failed:    ${RED}$failed${NC} files"
fi
echo "Output:    $OUTPUT_DIR"
echo "=============================================="
