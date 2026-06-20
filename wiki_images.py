import os
import sys
import requests
import time

def download_wiki_images(query, folder_path, num_images=3):
    print(f"Searching Wikipedia for: {query}")
    os.makedirs(folder_path, exist_ok=True)
    
    # Use MediaWiki API to search for images on Wikimedia Commons
    search_url = "https://commons.wikimedia.org/w/api.php"
    params = {
        "action": "query",
        "format": "json",
        "generator": "search",
        "gsrsearch": query,
        "gsrlimit": num_images * 2,
        "prop": "imageinfo",
        "iiprop": "url"
    }
    
    headers = {
        "User-Agent": "CricketHubBot/1.0 (contact@crickethub.co.in)"
    }
    
    try:
        res = requests.get(search_url, params=params, headers=headers)
        data = res.json()
        pages = data.get("query", {}).get("pages", {})
        
        count = 0
        for page_id, page_info in pages.items():
            if count >= num_images:
                break
                
            image_info = page_info.get("imageinfo", [])
            if not image_info:
                continue
                
            img_url = image_info[0].get("url")
            if not img_url:
                continue
                
            print(f"Downloading: {img_url}")
            try:
                img_res = requests.get(img_url, headers=headers, timeout=15)
                if img_res.status_code == 200:
                    ext = ".jpg"
                    if ".png" in img_url.lower(): ext = ".png"
                    
                    filename = "featured" if count == 0 else f"img-{count}"
                    file_path = os.path.join(folder_path, f"{filename}{ext}")
                    
                    with open(file_path, 'wb') as f:
                        f.write(img_res.content)
                    print(f"Saved: {file_path}")
                    count += 1
                    time.sleep(1)
            except Exception as e:
                print(f"Failed to download {img_url}: {e}")
                
        if count == 0:
            print("No images found or downloaded.")
    except Exception as e:
        print(f"API Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(1)
    query = sys.argv[1]
    folder = sys.argv[2]
    num = int(sys.argv[3]) if len(sys.argv) > 3 else 3
    download_wiki_images(query, folder, num)
