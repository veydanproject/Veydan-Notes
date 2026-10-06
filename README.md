<p align="center">
  <img src="docs/images/logo.png" width="112" alt="Veydan Notes logo">
</p>

<h1 align="center">Veydan Notes</h1>

<p align="center">
  <b>Notes with end-to-end encrypted sync.</b><br>
  Markdown notes that live on your disk, sync through storage you own, and work on your computer and phone.
</p>

<p align="center">
  <a href="https://github.com/veydanproject/Veydan-Notes/releases/latest"><img alt="Latest release" src="https://img.shields.io/github/v/release/veydanproject/Veydan-Notes?style=flat-square&color=10b981&label=release"></a>
  <img alt="Platforms" src="https://img.shields.io/badge/Windows%20·%20macOS%20·%20Linux%20·%20Android-0b0d14?style=flat-square">
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/license-PolyForm%20Perimeter-0b0d14?style=flat-square"></a>
</p>

<p align="center">
  <a href="https://github.com/veydanproject/Veydan-Notes/releases/latest"><b>Download</b></a> ·
  <a href="#features">Features</a> ·
  <a href="#on-your-phone">On your phone</a> ·
  <a href="#privacy">Privacy</a> ·
  <a href="docs/DEVELOPMENT.md">Build from source</a>
</p>

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/hero-dark.jpg">
  <img alt="Veydan Notes: a note with a table and a checklist on the computer and on a phone" src="docs/images/hero-light.jpg">
</picture>

## Why Veydan Notes

- **Your notes are files.** Every note is a plain Markdown file in a folder
  you choose. Open it in any editor, back it up any way you like — nothing is
  locked inside the app.
- **Sync without giving your notes to anyone.** Sync goes through your own
  folder, S3 bucket or WebDAV share, and everything is encrypted on the
  device first. There is no Veydan cloud and no account.
- **Nothing gets lost.** Every save keeps the previous version: compare,
  restore or merge any of them.
- **Computer and phone.** Windows, macOS, Linux and Android, with the same
  notes everywhere.

## Features

### Write in Markdown, see it formatted

A rich editor with headings, **tables**, checklists, quotes, code blocks,
links and images — or switch to the raw Markdown source with one click.
Paste or drop a picture or a file and it becomes an attachment.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/screen-note-image-dark.png">
  <img alt="A note with an image, a quote and a code block" src="docs/images/screen-note-image-light.png">
</picture>

### Organise your way

- **Folders and subfolders**, **colored tags** (a tag like `status/todo`
  groups into "status"), **pins** and an **archive**.
- **Smart views** — saved filters: by tags, folder, open tasks, attachments,
  or what changed in the last days.
- **Wiki links** — type `[[` to link another note; every note shows what
  links to it.
- **Templates** — any note in the `Templates` folder becomes a template with
  `{{date}}`, `{{time}}` and `{{title}}` filled in.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/screen-trip-dark.png">
  <img alt="A travel plan with a photo, in the Personal folder" src="docs/images/screen-trip-light.png">
</picture>

### A table of all your notes

Switch the list to a **table**: tags become columns (status, project, area…),
so a pile of notes turns into a tracker you can sort.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/screen-table-dark.png">
  <img alt="The table view: tags as columns" src="docs/images/screen-table-light.png">
</picture>

### Find anything, keep everything

- **Full-text search** across every note, and find & replace inside one.
- **Version history** — compare any two versions line by line, restore one,
  or merge pieces of an old version back in.
- **Safe sync conflicts** — if two devices change the same lines, nothing is
  thrown away: you choose per piece what to keep.
- **Crash-safe drafts** — unsaved text comes back after an unexpected close.
- **Edits from outside** — change a file in another editor and the app picks
  it up.

### Capture in a second

A **quick-capture window** from the tray or the command palette: type, pick a
folder or tags, or take the text from the clipboard, and save with
<kbd>Ctrl</kbd>+<kbd>Enter</kbd>. The **command palette** reaches every
action from the keyboard.

