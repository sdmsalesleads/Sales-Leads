# Sales Team CRM

A single-file, serverless CRM web application. All application logic, styling and
markup live in `index.html`. No build step, no backend, no database server.

## How it works
- All data (accounts, leads, targets) is stored in each user's **browser
  localStorage** — nothing is stored in this repository and nothing is sent to
  any server.
- External dependencies are loaded from CDNs at runtime:
  - SheetJS (Excel import/export) — cdnjs.cloudflare.com
  - Archivo font — fonts.googleapis.com
- Requires an internet connection on load.

## Deployment
Host `index.html` on any static hosting (GitHub Pages, Netlify, etc.).
Open the site once to run the first-time administrator setup, then add team
member accounts from the Team page.

## Privacy note
This repository contains **no data**: no leads, no names, no emails, no
passwords. Those exist only inside each user's browser after they use the app.
