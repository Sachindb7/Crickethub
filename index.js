/* ============================================================
   CricketHub — Main JavaScript
   Handles: navbar, animations, article loading, newsletter
   ============================================================ */

// ---- Cookie Consent ----
if (!localStorage.getItem('cookiesAccepted')) {
    document.getElementById('cookieBanner').style.display = 'flex';
}
function acceptCookies() {
    localStorage.setItem('cookiesAccepted', 'true');
    document.getElementById('cookieBanner').style.display = 'none';
}

// ---- Navbar Scroll Effect ----
const navbar = document.getElementById('navbar');
window.addEventListener('scroll', () => {
    if (navbar) navbar.classList.toggle('scrolled', window.scrollY > 50);
});

// ---- Mobile Nav Toggle ----
const navToggle = document.getElementById('navToggle');
const navLinks = document.getElementById('navLinks');
if (navToggle) {
    navToggle.addEventListener('click', function () {
        this.classList.toggle('active');
        navLinks.classList.toggle('open');
    });
    // Close nav on link click (mobile)
    navLinks.querySelectorAll('a').forEach(link => {
        link.addEventListener('click', () => {
            navToggle.classList.remove('active');
            navLinks.classList.remove('open');
        });
    });
}

// ---- Scroll Fade-In Animations ----
const observerOptions = { threshold: 0.1, rootMargin: '0px 0px -40px 0px' };
const fadeObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.classList.add('visible');
            fadeObserver.unobserve(entry.target);
        }
    });
}, observerOptions);

document.querySelectorAll('.fade-in').forEach(el => fadeObserver.observe(el));

