# omarchy-print-queue

A hidden CUPS print-queue widget for the [Omarchy](https://omarchy.org) status bar.

The widget stays out of the way while the queue is empty and shows up the
moment you send something to print: a printer icon plus the number of pending
jobs. Click it to open a panel with every job (printer, job number, timestamp,
size), cancel a single job or the whole queue.

- Polls `lpstat` every 3 seconds (configurable, 2–300)
- Panel keyboard: `r` refresh, `Esc` close
- UI language follows your system locale (English / Spanish, English fallback)
- Hides itself again as soon as the queue is empty
- Needs CUPS (`lpstat` and `cancel` on `PATH`), standard on Arch

## Install

```bash
omarchy plugin add https://github.com/Frank3e/omarchy-print-queue.git --enable
```

The installer asks which bar section to place it in (manifest default:
`right`). To place or move it manually later:

```bash
omarchy bar put frank3e.print-queue --section right
```

## Settings

Optional, in the widget entry inside `~/.config/omarchy/shell.json`:

```json
{ "id": "frank3e.print-queue", "refreshIntervalSec": 5 }
```

`refreshIntervalSec` — how often the queue is polled (seconds, default `3`).

## Uninstall

```bash
omarchy plugin remove frank3e.print-queue
```

## License

MIT