### Import and export

Import Markdown and text files or whole folders (front matter and images
come along). Export to a folder or a ZIP — Markdown with your attachments,
optionally **encrypted with a passphrase**.

## On your phone

The Android app has the same notes, folders, tags and editor, plus photo and
file attachments straight from the phone.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/phones-dark.png">
  <img alt="Veydan Notes on Android: the list, a note, a note with a photo and the folders" src="docs/images/phones-light.png">
</picture>

## Sync between your devices

Settings → Sync. Create a vault in an empty place you control, then join it
from your other devices with the same passphrase:

- **a folder** that Dropbox, Seafile, Syncthing or any cloud client mirrors
  (on a computer);
- **an S3-compatible bucket** (AWS S3, MinIO, Cloudflare R2…);
- **a WebDAV share** (Nextcloud and others).

Sync is in **beta**.

## Download

Get the latest version from the
**[releases page](https://github.com/veydanproject/Veydan-Notes/releases/latest)**.

| Platform | What to download |
|---|---|
| **Windows** 10 and 11 (x64) | the `.exe` installer (or the `.msi`) |
| **macOS** — Apple Silicon | the `.dmg` marked `aarch64` |
| **macOS** — Intel | the `.dmg` marked `x64` |
| **Linux** (x64) | `.AppImage`, or `.deb` / `.rpm` for your distribution |
| **Android** 8.0 and newer (64-bit ARM) | the `.apk` |

If macOS refuses to open the app on the first launch, right-click it and
choose **Open**.

The app updates itself when a new version comes out. Installed from a
`.deb` or `.rpm`? The app tells you about the new version, and you install it
from the releases page.

## Privacy

- **No account, no telemetry.** The app talks only to your own sync storage
  and to GitHub, to check for updates.
- **Sync storage only ever sees ciphertext** — notes and attachments are
  encrypted on the device (XChaCha20-Poly1305, with a key derived from your
  passphrase by Argon2id) before they leave it.
- **On the device, notes are plain Markdown files** — that is what keeps them
  yours and readable anywhere. Protect the disk with full-disk encryption.
- **App lock** — a PIN or password, with auto-lock; it locks the app window.

## The Veydan family

| | App | What it is |
|---|---|---|
| <img src="docs/images/logo.png" width="36" alt=""> | **Veydan Notes** | Markdown notes with end-to-end encrypted sync |
| <img src="https://raw.githubusercontent.com/veydanproject/Veydan-Pass/main/docs/images/logo.png" width="36" alt=""> | [Veydan Pass](https://github.com/veydanproject/Veydan-Pass) | Passwords and one-time codes, encrypted and synced |
| <img src="https://raw.githubusercontent.com/veydanproject/Veydan-Chat/main/docs/images/logo.png" width="36" alt=""> | [Veydan Chat](https://github.com/veydanproject/Veydan-Chat) | End-to-end encrypted chat on Nostr |
| <img src="https://raw.githubusercontent.com/veydanproject/Veydan-Space/main/docs/images/logo.png" width="36" alt=""> | [Veydan Space](https://github.com/veydanproject/Veydan-Space) | All of them in one workspace, plus browser profiles, proxies and SSH |

## Feedback

Found a bug or have an idea? [Open an issue](https://github.com/veydanproject/Veydan-Notes/issues).
Developers: see [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for building from
source.

## License

Copyright © 2026 **Veydan Project**.

Developed by **Rookbeam Technologies LLC**, USA.

Veydan Notes is **source-available** software under the
[PolyForm Perimeter License 1.0.1](https://polyformproject.org/licenses/perimeter/1.0.1):
see [`LICENSE`](LICENSE), a summary in [`LICENSE-SUMMARY.md`](LICENSE-SUMMARY.md)
and the licences of what it is built from in
[`THIRD-PARTY-LICENSES.md`](THIRD-PARTY-LICENSES.md).
