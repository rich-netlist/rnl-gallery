# Contributing

You add a design by adding one small file. You do not copy the design into this repository.

1. Find the design in a **public GitHub repository** with an accepted licence ([README](README.md#licences)). It need not be yours.
2. Take the **full commit id** you want to show: `git rev-parse HEAD` in a clone, or the commit page on GitHub.
3. Create `entries/<id>.json`. The id is the name in the gallery's addresses: lower case letters, digits and hyphens, 2 to 63 characters. On GitHub you can do this on the web page of the repository, with *Add file*; GitHub opens the pull request for you.
4. Fill in what [the README](README.md#add-a-design) lists: at least `title`, `description`, `author`, `source` and `entry`. Add `paths`, `add` and `packages` only when the netlist does not read cleanly without them, and `level` to choose the picture.
5. Open the pull request, tick the boxes of its description, and wait for the checks. They report errors in the files themselves (a netlist `rnl check` rejects, a missing include or package) and the licence. The run keeps the thumbnails and manifests as an artifact, `gallery-preview`: download it and look at the thumbnail.
6. A maintainer reviews the entry, and merges it. It appears in the gallery a few minutes later.

To **change** an entry, for example to show a newer commit of the design, edit its file in a pull request. If you change the English of its `title` or `description`, change their translations too, or remove them; the checks warn of a translation left as it was, and do not fail. To **remove** one, delete the file in a pull request, or open an issue.

A design that is not in a public repository, or whose licence the checks refuse, can be made an example of this repository instead, in `examples/<id>/` with an entry without `source`, a `license` in the entry and the text of that licence in `examples/<id>/LICENSE`: ask in an issue first.

To try an entry before pushing, see "Build it here" in the [README](README.md#build-it-here).

Pull requests go to `main`; the checks fail otherwise.
