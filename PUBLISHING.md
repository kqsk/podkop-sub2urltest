# Publishing / maintaining

Repo: https://github.com/kqsk/podkop-sub2urltest

## End-user install (share this)

```sh
wget -qO- https://raw.githubusercontent.com/kqsk/podkop-sub2urltest/main/remote-install.sh | ash
```

The installer asks for the subscription URL, writes config, runs the first
update, and enables periodic updates. Re-running it updates the script and keeps
the existing config.

## Pushing changes

```sh
git add -A
git commit -m "..."
git push
```

`remote-install.sh` pulls files from the `main` branch via raw.githubusercontent,
so a push is live immediately (subject to GitHub raw CDN cache ~5 min).
