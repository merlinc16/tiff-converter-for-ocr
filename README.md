# TIFF Converter for OCR

Converts 16-bit TIFF files with alpha channels to 8-bit grayscale TIFFs compatible with OCR software like ABBYY FineReader.

## The Problem

Some TIFF files (especially those processed by certain image repair tools) have:
- **16-bit depth** instead of standard 8-bit
- **Alpha channels** (transparency layer)

These formats are not supported by many OCR applications, resulting in errors like:
```
Error: The image file format has not been recognized
Error: This image file format is not supported
```

## The Solution

This script converts TIFFs to standard **8-bit grayscale with LZW compression**, which is widely supported by OCR applications including:
- ABBYY FineReader
- Adobe Acrobat
- Tesseract OCR
- And most other OCR tools

## Requirements

- **macOS** or **Linux**
- **ImageMagick** - Install with:
  ```bash
  # macOS
  brew install imagemagick

  # Ubuntu/Debian
  sudo apt install imagemagick
  ```

## Installation

```bash
git clone https://github.com/merlinc16/tiff-converter-for-ocr.git
cd tiff-converter-for-ocr
chmod +x convert-tiff-for-ocr.sh
```

## Usage

```bash
# Basic usage - creates output in <input_dir>_converted
./convert-tiff-for-ocr.sh /path/to/tiff/files

# Specify custom output directory
./convert-tiff-for-ocr.sh /path/to/input /path/to/output
```

## Example

```bash
$ ./convert-tiff-for-ocr.sh ./scanned_documents

==============================================
TIFF Converter for OCR
==============================================
Input:  ./scanned_documents
Output: ./scanned_documents_converted
Files:  642
==============================================

[1/642] Done: document_001.tiff
[2/642] Done: document_002.tiff
...

==============================================
Conversion Complete
==============================================
Converted: 642 files
Failed:    0 files
Output:    ./scanned_documents_converted
==============================================
```

## What It Does

| Property | Before | After |
|----------|--------|-------|
| Bit depth | 16-bit | 8-bit |
| Channels | 2 (gray + alpha) | 1 (grayscale) |
| Compression | Various | LZW |
| Multi-page | Preserved | Preserved |
| Resolution | Preserved | Preserved |

## Troubleshooting

### "._" files causing errors
If you see errors about `._` files on Windows, these are macOS metadata files. Delete them with:
```cmd
del /s C:\your\folder\._*
```

### ImageMagick not found
Make sure ImageMagick is installed and in your PATH:
```bash
which magick
# Should return: /opt/homebrew/bin/magick or similar
```

## License

MIT License - Use freely for any purpose.
