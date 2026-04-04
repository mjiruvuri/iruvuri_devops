# Auto-pushing changes to GitHub

This repository includes two approaches to automatically push changes to GitHub:

- Local (recommended for simple setups): a Git hook that runs `git push` after each commit.
- Remote (recommended for automated changes produced by CI): a GitHub Actions workflow that can commit and push changes from the workflow.

Follow the sections below to choose the one that fits your workflow.

## 1) Local: install the post-commit hook

1. Ensure you have a working remote named `origin` pointing to GitHub (SSH or HTTPS):

   git remote -v

   If it doesn't exist, add it:

   git remote add origin git@github.com:<owner>/<repo>.git

2. (Recommended) Use SSH authentication for painless non-interactive pushes. Create an SSH key and add it to your GitHub account if you haven't already:

   ssh-keygen -t ed25519 -C "your_email@example.com"
   # then add the public key (~/.ssh/id_ed25519.pub) to GitHub -> Settings -> SSH and GPG keys

3. Install the hook (from repo root):

   ./scripts/install-git-hook.sh

   This copies `hooks/post-commit` into `.git/hooks/post-commit` and makes it executable.

4. Commit as usual. After each commit the hook will attempt to push the current branch to `origin`.

Notes and caveats:
- The hook performs a plain `git push origin <branch>` and will fail if the remote rejects the push (e.g., due to non-fast-forward or required checks).
- The hook is intentionally simple. For more advanced flows (checking tests, rebase, retries) extend `hooks/post-commit`.

## 2) Remote: use GitHub Actions to push (for repo-driven automation)

The workflow in `.github/workflows/auto-push.yml` shows a minimal job that can commit and push changes created by the workflow. It uses the `GITHUB_TOKEN` and requires the workflow to have `permissions: contents: write`.

Typical use-case: you have a formatting or maintenance job that updates files on a schedule and commits the changes.

Security notes:
- For local hooks, prefer SSH keys rather than embedding personal access tokens in scripts.
- For CI pushes, use the built-in `GITHUB_TOKEN` with `contents: write` where possible; if you need a PAT, store it as a repository secret and reference it from the workflow.

## 3) Alternatives

- Use a launchd job on macOS to run a periodic `git pull && git add -A && git commit -m '...' && git push` script.
- Use Git GUI tools or your editor's auto-save + push extensions, if you prefer.

If you'd like, I can:
- Install the hook for you now.
- Create a small launchd plist to run periodic pushes on macOS.
- Customize the GitHub Actions workflow for a specific automation script in this repo.
