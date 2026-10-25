# PAI

A phone-first build of [pi-web](https://github.com/agegr/pi-web).

pi-web runs the [pi](https://github.com/earendil-works/pi) coding agent in a browser —
sessions, files, git, skills, model configuration — and all of that is upstream's. What it
did not have is a layout composed for a phone, and it carries a handful of defects that a
phone runs into first. That is what this build changes, and nothing else.

```sh
npx @perturbationai/pai
```

It serves on `127.0.0.1:30141`. Add it to your home screen and it runs standalone, with
lock-screen notifications when a session finishes.

```sh
npx @perturbationai/pai --help          # ports, hostname, the PI_WEB_* environment
```

The environment variables are upstream's and unchanged — `PI_WEB_PASSWORD`,
`PI_WEB_ALLOWED_HOSTS`, `PI_WEB_HOSTNAME` — so anything already configured against pi-web
keeps working.

## What is different from pi-web

Every change is listed below. The complete diff is one link: **[v0.9.1 → this
build](../../compare/upstream...main)** — the first commit in this repository is upstream
v0.9.1 imported verbatim, so the comparison against it is exactly what PAI changes.

### Fixed

Upstream defects rather than preferences. Each was reproduced before it was patched, and
each is better sent upstream than carried here.

- **A new session did not survive being left.** The workspace's last-open memory was not
  cleared, so the next load restored the session that was open before it. Loading a bare
  `/` ended at `?session=<the previous one>`. It matters most on a phone, where a
  home-screen app is relaunched constantly.
- **The first tap on a session row only produced a hover state,** revealing rename and
  delete under the finger, so opening the session took a second tap.
- **Hover painted into the inline style stuck after a touch.** iOS fires `mouseenter` and
  often never `mouseleave`, so the tint stayed under the finger — including a blue flash
  on whichever control the session dialog opened beneath.
- **An expanded thinking block lost its collapse target,** leaving a 14×17 icon as the
  only way back. It is 26×26 now, and 38×38 where the pointer is coarse.
- **The model button omitted its provider,** although the dropdown already groups by
  provider and the same model id can exist under two of them.
- **A model that is no longer configured went on being named,** which reads as a working
  selection. It now says "Select model".
- **The keyboard's height was read once,** and WebKit reports a half-settled value on the
  resize event itself. Read again as it settles, and polled.
- **The home indicator's inset stayed reserved while the keyboard covered it.**
- **A device kept the first build it ever cached.** The service worker named its cache
  after the package version, which a patched build never moves. Each build gets its own.
- **`/apple-touch-icon.png` was a 404** — the path Safari falls back to when adding to the
  home screen, which is where a miss gets the generated letter tile instead of the mark.
- **A tap in the terminal does not raise the keyboard on iOS.** iOS raises it when a focus
  lands inside a user gesture, and xterm focuses its hidden textarea as soon as the
  connection opens, long before a thumb arrives. Reproduced against stock v0.9.1.
- **A terminal in an installed iOS web app never connects.** `connect()` returned on
  `navigator.onLine` in silence — no error, no retry. A home-screen web app reports itself
  offline while every other request on the page goes through.

### Changed

Most are confined to a phone by a width or a pointer query. Three are not, and are how
this build looks on a desktop as well: Send's ground, the process group's frame, and the
model list's group headers.

- **The composer is one card,** with its controls on a row above the text line and Stop
  coming out onto that row while a turn runs rather than staying inside a menu.
- **Send is the app's own mark on a phone,** and keeps that dark ground without the mark
  everywhere else, where upstream paints the stock accent.
- **Every control on that row is 44pt to a thumb** without being drawn at 44 — a
  transparent extender behind each one is what the browser hit-tests.
- **The top bar floats over the transcript,** at 44pt, with the session name centred and
  the context window drawn as a ring beside it. The session panel is a full dialog.
- **The drawer takes 70% of the screen** and gives the session list the room: the file
  explorer starts collapsed on a phone unless asked for.
- **An empty new session stays centred, and drops onto the keyboard when one opens.**
- **The model list is reachable by thumb,** hung off the button that opened it, its
  provider headings without upstream's upper case.
- **A turn's process details are one enclosed group,** the model named once at its header.
- **The turn line says "cache read" rather than "cache R",** and how long the turn took.
- **It is called PAI,** with its own mark and wordmark.

### Added

- **Swipe a session row left for rename and delete.**
- **Swipe in from the left edge to open the drawer** — installed app only, where that edge
  is not already the browser's back gesture.
- **Pull the transcript down to put the keyboard away.**
- **A notice when the server has been rebuilt under an open page,** with a reload. An
  installed web app resumes from memory rather than reloading.
- **A way back to the latest message.**
- **A way out of the exported history.**

## Building from source

```sh
npm install
npm test        # upstream's suite, 1020 tests
npm run build
npm start
```

## Prebuilt releases (multi-node deployment)

For devices that should run this build without a local toolchain (e.g. a
phone running Termux), `scripts/push-prebuilt.sh` publishes the runtime
artifacts (`.next`, cache excluded) as a GitHub Release asset instead of a
commit — git history stays source-only.

**Build node (this repo):**

```sh
./scripts/push-prebuilt.sh
```

Builds, uploads `pai-next.tar.gz` to a new Release (`prebuilt-<date>-<sha>`),
and restarts the local `pai.service` if it runs from this tree — a running
`next start` must not have `.next` swapped underneath it.

**Consumer node (e.g. phone):** clone this repo once, `npm install` there
once, then every update is:

```sh
~/pai/update-prebuilt.sh    # scripts/update-prebuilt.sh, copied to ~/pai
```

It fetches `/releases/latest`, swaps in `.next`, and restarts. Needs network
access to github.com — set `http_proxy`/`https_proxy` if direct access is
blocked (the script defaults to `http://192.168.10.130:7890` when unset).

### Termux (Android) deployment

One-time setup, in Termux:

```sh
pkg install nodejs clang python make git    # node-pty compiles natively
git clone -b feat/title-suffix https://github.com/playdougher/pai.git ~/pai
cd ~/pai && npm install                     # no build needed; artifacts come from Releases
cp scripts/update-prebuilt.sh ~/pai/update-prebuilt.sh && chmod +x ~/pai/update-prebuilt.sh
~/pai/update-prebuilt.sh                    # pull artifacts + first start
```

Boot-time startup on Android:

1. Install the **Termux:Boot** add-on from the same source as Termux itself
   (F-Droid/GitHub signatures differ), and open it once so the system
   registers the boot receiver.
2. Install the boot script:

   ```sh
   mkdir -p ~/.termux/boot
   cp ~/pai/scripts/termux-boot.sh ~/.termux/boot/pai.sh
   chmod +x ~/.termux/boot/pai.sh
   ```

   It takes a wake lock (Android freezes background processes without one),
   then sources `~/.bashrc` (boot scripts run under non-interactive `sh`, so
   API keys exported there would otherwise be missing — symptom: "No API key
   found" / empty model list) and starts the server headless. Edit the copied
   file to set your own `PI_WEB_TITLE_SUFFIX`. After a reboot the server is on
   `http://127.0.0.1:30141` within a minute or two.

Disk note: `~/pai` with `node_modules` is ~1.7 GB; only `npm install` needs
the toolchain, updates come from Releases and replace `.next` only.

## Browser-tab node identification

`PI_WEB_TITLE_SUFFIX` (read at request time via `/api/pai-title`, no rebuild
needed) appends a suffix to the tab title, e.g. `会话名 - PAI@vm_wujie_1`, so
several nodes open side by side stay distinguishable. Empty by default.

## License and attribution

MIT, and a derivative work of **[pi-web](https://github.com/agegr/pi-web)** by **agegr**,
whose copyright notice is reproduced in `LICENSE` as that license requires. The changes
carried here are © 2026 Perturbation AI, under the same terms.

The agent underneath is **[pi](https://github.com/earendil-works/pi)**
(`@earendil-works/pi-coding-agent`) by **Mario Zechner**, also MIT. It is a dependency
rather than something this build changes, and it is named here because it is what does the
work.

Neither project endorses this one. PAI is not official, and carries none of their marks.
