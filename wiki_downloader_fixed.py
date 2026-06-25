import os
import sys
import requests
import time

def download_images(query, folder_path, num_images):
    print(f"Searching Wikipedia for: {query}")
    os.makedirs(folder_path, exist_ok=True)
    
    headers = {
        'User-Agent': 'CricketHubBot/1.0 (contact@crickethub.co.in)'
    }
    
    # 1. Search for pages matching the query
    search_url = "https://en.wikipedia.org/w/api.php"
    search_params = {
        "action": "query",
        "format": "json",
        "list": "search",
        "srsearch": query,
        "utf8": 1,
        "srlimit": 3
    }
    
    try:
        res = requests.get(search_url, params=search_params, headers=headers).json()
        if not res.get("query", {}).get("search"):
            print("No pages found.")
            return
            
        page_titles = [item["title"] for item in res["query"]["search"]]
        
        # 2. Get images for those pages
        image_titles = []
        for title in page_titles:
            img_params = {
                "action": "query",
                "format": "json",
                "prop": "images",
                "titles": title,
                "imlimit": 20
            }
            img_res = requests.get(search_url, params=img_params, headers=headers).json()
            pages = img_res.get("query", {}).get("pages", {})
            for page_id, page_data in pages.items():
                if "images" in page_data:
                    for img in page_data["images"]:
                        img_title = img["title"]
                        # Filter out SVG and tiny icons
                        if img_title.lower().endswith(('.jpg', '.png', '.jpeg')) and 'icon' not in img_title.lower() and 'logo' not in img_title.lower():
                            if img_title not in image_titles:
                                image_titles.append(img_title)
                            
        # 3. Get image URLs
        count = 0
        for img_title in image_titles:
            if count >= num_images:
                break
                
            info_params = {
                "action": "query",
                "format": "json",
                "prop": "imageinfo",
                "titles": img_title,
                "iiprop": "url"
            }
            info_res = requests.get(search_url, params=info_params, headers=headers).json()
            pages = info_res.get("query", {}).get("pages", {})
            
            for page_id, page_data in pages.items():
                if "imageinfo" in page_data:
                    img_url = page_data["imageinfo"][0]["url"]
                    print(f"Downloading: {img_url}")
                    
                    try:
                        img_data = requests.get(img_url, headers=headers, timeout=15)
                        if img_data.status_code == 200:
                            ext = ".jpg" if img_url.lower().endswith(('.jpg', '.jpeg')) else ".png"
                            filename = "featured" if count == 0 else f"img-{count}"
                            
                            file_path = os.path.join(folder_path, f"{filename}{ext}")
                            with open(file_path, 'wb') as f:
                                f.write(img_data.content)
                            print(f"Saved: {file_path}")
                            count += 1
                            time.sleep(1)
                    except Exception as e:
                        print(f"Failed to download {img_url}: {e}")
                        
        if count == 0:
            print("No images downloaded.")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(1)
    title = sys.argv[1]
    folder = sys.argv[2]
    num = int(sys.argv[3]) if len(sys.argv) > 3 else 3
    download_images(title, folder, num)
