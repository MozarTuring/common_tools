"""Download and extract arXiv sources into /Users/jinma63/project/paper_reading/pkq_citations/<Title_With_Underscores>/.

Usage:
    python3 -I /Users/jinma63/project/common_tools/arxiv_fetch.py 2610.03938 2609.35117 ...
    python3 -I /Users/jinma63/project/common_tools/arxiv_fetch.py 2610.03938 --name Custom_Folder_Name
    python3 -I /Users/jinma63/project/common_tools/arxiv_fetch.py --placeholder 2610.03938 2609.35117 ...
    python3 -I /Users/jinma63/project/common_tools/arxiv_fetch.py Folder_Name_Of_A_Placeholder ...

The folder name is built from the arXiv title (characters other than letters, digits and '-' become '_').
Every created folder gets an arxiv_id.txt holding the id. With --placeholder only the folder and arxiv_id.txt
are created (no download); a placeholder folder (or its path) can later be passed instead of the id to download it.
A paper is skipped if a non-placeholder folder with that name already exists anywhere under paper_reading/
(up to 3 levels deep); with --placeholder, an existing placeholder also counts.
Sources are extracted (tar.gz, or a single gzipped .tex saved as main.tex); PDF-only submissions are saved as <folder>.pdf.
The downloaded archive is deleted after extraction. The last output line per paper is `<id>\t<status>\t<folder>`,
where the folder name is what goes into `\\bibitem{key} \\path{<folder>}`.
"""

import argparse
import gzip
import io
import os
import re
import sys
import tarfile
import time
import urllib.request
import xml.etree.ElementTree as ET

PAPER_READING = "/Users/jinma63/project/paper_reading"
DEST_ROOT = os.path.join(PAPER_READING, "pkq_citations")
UA = {"User-Agent": "Mozilla/5.0 (arxiv-fetch)"}
ID_FILE = "arxiv_id.txt"
ARXIV_ID = re.compile(r"\d{4}\.\d{4,5}(v\d+)?|[a-z-]+(\.[A-Z]{2})?/\d{7}(v\d+)?")


def get(url):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=120) as r:
        return r.read()


def arxiv_title(arxiv_id):
    data = get(f"http://export.arxiv.org/api/query?id_list={arxiv_id}")
    ns = {"a": "http://www.w3.org/2005/Atom"}
    entry = ET.fromstring(data).find("a:entry", ns)
    title = entry.find("a:title", ns) if entry is not None else None
    if title is None or not title.text or title.text.strip() == "Error":
        raise ValueError(f"no title found for {arxiv_id}")
    return " ".join(title.text.split())


def folder_name(title):
    name = re.sub(r"[^A-Za-z0-9-]+", "_", title)
    return re.sub(r"_+", "_", name).strip("_")


def norm(name):
    return name.lower().replace("-", "_")


def is_placeholder(path):
    return [f for f in os.listdir(path) if not f.startswith(".")] == [ID_FILE]


def find_existing(name, include_placeholders=False):
    target = norm(name)
    base_depth = PAPER_READING.rstrip("/").count("/")
    for root, dirs, _ in os.walk(PAPER_READING):
        for d in dirs:
            if norm(d) == target:
                path = os.path.join(root, d)
                if os.listdir(path) and (include_placeholders or not is_placeholder(path)):
                    return path
        if root.count("/") - base_depth >= 2:
            dirs[:] = []
    return None


def safe_extract(tar, dest):
    dest_abs = os.path.realpath(dest)
    members = []
    for m in tar.getmembers():
        if m.issym() or m.islnk() or m.isdev():
            continue
        target = os.path.realpath(os.path.join(dest, m.name))
        if not (target == dest_abs or target.startswith(dest_abs + os.sep)):
            continue
        members.append(m)
    if hasattr(tarfile, "data_filter"):
        tar.extractall(dest, members=members, filter="data")
    else:
        tar.extractall(dest, members=members)


def unpack(data, dest, name):
    if data[:4] == b"%PDF":
        with open(os.path.join(dest, f"{name}.pdf"), "wb") as f:
            f.write(data)
        return "pdf"
    raw = gzip.decompress(data) if data[:2] == b"\x1f\x8b" else data
    try:
        with tarfile.open(fileobj=io.BytesIO(raw)) as tar:
            safe_extract(tar, dest)
        return "source"
    except tarfile.ReadError:
        with open(os.path.join(dest, "main.tex"), "wb") as f:
            f.write(raw)
        return "source(single tex)"


def resolve(arg):
    arg = re.sub(r"^(https?://arxiv\.org/(abs|pdf|e-print)/)", "", arg).removesuffix(".pdf")
    if ARXIV_ID.fullmatch(arg):
        return arg, None
    path = arg if os.path.isdir(arg) else os.path.join(DEST_ROOT, arg)
    with open(os.path.join(path, ID_FILE)) as f:
        return f.read().strip(), os.path.basename(os.path.normpath(path))


def fetch(arxiv_id, name=None, placeholder=False):
    name = name or folder_name(arxiv_title(arxiv_id))
    existing = find_existing(name, include_placeholders=placeholder)
    if existing:
        return "exists", os.path.basename(existing), existing
    dest = os.path.join(DEST_ROOT, name)
    os.makedirs(dest, exist_ok=True)
    with open(os.path.join(dest, ID_FILE), "w") as f:
        f.write(arxiv_id + "\n")
    if placeholder:
        return "placeholder", name, dest
    archive = os.path.join(dest, "src.archive")
    with open(archive, "wb") as f:
        f.write(get(f"https://arxiv.org/e-print/{arxiv_id}"))
    with open(archive, "rb") as f:
        data = f.read()
    try:
        status = unpack(data, dest, name)
    finally:
        os.remove(archive)
    return status, name, dest


def main():
    p = argparse.ArgumentParser()
    p.add_argument("ids", nargs="+", help="arXiv ids/URLs, or names/paths of placeholder folders")
    p.add_argument("--name", help="folder name override (only with a single id)")
    p.add_argument("--placeholder", action="store_true", help="create the folder and arxiv_id.txt only, no download")
    args = p.parse_args()
    if args.name and len(args.ids) > 1:
        sys.exit("--name works with a single id only")
    failed = False
    for i, arg in enumerate(args.ids):
        arxiv_id = arg
        try:
            arxiv_id, folder = resolve(arg)
            status, name, path = fetch(arxiv_id, args.name or folder, args.placeholder)
            print(f"{arxiv_id}\t{status}\t{name}\t{path}")
        except Exception as e:
            failed = True
            print(f"{arxiv_id}\tERROR\t{e}", file=sys.stderr)
        if i + 1 < len(args.ids):
            time.sleep(3)
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
