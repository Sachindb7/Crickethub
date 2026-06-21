import re
import datetime

with open('index.js', 'r', encoding='utf-8') as f:
    js_content = f.read()

articles = []
for match in re.finditer(r"slug:\s*['\"]([^'\"]+)['\"][\s\S]*?date:\s*['\"]([^'\"]+)['\"]", js_content):
    slug = match.group(1)
    date_str = match.group(2)
    articles.append((slug, date_str))

today = datetime.datetime.utcnow().date()

xml_content = """<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://crickethub.co.in/</loc>
    <priority>1.0</priority>
    <changefreq>daily</changefreq>
  </url>
  <url>
    <loc>https://crickethub.co.in/category/behind-the-scenes/</loc>
    <priority>0.7</priority>
    <changefreq>weekly</changefreq>
  </url>
  <url>
    <loc>https://crickethub.co.in/category/legendary-moments/</loc>
    <priority>0.7</priority>
    <changefreq>weekly</changefreq>
  </url>
  <url>
    <loc>https://crickethub.co.in/category/rise-to-fame/</loc>
    <priority>0.7</priority>
    <changefreq>weekly</changefreq>
  </url>
  <url>
    <loc>https://crickethub.co.in/category/untold-stories/</loc>
    <priority>0.7</priority>
    <changefreq>weekly</changefreq>
  </url>
  <url>
    <loc>https://crickethub.co.in/pages/about</loc>
    <priority>0.5</priority>
    <changefreq>yearly</changefreq>
  </url>
  <url>
    <loc>https://crickethub.co.in/pages/contact</loc>
    <priority>0.5</priority>
    <changefreq>yearly</changefreq>
  </url>
  <url>
    <loc>https://crickethub.co.in/pages/disclaimer</loc>
    <priority>0.3</priority>
    <changefreq>yearly</changefreq>
  </url>
  <url>
    <loc>https://crickethub.co.in/pages/privacy</loc>
    <priority>0.3</priority>
    <changefreq>yearly</changefreq>
  </url>
  <url>
    <loc>https://crickethub.co.in/pages/sitemap-page</loc>
    <priority>0.5</priority>
    <changefreq>weekly</changefreq>
  </url>
  <url>
    <loc>https://crickethub.co.in/pages/terms</loc>
    <priority>0.3</priority>
    <changefreq>yearly</changefreq>
  </url>
"""

# Track unique slugs to avoid duplicates in case of errors
added_slugs = set()

for slug, date_str in articles:
    if slug in added_slugs:
        continue
    try:
        article_date = datetime.datetime.strptime(date_str[:10], "%Y-%m-%d").date()
        if article_date <= today:
            xml_content += f"""  <url>
    <loc>https://crickethub.co.in/articles/{slug}/</loc>
    <lastmod>{date_str}</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>
"""
            added_slugs.add(slug)
    except Exception as e:
        print(f"Error parsing date for {slug}: {e}")

xml_content += "</urlset>\n"

with open('sitemap.xml', 'w', encoding='utf-8') as f:
    f.write(xml_content)

print("sitemap.xml updated successfully!")
