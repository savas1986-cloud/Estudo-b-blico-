/* Raízes & Graça — Service Worker
 * - Pré-carrega o app (a Bíblia inteira está dentro do index.html) para funcionar offline.
 * - Abre instantaneamente do cache e atualiza em segundo plano (stale-while-revalidate).
 * - Guarda as fontes do Google em cache após o primeiro acesso.
 * Ao publicar uma nova versão, altere VERSION para forçar a atualização do cache.
 */
const VERSION = "rg-v1.0.0";
const APP_CACHE = `app-${VERSION}`;
const RUNTIME_CACHE = `runtime-${VERSION}`;

const PRECACHE = [
  "./",
  "./index.html",
  "./manifest.json",
  "./icons/icon.svg",
  "./icons/icon-192.png",
  "./icons/icon-512.png",
  "./icons/icon-maskable-192.png",
  "./icons/icon-maskable-512.png",
  "./icons/apple-touch-icon.png",
  "./icons/favicon-32.png",
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(APP_CACHE)
      .then((cache) => cache.addAll(PRECACHE.map((u) => new Request(u, { cache: "reload" }))))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== APP_CACHE && k !== RUNTIME_CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

// Busca na rede e atualiza o cache; devolve o cache se já existir.
async function staleWhileRevalidate(request, cacheName, fallbackKey) {
  const cache = await caches.open(cacheName);
  const cached = await cache.match(fallbackKey || request, { ignoreSearch: true });
  const network = fetch(request)
    .then((res) => {
      if (res && (res.ok || res.type === "opaque")) cache.put(fallbackKey || request, res.clone());
      return res;
    })
    .catch(() => null);
  return cached || (await network) || new Response("Você está offline e esta página ainda não foi salva.", {
    status: 503, headers: { "Content-Type": "text/plain; charset=utf-8" },
  });
}

self.addEventListener("fetch", (event) => {
  const { request } = event;
  if (request.method !== "GET") return;
  const url = new URL(request.url);

  // Abrir o app (qualquer navegação dentro do escopo) → index.html do cache
  if (request.mode === "navigate" && url.origin === self.location.origin) {
    event.respondWith(staleWhileRevalidate(request, APP_CACHE, "./index.html"));
    return;
  }

  // Arquivos do próprio app (ícones, manifest)
  if (url.origin === self.location.origin) {
    event.respondWith(staleWhileRevalidate(request, APP_CACHE));
    return;
  }

  // Fontes (Lora e Inter)
  if (url.hostname === "fonts.googleapis.com" || url.hostname === "fonts.gstatic.com") {
    event.respondWith(staleWhileRevalidate(request, RUNTIME_CACHE));
  }
});

// Permite que a página peça para ativar uma nova versão imediatamente
self.addEventListener("message", (event) => {
  if (event.data === "SKIP_WAITING") self.skipWaiting();
});