// ---- Article Data & Rendering ----
// Articles are stored as a JSON array. When you add a new article via the admin panel,
// you add its metadata here. The homepage reads from this array.
const ARTICLES = [
    {
        title: "The Slow Death of ODI Cricket: Why 50-Over Matches Are Disappearing Forever",
        slug: "slow-death-of-odi-cricket-50-overs-disappearing",
        date: "2026-06-27T10:00:00Z",
        category: "Untold Stories",
        categorySlug: "untold-stories",
        excerpt: "Between the explosion of T20 leagues and the prestige of Test cricket, the 50-over format is dying a slow, quiet death. Here is why ODI cricket is fading away.",
        image: "/articles/slow-death-of-odi-cricket-50-overs-disappearing/featured.avif"
    },
    {
        title: "Why Umpiring is the Most Thankless Job in Cricket",
        slug: "why-umpiring-most-thankless-job-in-cricket",
        date: "2026-06-26T10:00:00Z",
        category: "Behind the Scenes",
        categorySlug: "behind-the-scenes",
        excerpt: "One mistake and the world hates you. Technology exposes every error. The psychological toll of being a cricket umpire in the modern era.",
        image: "/articles/why-umpiring-most-thankless-job-in-cricket/featured.jpg"
    },
    {
        title: "The 175 That Changed Cricket: When Kapil Dev Saved India",
        slug: "175-that-changed-cricket-kapil-dev-1983",
        date: "2026-06-25T10:00:00Z",
        category: "Legendary Moments",
        categorySlug: "legendary-moments",
        excerpt: "In 1983, India was 17/5 against Zimbabwe. Kapil Dev walked in and scored 175*. But there is no video footage of the greatest innings in Indian cricket history.",
        image: "/articles/175-that-changed-cricket-kapil-dev-1983/featured.jpg"
    },
    {
        title: "The ₹1 Lakh Bat: What Actually Goes Into Making an International Cricket Bat?",
        slug: "cost-of-making-international-cricket-bat",
        date: "2026-06-24T10:00:00Z",
        category: "Behind the Scenes",
        categorySlug: "behind-the-scenes",
        excerpt: "Why do international cricket bats cost over ₹1,000,000? From English Willow grades to custom sweet spots, the secret science of bat making.",
        image: "/articles/cost-of-making-international-cricket-bat/featured.png"
    },
    {
        title: "The Loneliest Job in Cricket: What It Actually Feels Like to Be the 12th Man",
        slug: "loneliest-job-in-cricket-12th-man-reality",
        date: "2026-06-23T10:00:00Z",
        category: "Untold Stories",
        categorySlug: "untold-stories",
        excerpt: "Carrying drinks, mixing energy powders, and watching others live your dream. The psychological reality of being a reserve player in the Indian cricket team.",
        image: "/articles/loneliest-job-in-cricket-12th-man-reality/featured.jpg"
    },
    {
        title: "Smriti Mandhana: Why She Is The Most Elegant Batter in World Cricket Right Now",
        slug: "smriti-mandhana-most-elegant-batter-world-cricket",
        date: "2026-06-22T10:00:00Z",
        category: "Rise to Fame",
        categorySlug: "rise-to-fame",
        excerpt: "There is batting, and then there is art. Why Smriti Mandhana's cover drive is the most aesthetically pleasing shot in modern cricket, male or female.",
        image: "/articles/smriti-mandhana-most-elegant-batter-world-cricket/featured.jpg"
    },
    {
        title: "Why Left-Arm Pacers Always Destroy India's Top Order",
        slug: "why-left-arm-pacers-destroy-india-top-order",
        date: "2026-06-21T10:00:00Z",
        category: "Behind the Scenes",
        categorySlug: "behind-the-scenes",
        excerpt: "From Trent Boult to Shaheen Afridi to Mitchell Starc, left-arm fast bowlers have been India's kryptonite for a decade. What's the technical reason behind this collapse?",
        image: "/articles/why-left-arm-pacers-destroy-india-top-order/featured.webp"
    },
    {
        title: "The 2019 World Cup Heartbreak: The Rule That Cost India The Cup",
        slug: "the-2019-world-cup-heartbreak-rule-cost-india-the-cup",
        date: "2026-06-20T10:00:00Z",
        category: "Untold Stories",
        categorySlug: "untold-stories",
        excerpt: "MS Dhoni's run out broke a billion hearts, but the 2019 World Cup semi-final was lost due to a controversial rule nobody talks about anymore.",
        image: "/articles/the-2019-world-cup-heartbreak-rule-cost-india-the-cup/featured.png"
    },
    { title: "Why Indian Fast Bowlers Break Down Every 6 Months. The Ugly Truth Nobody Wants to Hear", slug: "why-indian-fast-bowlers-break-down-every-6-months", category: "Behind the Scenes", categorySlug: "behind-the-scenes", description: "Bumrah, Shami, Bhuvi — India keeps losing its best pace bowlers. Here's the ugly truth about IPL workload and BCCI scheduling.", image: "/articles/why-indian-fast-bowlers-break-down-every-6-months/featured.jpg", date: "2026-06-18", readTime: "8 min read", featured: false },
    { title: "MS Dhoni's Last Night as a CSK Player. The Farewell Nobody Filmed", slug: "ms-dhoni-last-night-csk-farewell-nobody-filmed", category: "Untold Stories", categorySlug: "untold-stories", description: "MS Dhoni played his last IPL match. No announcement. No grand farewell. Here's what happened when the cameras stopped rolling.", image: "/articles/ms-dhoni-last-night-csk-farewell-nobody-filmed/featured.png", date: "2026-06-16", readTime: "9 min read", featured: false },
    { title: "What Happens When the IPL Stops Calling Your Name", slug: "what-happens-when-ipl-stops-calling-your-name", category: "Behind the Scenes", categorySlug: "behind-the-scenes", description: "Every IPL auction creates millionaires. But what happens to the players who stop getting bought? The silence nobody prepares you for.", image: "/articles/what-happens-when-ipl-stops-calling-your-name/featured.png", date: "2026-06-14", readTime: "8 min read", featured: false },
    { title: "Kane Williamson Just Retired. He Was the Quietest Great Cricketer We'll Ever See", slug: "kane-williamson-retired-quietest-great-cricketer", category: "Legendary Moments", categorySlug: "legendary-moments", description: "Kane Williamson retired today. 19,346 runs, 48 centuries, WTC champion, Fab Four member. No drama, no noise. Just pure cricket.", image: "/articles/kane-williamson-retired-quietest-great-cricketer/featured.avif", date: "2026-06-12", readTime: "8 min read", featured: false },
    { title: "They Called Him the Next Dhoni. Then CSK Finished 8th and Everything Fell Apart", slug: "ruturaj-gaikwad-next-dhoni-csk-finished-8th", category: "Rise to Fame", categorySlug: "rise-to-fame", description: "Ruturaj Gaikwad went from Orange Cap winner to CSK's worst season ever. The captaincy crushed his batting, critics piled on, and Dhoni's shadow never left.", image: "/articles/ruturaj-gaikwad-next-dhoni-csk-finished-8th/featured.jpg", date: "2026-06-09", readTime: "8 min read", featured: false },
    { title: "Your Favourite IPL Star Earns ₹16 Crore. Here's What He Actually Takes Home", slug: "ipl-salary-what-cricketers-actually-take-home", category: "Behind the Scenes", categorySlug: "behind-the-scenes", description: "IPL auction prices look massive. But after tax, agent fees, and hidden costs, a ₹16 crore contract shrinks fast. Here's what cricketers actually earn.", image: "/articles/ipl-salary-what-cricketers-actually-take-home/featured.jpg", date: "2026-06-05", readTime: "7 min read", featured: false },
    { title: "28 Wickets, 2 IPL Titles, and Still No India Call. The Bhuvneshwar Kumar Story Nobody Talks About", slug: "bhuvneshwar-kumar-28-wickets-2-ipl-titles-still-no-india-call", category: "Behind the Scenes", categorySlug: "behind-the-scenes", description: "Bhuvneshwar Kumar took 28 wickets in IPL 2026, helped RCB win back-to-back titles, crossed 350 T20 wickets. India still hasn't called.", image: "/articles/bhuvneshwar-kumar-28-wickets-2-ipl-titles-still-no-india-call/featured.webp", date: "2026-06-04", readTime: "8 min read", featured: false },
    { title: "The Six That Completed the Dream: Virat Kohli and RCB's Back-to-Back IPL Title", slug: "the-six-that-completed-the-dream-virat-kohli-ipl-2026-final", category: "Legendary Moments", categorySlug: "legendary-moments", description: "Virat Kohli hit the winning six in the IPL 2026 final. RCB became back-to-back champions. After 16 years of heartbreak, here's what that moment really meant.", image: "/articles/the-six-that-completed-the-dream-virat-kohli-ipl-2026-final/featured.jpg", date: "2026-06-03", readTime: "8 min read", featured: false },
    { title: "He's 15 and He Just Broke the IPL. Not Everyone's Happy About It", slug: "vaibhav-suryavanshi-15-year-old-who-broke-ipl", category: "Untold Stories", categorySlug: "untold-stories", description: "Vaibhav Suryavanshi is 15. He just smashed 776 runs, hit 72 sixes, and broke Chris Gayle's record. But not everyone is cheering.", image: "/articles/vaibhav-suryavanshi-15-year-old-who-broke-ipl/featured.png", date: "2026-05-30", readTime: "7 min read", featured: false },
    { title: "The Next Sachin Who Never Made It: The Manish Pandey Story", slug: "the-next-sachin-who-never-made-it-the-manish-pandey-story", category: "Untold Stories", categorySlug: "untold-stories", description: "Before Virat Kohli became India's biggest star, many believed Manish Pandey would be India's next cricket superstar. What really happened?", image: "/articles/the-next-sachin-who-never-made-it-the-manish-pandey-story/featured.jpg", date: "2026-05-29", readTime: "6 min read", featured: false },
    { title: "The Night Virat Kohli Almost Quit Cricket", slug: "the-night-virat-kohli-almost-quit-cricket", category: "Untold Stories", categorySlug: "untold-stories", description: "On the night his father passed away, 18-year-old Virat Kohli made a decision nobody expected. This is the story cricket never puts in the highlight reels.", image: "/articles/the-night-virat-kohli-almost-quit-cricket/featured.avif", date: "2026-05-28", readTime: "6 min read", featured: false },
    // Example article object (uncomment and modify when you have articles):
    // {
    //     title: "The Night Virat Kohli Almost Quit Cricket",
    //     slug: "virat-kohli-almost-quit-cricket",
    //     category: "Untold Stories",
    //     categorySlug: "untold-stories",
    //     description: "Before becoming the greatest run-chaser in cricket history, there was a night when a young Virat Kohli wanted to give up everything.",
    //     image: "/articles/virat-kohli-almost-quit-cricket/featured.jpg",
    //     date: "2026-06-01",
    //     readTime: "8 min read",
    //     featured: true
    // }
];

