# convert a PDF to Markdown using lbl/cborg-ocr model
# requires pdf2image and PIL

import os
from pdf2image import convert_from_path
from PIL import Image
import io
import base64

def encode_pil_image(pil_image):
    """Convert PIL Image to base64 encoding"""
    # Create a bytes buffer
    buffered = io.BytesIO()

    print("PIL", pil_image)

    # Save the image to the buffer in PNG format
    pil_image.save(buffered, format="PNG")

    # Get the byte data and encode it in base64
    img_str = base64.b64encode(buffered.getvalue()).decode('utf-8')

    #print('encoded', img_str)

    return img_str

def write_image_to_file(pil_image, path):
    """
    Save a PIL Image to the specified file path.

    Parameters
    ----------
    pil_image : PIL.Image.Image
        The image to write.
    path : str
        Destination file path where the image will be saved.
    """
    # Ensure the output directory exists
    directory = os.path.dirname(path)
    if directory and not os.path.isdir(directory):
        os.makedirs(directory, exist_ok=True)

    # Save the image; Pillow will infer the format from the file extension
    pil_image.save(path)

def pdf_to_images(pdf_path):
    try:

        # Convert PDF to images
        # Setting use_pdftocairo=True is generally faster than using poppler directly
        images = convert_from_path(
            pdf_path,
            dpi=400,  # Adjust DPI as needed for quality/size trade-off
            use_pdftocairo=True,
            strict=False
        )
        
        # images is now a list of PIL Image objects
        # You can work with them directly in memory
        return images
         
    except Exception as e:
        print(f"Error converting PDF: {str(e)}")
        return None

def image_to_markdown(image):

    # The following is the recommended prompt for Nanonets-OCR-s model

    prompt = """Extract the text from the above document as if you were reading it naturally. 
Return the tables in html format. 
Return the equations in LaTeX representation. 
If there is an image in the document and image caption is not present, add a small description of the image inside the <img></img> tag; otherwise, add the image caption inside <img></img>. 
Watermarks should be wrapped in brackets. Ex: <watermark>OFFICIAL COPY</watermark>. 
Page numbers should be wrapped in brackets. Ex: <page_number>14</page_number> or <page_number>9/22</page_number>. 
Prefer using ☐ and ☑ for check boxes.
"""

    print("Processing...")

    max_retry = 10
    n = 0

    try:
        response = client.chat.completions.create(
            model="lbl/cborg-ocr",
            messages = [
                {
                "role": "user",
                "content": [
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": "data:image/png;base64," + encode_pil_image(image)
                        }
                    },
                    {
                        "type": "text",
                        "text": prompt
                    }
                ]
                }
            ],
            temperature=0.0,
            stream=False
        )
    except Exception as e:
        print("ERROR:", e)
        n += 1
        if n >= max_retry:
            raise e
        else:
            time.sleep(n*5)
            pass

    print(response.choices[0].message.content)
    return response.choices[0].message.content

if __name__ == '__main__':
    # Example usage:
    import sys
    pdf_path = sys.argv[1]

    image_list = pdf_to_images(pdf_path)

    # for debugging, you can write the images out to disk and check them
    #for idx, image in enumerate(image_list):
    #    write_image_to_file(image, f'./img/{idx}.png')

    import openai
    import base64
    import time

    client = openai.OpenAI(
        api_key=os.environ.get('CBORG_API_KEY'),
        base_url='https://api.cborg.lbl.gov'
    )

    start = time.time()


from concurrent.futures import ThreadPoolExecutor

def process_image(i):
    return image_to_markdown(i)

markdown = []

with ThreadPoolExecutor(max_workers=1) as executor:
    # Map the process_image function to each item in image_list
    results = list(executor.map(process_image, image_list))

# Concatenate all results into markdown
markdown = ''.join(results)

with open(pdf_path + ".md", "w") as fp:
    fp.write(markdown)

