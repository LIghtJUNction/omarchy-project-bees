# Project Bees for Omarchy

![Project Bees dashboard with synthetic repository data](https://github.com/LIghtJUNction/omarchy-project-bees/releases/download/v0.1.2/dashboard.jpg)

A native dashboard for [project-bees](https://github.com/LIghtJUNction/project-bees).
The bar shows cumulative newly shared data. Click it to view size-ranked
repository and pair lists, filter paths, and see each pair's direction totals.
The panel follows Omarchy's theme, text size, corner radius, and selected
language. Its interface is translated into all 50 Omarchy languages.

## Install

Requires Omarchy 4.5 or later and project-bees 0.1 or later. Activity reporting
requires project-bees 0.1.1 or later. On Arch and Omarchy:

```sh
yay -S project-bees
systemctl --user enable --now project-bees.service
omarchy plugin add https://github.com/LIghtJUNction/omarchy-project-bees --enable
```

The dashboard opens from its bar widget or from
`omarchy-shell shell summon io.github.lightjunction.project-bees`.

| Control | Action |
| --- | --- |
| Bar widget | Toggle the dashboard |
| Search field | Filter repository paths in the current list |
| Repositories / Repository pairs | Switch between destination totals and pair totals |
| Esc, close button, or outside click | Close the dashboard |

## Languages

Choose a language in Omarchy's **Setup > Language** menu. The dashboard and
bar widget update immediately, including number and date formatting. Arabic,
Hebrew, Persian, and Urdu mirror the interface; repository paths and pair
directions keep their left-to-right order.

Translation catalogs live in `i18n/`. Each catalog contains the same 21 keys
as `en.json`, with numbered placeholders preserved. Omarchy falls back to English
for an unknown language or a missing translation.

## Activity

The status line shows the latest reported phase: indexing, deduplicating,
waiting for the next scan, or stopped. During indexing it shows files read
and chunks indexed; during deduplication it shows files checked and ranges
matched. These counters describe the current pass, while the large newly
shared total keeps its history.

The daemon finishes indexing before it starts deduplication. On the first
pass, the total can remain zero while indexing progresses. No percentage or
remaining-time estimate is shown because the complete workload is not known.
An old active snapshot shows its age instead of an active phase. A snapshot
without activity data still displays its totals and reports progress as
unavailable.

## Data access

The widget reads `${XDG_STATE_HOME:-$HOME/.local/state}/project-bees/stats.json`.
It does not launch processes, access the network, or change shell settings.
The daemon counts logical bytes whose allocated destination ranges became
shared. Project totals are assigned to destination repositories. Pair totals
include both directions, and the source subtotals show where the data came from.
The measurement starts when the stats-enabled daemon first runs.
Already shared ranges add zero. These lifetime counters describe logical
bytes newly shared by the daemon; filesystem compression, snapshots, and
later writes affect the physical space available on disk.

The snapshot updates atomically. The plugin reloads it when the file changes
and every 30 seconds. Missing statistics show a waiting state; invalid or
unsupported snapshots show an error and clear the previous values. Paths are
rendered as plain text. Invalid UTF-8 path bytes are displayed as U+FFFD, while
the daemon keeps the original bytes in its private index.

## Remove

```sh
omarchy plugin remove io.github.lightjunction.project-bees --yes
```

The daemon and its history are separate from the dashboard.

## Development

This repository is also pinned as the `plugins/project-bees` Git submodule in
the daemon repository. Validate its manifest before installing an edit:

```sh
omarchy plugin validate .
```

MIT license.