// Category badge color mapping
function getCategoryClass(category) {
    const map = {
        'Untold Stories': '',
        'Rise to Fame': 'green',
        'Behind the Scenes': 'blue',
        'Legendary Moments': 'red'
    };
    return map[category] || '';
}

// Format date
function formatDate(dateStr) {
    const d = new Date(dateStr);
    return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

// Render articles on homepage
function renderArticles() {
    const grid = document.getElementById('articlesGrid');
    const emptyState = document.getElementById('emptyState');
    const featuredEl = document.getElementById('featuredArticle');
    const countEl = document.getElementById('articleCount');

    if (!grid) return;

    // Filter articles: only show articles whose date is today or earlier
    const today = new Date();
    today.setHours(23, 59, 59, 999);
    const publishedArticles = ARTICLES.filter(a => new Date(a.date) <= today);

    // Update article count
    if (countEl) {
        animateCounter(countEl, publishedArticles.length);
    }

    if (publishedArticles.length === 0) {
        if (emptyState) emptyState.style.display = '';
        if (featuredEl) featuredEl.style.display = 'none';
        grid.innerHTML = '';
        return;
    }

    if (emptyState) emptyState.style.display = 'none';

    // Featured = newest published article
    const featured = publishedArticles[0];
    const restArticles = publishedArticles.filter(a => a !== featured);

    // Render featured
    if (featuredEl && featured) {
        featuredEl.style.display = '';
        featuredEl.href = `/articles/${featured.slug}/`;
        document.getElementById('featuredImg').src = featured.image;
        document.getElementById('featuredImg').alt = featured.title;
        document.getElementById('featuredCat').textContent = featured.category;
        document.getElementById('featuredCat').className = 'category-badge ' + getCategoryClass(featured.category);
        document.getElementById('featuredTitle').textContent = featured.title;
        document.getElementById('featuredDesc').textContent = featured.description;
        document.getElementById('featuredDate').textContent = formatDate(featured.date);
        document.getElementById('featuredReadTime').textContent = featured.readTime;
    }

    // Render grid
    grid.innerHTML = restArticles.slice(0, 6).map(article => `
        <a href="/articles/${article.slug}/" class="article-card fade-in">
            <div class="card-image-wrapper">
                <img src="${article.image}" alt="${article.title}" loading="lazy">
            </div>
            <div class="card-body">
                <span class="category-badge ${getCategoryClass(article.category)}">${article.category}</span>
                <h3>${article.title}</h3>
                <p>${article.description}</p>
                <div class="article-meta">
                    <span><i class="fas fa-user"></i> CricketHub</span>
                    <span><i class="fas fa-calendar"></i> ${formatDate(article.date)}</span>
                    <span><i class="fas fa-clock"></i> ${article.readTime}</span>
                </div>
            </div>
        </a>
    `).join('');

    // Re-observe new fade-in elements
    grid.querySelectorAll('.fade-in').forEach(el => fadeObserver.observe(el));
}

// Animate counter
function animateCounter(el, target) {
    let current = 0;
    const duration = 1500;
    const step = target / (duration / 16);
    function update() {
        current += step;
        if (current >= target) {
            el.textContent = target;
            return;
        }
        el.textContent = Math.floor(current);
        requestAnimationFrame(update);
    }
    update();
}

// ---- Newsletter ----
function handleNewsletter(e) {
    e.preventDefault();
    const email = document.getElementById('newsletterEmail');
    if (email && email.value) {
        // Store in localStorage as a simple subscriber list
        const subs = JSON.parse(localStorage.getItem('ch_subscribers') || '[]');
        if (!subs.includes(email.value)) {
            subs.push(email.value);
            localStorage.setItem('ch_subscribers', JSON.stringify(subs));
        }
        email.value = '';
        // Show success message
        const form = document.getElementById('newsletterForm');
        const msg = document.createElement('p');
        msg.style.cssText = 'color: var(--gold); font-weight: 600; margin-top: 12px;';
        msg.textContent = '🎉 You\'re subscribed! We\'ll send you the best cricket stories.';
        form.parentNode.appendChild(msg);
        setTimeout(() => msg.remove(), 4000);
    }
    return false;
}

// ---- Reading Progress Bar (for article pages) ----
function initReadingProgress() {
    const progressBar = document.querySelector('.reading-progress');
    if (!progressBar) return;

    window.addEventListener('scroll', () => {
        const scrollTop = window.scrollY;
        const docHeight = document.documentElement.scrollHeight - window.innerHeight;
        const progress = (scrollTop / docHeight) * 100;
        progressBar.style.width = Math.min(progress, 100) + '%';
    });
}

// ---- Social Share (for article pages) ----
function shareArticle(platform) {
    const url = encodeURIComponent(window.location.href);
    const title = encodeURIComponent(document.title);

    const urls = {
        twitter: `https://twitter.com/intent/tweet?url=${url}&text=${title}`,
        facebook: `https://www.facebook.com/sharer/sharer.php?u=${url}`,
        whatsapp: `https://api.whatsapp.com/send?text=${title}%20${url}`,
        linkedin: `https://www.linkedin.com/sharing/share-offsite/?url=${url}`,
    };

    if (platform === 'copy') {
        navigator.clipboard.writeText(window.location.href).then(() => {
            const btn = document.querySelector('[onclick="shareArticle(\'copy\')"]');
            if (btn) {
                const original = btn.innerHTML;
                btn.innerHTML = '<i class="fas fa-check"></i>';
                btn.style.color = 'var(--green)';
                btn.style.borderColor = 'var(--green)';
                setTimeout(() => {
                    btn.innerHTML = original;
                    btn.style.color = '';
                    btn.style.borderColor = '';
                }, 2000);
            }
        });
        return;
    }

    if (urls[platform]) {
        window.open(urls[platform], '_blank', 'width=600,height=400');
    }
}

// ---- Initialize ----
document.addEventListener('DOMContentLoaded', () => {
    renderArticles();
    initReadingProgress();
});
