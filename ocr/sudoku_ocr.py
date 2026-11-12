import base64
import mimetypes
import re
import sys

import openai

# This relies on OPENAI_API_KEY and OPENAI_BASE_URL
#
# Reads a Sudoku puzzle from an image and prints it as 81 digits in
# row-major order, with 0 for blank cells.
#
#   uv run sudoku_ocr.py test-data/globe-sudoku-2026-11-12.jpg

MODEL = "gpt-5.5"

PROMPT = (
    "This image contains a 9x9 Sudoku puzzle. Read it row by row, top to bottom, "
    "left to right. Output exactly 81 digits with no spaces or other text, "
    "using 0 for each empty cell."
)

def read_sudoku(client, image_path):
    """Return the puzzle in image_path as an 81-character digit string."""
    mime_type = mimetypes.guess_type(image_path)[0] or "image/png"
    with open(image_path, "rb") as f:
        data = base64.b64encode(f.read()).decode()
    response = client.responses.create(
        model=MODEL,
        input=[
            {
                "role": "user",
                "content": [
                    {"type": "input_text", "text": PROMPT},
                    {"type": "input_image", "image_url": f"data:{mime_type};base64,{data}"},
                ],
            }
        ],
    )
    digits = re.sub(r"\D", "", response.output_text)
    if len(digits) != 81:
        raise ValueError(f"Expected 81 digits, got {len(digits)}: {response.output_text!r}")
    return digits

if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: sudoku_ocr.py <image>")
    print(read_sudoku(openai.OpenAI(), sys.argv[1]))
