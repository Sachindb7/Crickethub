import wikipedia
import os
import sys
import requests
import time

def download_images(page_title, folder_path, num_images):
    print(f"Searching Wikipedia for: {page_title}")
    os.makedirs(folder_path, exist_ok=True)
    
    try:
        page = wikipedia.page(page_title)
        images = [img for img in page.images if img.endswith('.jpg') or img.endswith('.png')]
        
        count = 0
        for img_url in images:
            if count >= num_images:
                break
                
            print(f"Downloading: {img_url}")
            try:
                res = requests.get(img_url, timeout=15)
                if res.status_code == 200:
                    ext = ".jpg" if img_url.endswith('.jpg') else ".png"
                    filename = "featured" if count == 0 else f"img-{count}"
                    
                    file_path = os.path.join(folder_path, f"{filename}{ext}")
                    with open(file_path, 'wb') as f:
                        f.write(res.content)
                    print(f"Saved: {file_path}")
                    count += 1
                    time.sleep(1)
            except Exception as e:
                print(f"Failed to download {img_url}: {e}")
                
        if count == 0:
            print("No images downloaded.")
    except Exception as e:
        print(f"Error fetching page: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(1)
    title = sys.argv[1]
    folder = sys.argv[2]
    num = int(sys.argv[3]) if len(sys.argv) > 3 else 3
    download_images(title, folder, num)
