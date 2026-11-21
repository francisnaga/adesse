const CACHE_NAME = 'muster-v1';
const ASSETS = [
  './',
  './index.html',
  './config.js',
  './privacy.html',
  './terms.html',
  './delete-account.html',
  './site.webmanifest',
  './manifest.webmanifest',
  './favicon.svg',
  './favicon.ico',
  './favicon-16x16.png',
  './favicon-32x32.png',
  './favicon-48x48.png',
  './safari-pinned-tab.svg',
  './og-image-1200x630.png',
  './icon-192.png',
  './icon-512.png',
  './icon-maskable-192.png',
  './icon-maskable-512.png',
  './apple-touch-icon.png',
  'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(ASSETS)).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys => Promise.all(
      keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k))
    )).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;
  
  // Never cache Supabase API calls or external OAuth endpoints
  const url = new URL(event.request.url);
  if (url.origin.includes('supabase.co') || url.pathname.includes('/auth/v1/')) {
    return;
  }

  // Network-first for HTML navigation requests to always show latest UI
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request).then(response => {
        if (response && response.status === 200) {
          const toCache = response.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(event.request, toCache));
        }
        return response;
      }).catch(() => caches.match('./index.html'))
    );
    return;
  }

  event.respondWith(
    caches.match(event.request).then(cached => {
      if (cached) return cached;
      return fetch(event.request).then(response => {
        if (!response || response.status !== 200 || response.type !== 'basic') {
          return response;
        }
        const toCache = response.clone();
        caches.open(CACHE_NAME).then(cache => cache.put(event.request, toCache));
        return response;
      });
    })
  );
});
