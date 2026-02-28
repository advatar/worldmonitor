# Upstream update + redeploy workflow

Upstream changes are frequent, so this workflow keeps local customizations (like your TV API work) out of your way during pulls.

## One-command workflow

- Update only:
  - `npm run sync:upstream`
- Update and deploy:
  - `npm run sync:upstream:deploy`

## What it does

- Fetches `origin/<branch>` (default `origin/main`).
- Rebases the current branch on top of upstream.
- If there are local changes, it stashes them first (including untracked files), then reapplies after rebase.
- Optionally runs `npx --yes vercel --prod --yes`.

## If you need custom upstream branch

```bash
npm run sync:upstream -- --branch release
```

## Conflict handling

- If the stash restore fails, fix conflicts, then finish with:
  - `git add -u`
  - `git stash pop`

If the rebase itself fails, resolve conflicts and run:
- `git rebase --continue`
- then re-run the script.

If you want to skip automatic stashing, use:

```bash
npm run sync:upstream -- --skip-stash
```
This exits with a clear message when local changes are present.
