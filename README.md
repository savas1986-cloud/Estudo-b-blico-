# Raízes & Graça — PWA

Arquivos:
- `index.html` — o app completo (Bíblia Livre embutida) com meta tags PWA e registro do Service Worker
- `manifest.json` — nome, cores, ícones e atalhos do app instalado
- `sw.js` — Service Worker: funciona offline e abre instantaneamente
- `icons/` — ícone SVG (Bíblia com ramo de oliveira) e PNGs para Android, iPhone e favicon

## Como publicar
O PWA precisa de **HTTPS**. Qualquer hospedagem de site estático gratuita serve:
- **Netlify Drop**: arraste esta pasta em app.netlify.com/drop
- **GitHub Pages**: suba a pasta num repositório e ative Pages
- **Vercel / Cloudflare Pages**: importe a pasta como site estático

Mantenha todos os arquivos juntos na mesma pasta (o app funciona também em subpastas).

## Como instalar
- **Android (Chrome):** abra o site → aparece o convite "Instalar" (ou menu ⋮ → Instalar app).
- **iPhone (Safari):** abra o site → Compartilhar → Adicionar à Tela de Início.

## Atualizações
Ao publicar uma nova versão do `index.html`, troque `VERSION` no topo do `sw.js`
(ex.: `rg-v1.0.1`) para que os aparelhos baixem a versão nova.

## Testar no computador
    python3 -m http.server 8080
e abra http://localhost:8080 (o Service Worker também funciona em localhost).
