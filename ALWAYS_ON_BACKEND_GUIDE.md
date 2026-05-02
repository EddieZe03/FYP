# Always-On Backend + Cloudflare Tunnel (Linux)

Use this if you want your Flask backend and Cloudflare tunnel to auto-start and keep running without manually typing commands each time.

## What this setup gives you

- Flask backend auto-starts after reboot.
- Cloudflare quick tunnel auto-starts after backend.
- Services auto-restart if they crash.
- You can check logs/status from terminal any time.

## 1) Make scripts executable

```bash
cd /workspaces/FYP
chmod +x scripts/run_backend.sh scripts/run_cloudflared_quick_tunnel.sh
```

## 2) Install systemd user services

```bash
mkdir -p ~/.config/systemd/user
cp deploy/systemd/phish-guard-backend.service ~/.config/systemd/user/
cp deploy/systemd/phish-guard-cloudflared.service ~/.config/systemd/user/
systemctl --user daemon-reload
```

## 3) Enable auto-start

```bash
systemctl --user enable phish-guard-backend.service
systemctl --user enable phish-guard-cloudflared.service
```

If you want services to continue running even after logout:

```bash
sudo loginctl enable-linger "$USER"
```

## 4) Start now

```bash
systemctl --user start phish-guard-backend.service
systemctl --user start phish-guard-cloudflared.service
```

## 5) Verify

```bash
systemctl --user status phish-guard-backend.service --no-pager
systemctl --user status phish-guard-cloudflared.service --no-pager
curl -s http://127.0.0.1:5000/api/health
```

## 6) Get the tunnel URL

The quick-tunnel URL appears in:

```bash
tail -f ~/.local/state/phish-guard/cloudflared.log
```

Copy that `https://...trycloudflare.com` URL and use it as Flutter backend:

```bash
flutter run --dart-define=API_BASE_URL=https://YOUR-URL.trycloudflare.com
```

## Useful commands

Stop services:

```bash
systemctl --user stop phish-guard-cloudflared.service
systemctl --user stop phish-guard-backend.service
```

Restart services:

```bash
systemctl --user restart phish-guard-backend.service
systemctl --user restart phish-guard-cloudflared.service
```

View logs:

```bash
tail -f ~/.local/state/phish-guard/backend.log
tail -f ~/.local/state/phish-guard/cloudflared.log
```

## Important notes

- Quick tunnel URL can change if cloudflared restarts.
- Your laptop must stay powered on and connected to internet.
- For a truly no-laptop demo, deploy backend to a cloud host (Render/Railway/Fly) and use that permanent URL in `API_BASE_URL`.
