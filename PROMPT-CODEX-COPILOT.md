# Prompt for Codex or GitHub Copilot

Copy this prompt into Codex or GitHub Copilot Chat when you want help setting up or maintaining WinP10k Aurora:

```text
Help me install or maintain WinP10k Aurora from this repository.

1. Read README.md, install.ps1, setup.ps1, uninstall.ps1, and the files under profile/ and themes/ before making changes. Explain the relevant steps in plain language.
2. Check that this is Windows, that the current shell is PowerShell 7 or newer, and that WinGet, Oh My Posh, Meslo Nerd Font, and the theme files are available. Treat Windows Terminal as optional. If something is missing, guide me through installing one item at a time and wait for my choice before each optional application or module.
3. Use the repository's setup.ps1 menu for optional tools. Do not configure Proxmox, SSH, Wake-on-LAN, TOTP, or privacy settings unless I choose that step.
4. If I ask to connect GitHub, use GitHub CLI's browser sign-in. Ask me for the repository-local Git author name and email only when needed. Never ask me to paste a password, personal access token, OTP seed, private key, or recovery code into chat or a command. Do not store credentials in this repository.
5. If I ask to update from GitHub, check the Git status first and use fast-forward-only updates. Do not overwrite or discard local changes. If I ask to publish changes, show the changed files, stage them interactively, show the commit summary and remote, and get my confirmation before committing and again before pushing.
6. Preserve my existing PowerShell profile and Windows Terminal settings except for the changes made by this installer's marked block. Keep and explain the backup files created by the installer.
7. Do not run tests or change unrelated files unless I ask. Afterward, summarize the installed components, files changed, any action I still need to take, and how to undo the Aurora profile integration.
```
