# Project Bees for Omarchy

<img src="assets/logo.svg" alt="Project Bees honeycomb logo" width="104">

See what [project-bees](https://github.com/LIghtJUNction/project-bees) is doing
from your Omarchy bar. Open the native panel to follow the current scan
directory, priority or full scan pass, file counts, and live activity log.
Progress entries appear during indexing; successful sharing records show
which files began sharing storage and how many bytes were newly shared.
Searchable repository and pair lists keep the cumulative history visible.

The background service asks Btrfs to share physical storage for identical
file ranges after the kernel compares their contents. File names and contents
stay intact, and later writes use copy-on-write. This plugin displays the
service's local statistics. Its lifetime counter measures newly shared
logical bytes; current free disk space also depends on compression,
snapshots, and later writes.

The panel follows Omarchy's theme, text size, corner radius, and language.
The skipped-range counter is translated into all 50 Omarchy languages. Some
of the other live log labels use English outside the Chinese locales.

**简介：** 在 Omarchy 状态栏中查看 Project Bees 的扫描目录、处理计数和运行日志。
扫描进度与真正新增的共享量分别标明。后台服务让相同内容共用 Btrfs 数据块，
文件名称与内容保持不变；插件只读统计，安装启用后无需额外配置。

## Install

Install and enable the plugin with Omarchy's
[standard plugin command](https://omarchy.org/manual/shell-plugins/#adding-a-plugin-from-git):

```sh
omarchy plugin add https://github.com/LIghtJUNction/omarchy-project-bees.git --enable
```

No additional plugin configuration is required. The enabled plugin reads
the service's standard statistics file automatically.

**Prerequisites:** Omarchy 4.5 or later and a running
[project-bees service](https://github.com/LIghtJUNction/project-bees#install-on-arch-linux).
Use project-bees 0.1.3 or later for scan progress and sharing-log features.
The skipped-range counter requires project-bees 0.1.7 or later. You can
[build the daemon from source](https://github.com/LIghtJUNction/project-bees#build-and-run)
if your package is older.
The service is a separate dependency; the plugin does not install or start it.
If statistics are not available yet, the panel shows a waiting state.
Older service versions can still display their supported statistics.

The dashboard opens from its bar widget or from
`omarchy-shell shell summon io.github.lightjunction.project-bees`.

| Control | Action |
| --- | --- |
| Bar widget | Toggle the dashboard |
| Search field | Filter paths in the current list, including scan directories and both sides of a sharing record |
| Deduplication log / Repositories / Repository pairs | Switch between the live activity log and cumulative totals |
| Esc, close button, or outside click | Close the dashboard |

## Languages

Choose a language in Omarchy's **Setup > Language** menu. The dashboard and
bar widget update immediately, including number and date formatting. Arabic,
Hebrew, Persian, and Urdu mirror the interface; repository paths and pair
directions keep their left-to-right order.

Translation catalogs live in `i18n/`. Each catalog contains the same keys as
`en.json`, with numbered placeholders preserved. Omarchy falls back to English
for an unknown language or a missing translation.

## Activity

The progress area shows the latest reported phase: indexing, deduplicating,
waiting for the next scan, or stopped. It displays visited files, files read,
content blocks indexed, and files checked for deduplication. When the daemon
provides them, it also shows the priority or full scan pass, the current
directory, and the time spent in the current phase. These counters describe
the current pass, while the large newly shared total keeps its history.
During deduplication, the skipped-range counter shows ranges that already
shared the same Btrfs blocks. Progress rows retain this count when reported.

The daemon indexes a scan range before deduplicating its matches. With a
priority scan, high-priority ranges can produce sharing records before the
full scan finishes. During indexing, the total can remain unchanged while
file counts grow. No percentage or
remaining-time estimate is shown because the complete workload is not known.
An old active snapshot shows its age instead of an active phase. A snapshot
without activity data still displays its totals and reports progress as
unavailable. Older activity snapshots remain usable without the new optional
scan fields.

The default **Deduplication log** tab shows the latest real activity snapshot
immediately, including while the first directory is still being indexed.
Progress rows show the reported phase, scan directory, file and block counts,
and snapshot time. Changes are retained as up to 32 in-memory progress rows;
re-reading an unchanged snapshot adds no duplicate row. This history resets
when the shell restarts and is not written to disk.

Up to 32 successful sharing records from the daemon appear in the same
chronological list, newest first. They are labeled **Newly shared** and show
the source, destination, time, and positive newly shared logical bytes.
Progress rows are separately labeled **Progress** and never claim shared
bytes. Consecutive ranges from the same file pair may be combined by the
daemon. These sharing records survive scan-phase changes and reset when the
daemon restarts; cumulative totals remain persistent. The combined list has
at most 64 rows. Older daemons with activity reporting still produce progress
rows without the optional successful-sharing log.

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
and every 10 seconds. The daemon publishes progress and new records in
batches, so the panel follows the latest snapshot rather than each kernel
operation. Missing statistics show a waiting state; invalid or
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

## Visual identity

The two honeycomb cells share one edge, reflecting the way identical file
ranges share storage. The editable mark is in `assets/logo.svg`; the root
`preview.webp` is the compact raster preview supported by the marketplace.
Its vector source is in `assets/marketplace-preview.svg`.
