# Raízes & Graça — PWA com Comunidade online

## Arquivos
- `index.html` — o app completo (Bíblia Livre embutida)
- `config.js` — **onde você cola os dados do Supabase** (único arquivo que você edita)
- `supabase.sql` — cria o banco da comunidade com as regras de segurança
- `manifest.json`, `sw.js`, `icons/` — instalação como app e modo offline
- `vercel.json` — cabeçalhos corretos para a Vercel

## Ativar a Comunidade (uma vez, ~10 minutos)
1. Crie uma conta grátis em **supabase.com** → **New project** (região: São Paulo / sa-east-1).
2. Menu **SQL Editor** → **New query** → cole todo o conteúdo de `supabase.sql` → **Run**.
3. Menu **Authentication → Sign In / Providers** (ou *Settings*) → ligue **Allow anonymous sign-ins** → Save.
4. Menu **Project Settings → API** (ou *Data API*): copie **Project URL** e a chave **anon / public**.
5. Abra `config.js` e cole os dois valores entre as aspas.
6. Publique a pasta na Vercel (preset **Other**, sem build). Pronto!

> A chave **anon/public** pode ficar no site. Nunca use a chave **service_role**.

## Como as amigas participam
- Quem cria o grupo toca em **Convidar** → envia o link pelo WhatsApp.
- A amiga toca no link → o app abre em "Você foi convidada!" com o nome do grupo → ela digita só o nome.
- Também dá para entrar manualmente: **Comunidade → Entrar com código**.
- Não precisa de e-mail nem senha. Se alguém trocar de celular ou limpar o navegador,
  é só entrar de novo com o código (os pedidos antigos continuam no grupo).

## Segurança e moderação
- Só quem tem o código vê o grupo; ninguém consegue listar grupos de outras pessoas.
- Cada uma só apaga o que ela mesma publicou.
- A **criadora do grupo** pode apagar qualquer pedido/partilha, remover participantes e excluir o grupo.
- Grifos, anotações, respostas dos estudos e plano de leitura continuam **só no aparelho** de cada uma.

## Publicando na Vercel
- Envie a pasta inteira na **raiz** do projeto. Framework Preset: **Other**.
- Instale pelo endereço de **produção** (`seu-projeto.vercel.app`). Links de *preview* têm
  "Vercel Authentication" e impedem a instalação (Settings → Deployment Protection).
- Teste: abra `https://seu-projeto.vercel.app/manifest.json` numa aba anônima.

## Atualizações
Ao trocar o `index.html`, mude `VERSION` no topo do `sw.js` (ex.: `rg-v1.1.1`).
Mudanças só no `config.js` não precisam disso.
