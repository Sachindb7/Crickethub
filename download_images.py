import os
import sys
import requests
from duckduckgo_search import DDGS
from urllib.parse import urlparse
import time

def download_images(query, folder_path, num_images=3):
    print(f"Searching images for: {query}")
    os.makedirs(folder_path, exist_ok=True)
    
    with DDGS() as ddgs:
        results = list(ddgs.images(query, max_results=10))
    
    count = 0
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }

    for i, res in enumerate(results):
        if count >= num_images:
            break
            
        img_url = res.get('image')
        if not img_url:
            continue
            
        try:
            print(f"Downloading: {img_url}")
            response = requests.get(img_url, headers=headers, timeout=10)
            if response.status_code == 200:
                # determine extension
                ext = ".jpg"
                if ".png" in img_url.lower(): ext = ".png"
                elif ".webp" in img_url.lower(): ext = ".webp"
                
                filename = "featured" if count == 0 else f"img-{count}"
                file_path = os.path.join(folder_path, f"{filename}{ext}")
                
                with open(file_path, 'wb') as f:
                    f.write(response.content)
                print(f"Saved: {file_path}")
                count += 1
                time.sleep(1) # be nice
        except Exception as e:
            print(f"Failed to download {img_url}: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python download_images.py 'search query' 'folder_path' [num_images]")
        sys.exit(1)
        
    query = sys.argv[1]
    folder = sys.argv[2]
    num = int(sys.argv[3]) if len(sys.argv) > 3 else 3
    
    download_images(query, folder, num)
