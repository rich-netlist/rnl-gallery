# RNL 图库

[English](README.md)

用 [RNL](https://github.com/rich-netlist/rnl)（Rich Netlist）画出原理图的电路例子，显示在项目网站上：<https://rich-netlist.github.io/rnl/gallery.html>。

图库是一张**列表**。每个条目指向某个公开 GitHub 仓库里的一个设计，固定在某一个提交上；设计本身不复制到这里。点开一个条目，就用[网页版 Viewer](https://rich-netlist.github.io/rnl/viewer/)打开那个提交里的文件。我们自己的例子放在本仓库的 `examples/` 里，也只是列表里的条目。

## 加一个设计

提一个 PR，只加一个文件 `entries/<id>.json`（见 [CONTRIBUTING.md](CONTRIBUTING.md)）。设计的作者不用做任何事：只要仓库是公开的、许可证允许（见下），任何人都可以推荐。

```json
{
  "title": {"en": "Phase-locked loop", "zh": "锁相环"},
  "description": {"en": "A hierarchical PLL …", "zh": "…"},
  "author": "Name",
  "source": {"repo": "owner/name", "commit": "<完整的 40 位提交号>"},
  "entry": "top.scs",
  "paths": ["cells"],
  "add": ["models/"],
  "packages": [{"name": "eda-symbol", "version": "0.3"}, {"path": "semantics.rnl"}],
  "tags": ["pll", "mixed-signal"],
  "cover": {"cell": "lc_vco", "view": "schematic"}
}
```

| 字段 | 说明 |
| --- | --- |
| `title`、`description`、`author` | 图库上显示的内容。`title`、`description` 必须有 `en`，可以再加 `zh` 等。 |
| `license` | 别的仓库里的设计可以不写（不写就读它仓库的许可证）；放在本仓库里的例子必须写。从下面的清单里选一个 SPDX 名。见[许可证](#许可证)。 |
| `source` | 仓库（GitHub 上的 `owner/name`）和**完整的提交号**：不能写分支或标签，这样显示的永远是审核过的那一版。本仓库 `examples/<id>/` 里的例子不写 `source`。 |
| `entry` | Viewer 打开的网表（SPICE：`.sp`、`.spi`、`.cir`、`.net`；Spectre：`.scs`），相对仓库根目录。 |
| `paths` | 只写了文件名的 include 在哪些目录里找，按顺序；默认是入口所在的目录。 |
| `add` | 除了网表 include 到的文件，还要带上的文件或目录（目录连同它下面的一起）。很少需要：网表 include 的文件会通过读它自动找到。 |
| `packages` | 要载入的包：`{"name", "version"}` 是[公开目录](https://rich-netlist.github.io/rnl-packages/catalog.json)里的包，`{"path"}` 是仓库里的包文件，`{"url"}` 是 raw.githubusercontent.com 的地址。标准包不用写。 |
| `tags` | 最多 8 个标签，小写字母、数字和连字符，用来找到这个设计；图库页可以按标签筛选。自由填写，建议用[推荐标签](#标签)，这样同一件事的标签一致。 |
| `formats` | 要手动指定读法的文件：`{"models/n.lib": "spectre"}`，设计里的一个文件，值是 `"spice"` 或 `"spectre"`。只写核心会猜错的文件（核心按后缀和开头几行猜）；不需要就不写。检查和查看器都按这些格式读文件。 |
| `cover` | 缩略图画什么，也是查看器先打开的：`{"cell": "lc_vco", "view": "schematic"}`，或 `"view": "symbol"` 表示这个单元的符号（这个单元自己的块符号，网表里要定义了它）。`cell` 是子电路名，或 `"(top)"` 表示网表自己这一层；`view` 不写就是 `"schematic"`；不写 `cell` 就是第一张有内容的层。请选最能代表这个设计的。 |
| `level` | `{"cover": {"cell": …}}`（原理图）的旧写法；不能和 `cover` 一起写。 |

### 标签

推荐的标签，让同一件事用同一个标签：`amplifier`、`opamp`、`ota`、`comparator`、`bandgap`、`reference`、`bias`、`ldo`、`power`、`oscillator`、`vco`、`pll`、`adc`、`sar-adc`、`dac`、`filter`、`switched-capacitor`、`mixed-signal`、`digital`、`rf`、`lna`、`mixer`、`hierarchical`、`transistor-level`、`virtuoso-export`。别的标签也可以，检查只看格式。

## 检查做什么

PR 上和合并之后，`tools/build.mjs` 对每个条目：

1. 找出设计的许可证，不在接受清单里就拒绝（见下）：放在本仓库里的例子，看条目的 `license`，它必须和目录里 `LICENSE` 文件的许可证一致；别的仓库里的设计，看仓库的许可证，条目写了 `license` 就以它为准；
2. 列出那个提交的文件，取网表需要的：入口、它 include 的、包、`paths` 和 `add` 指的；
3. 用和 Viewer 同一个核心（`@rich-netlist/runtime`，WebAssembly）读这些文件：**有错误就不通过**，警告只显示；
4. 画缩略图（PNG，宽 640 像素）：选定单元的原理图，或它的符号；
5. 给条目写一份"清单"：每个文件的地址和 SHA-256、只写文件名的 include 的搜索顺序、包和层。Viewer 按清单打开条目，并逐个文件核对。

合并后的结果发布在本仓库的 GitHub Pages 上：`index.json`、`manifests/<id>.json` 和 `thumbs/…png`，地址是 <https://rich-netlist.github.io/rnl-gallery/>。网站读那里的 `index.json` 和缩略图，所以新条目合并几分钟后就出现，不用改网站。只用 GitHub 的静态文件：没有服务器，浏览器里也不调用 GitHub API。

限制：每个条目最多 300 个文件，单个不超过 2 MB，合计不超过 20 MB。只支持 GitHub 上的公开仓库：别的托管站点没有发浏览器跨站读文件所需的响应头。

## 许可证

**每个设计有自己的许可证**，卡片上会和作者的名字一起显示。

- **放在本仓库里的例子**（`examples/<id>/`）有自己的 `LICENSE` 文件，里面是许可证的文本，条目的 `license`（SPDX 名）写明是哪个，检查会核对两者。这类例子只接受几种许可证（CC0-1.0、CC-BY-4.0、CC-BY-SA-4.0、MIT、Apache-2.0、Unlicense），这样才能认出文本。
- **别的仓库里的设计**按那个仓库的许可证：检查读取仓库的许可证。条目写了 `license` 的，卡片显示它，由审核人对照仓库核对（用于：仓库里某个设计有自己的许可证、而仓库是另一个；或者 GitHub 认不出的许可证）。

图库会为每个设计生成并发布一张图，所以只收许可证允许这样做的设计：CC0-1.0、CC-BY-4.0、CC-BY-SA-4.0、MIT、MIT-0、BSD-2-Clause、BSD-3-Clause、ISC、Apache-2.0、Unlicense、MPL-2.0、0BSD、Zlib，以及 GPL、LGPL、AGPL 系列。**没有许可证**（保留所有权利）、非商业或禁止演绎的许可证、自定义许可证的设计，检查会拒绝。清单在 `tools/lib/license.mjs`。设计的文件仍按它的许可证，Viewer 直接从它所在的地方读。

**撤下条目**：设计的所有者或有理由的人，可以开 issue 要求撤下。条目会被删除，缩略图和清单在下一次发布时一起消失。

受保密协议约束的内容、不允许公开的工艺数据，不能放在这里，也不能放在条目指向的仓库里。

## 本仓库的文件

| 路径 | 说明 |
| --- | --- |
| `entries/<id>.json` | 列表：一个条目一个文件。 |
| `examples/<id>/` | 放在这里的例子的文件。它们是没有 `source` 的条目，路径相对这个目录。 |
| `schema/entry.schema.json` | 条目的 JSON Schema，给编辑器用。检查实际运行的是 `tools/lib/entry.mjs`。 |
| `tools/` | 检查和构建（Node，MIT 许可证，见下）。 |
| `.github/workflows/` | `check.yml`（PR 上）、`pages.yml`（合并后和每晚）。 |

### 在本机构建

Node 22 或更新。核心和栅格化库来自 npm，字体下载后核对固定的 SHA-256。

```bash
npm ci --prefix tools
node --test tools/test.mjs
GITHUB_TOKEN=… node tools/build.mjs --out dist     # 令牌可不给；只是放宽 API 的频率限制
```

`--only id,id` 只构建某几个条目。`RNL_GALLERY_LOCAL` 是一个 JSON 对象（文本或文件路径），从 `"owner/name"` 到 `{"dir": "…", "license": "CC0-1.0"}`：这些仓库改为从该目录读取，用来在推送前试一个条目。

## 本仓库的许可证

按 [REUSE](https://reuse.software) 的做法：[`REUSE.toml`](REUSE.toml) 写明每个路径的许可证，文本在 [`LICENSES/`](LICENSES)。`tools/` 里的代码和工作流按 MIT；条目、schema 和文档按 CC0-1.0；每个例子按它自己目录的许可证，见上。
