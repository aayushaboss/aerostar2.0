# Aerostar 2.0 — student portal redesign

Pushed to https://github.com/aayushaboss/aerostar2.0.git (main).

- `app/` — the Aerostar Flutter app (copied from `placement app aerostar version`), redesigned to the Aerostar Minimal design system.
- `Aerostar Student Portal Redesign.html` — static design canvas (mobile + desktop screens).
- `Aerostar Student Portal Prototype.html` — clickable HTML prototype (opens as mobile or desktop by window width).

## Run the Flutter app on your Wi-Fi

```bash
cd app
flutter build web --release --no-tree-shake-icons --pwa-strategy=none
node tool/serve_web.js 8081
```

- Laptop browser: `http://localhost:8081` shows the desktop layout (top navigation bar).
- Phone on the same Wi-Fi: `http://<this PC's IPv4>:8081` shows the mobile layout (bottom tab bar).

Rebuild after code changes (about 2 minutes), then reload the page.
