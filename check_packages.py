"""Check that a `pip list` output satisfies the `pip install` lines of a common.sh.

Usage: python3 check_packages.py <common.sh> <packages.txt>

Exits 0 when every package installed by common.sh is in packages.txt and satisfies its version spec
(==, !=, >=, <=, >, <); otherwise prints each mismatch and exits 1. Only the two text files are read:
nothing is looked up in the python environment this script runs in.
"""

import re
import shlex
import sys

# options of `pip install` that take a value: the value is not a package
TAKES_VALUE = {"-i", "--index-url", "--extra-index-url", "-f", "--find-links", "-c", "--constraint"}
SPEC_RE = re.compile(r"(==|!=|>=|<=|>|<)\s*([^,\s]+)")
REQ_RE = re.compile(r"([A-Za-z0-9][A-Za-z0-9._-]*)(\[[^\]]*\])?((?:\s*(?:==|!=|>=|<=|>|<)\s*[^,\s]+\s*,?)*)")


def norm(name):
    # pip treats -, _ and . alike and ignores case
    return re.sub(r"[-_.]+", "-", name).lower()


def vkey(v):
    # numeric release parts: 4.39 -> (4, 39), 2.1.0+cu121 -> (2, 1, 0)
    m = re.match(r"\d+(\.\d+)*", v)
    return tuple(int(p) for p in m.group(0).split(".")) if m else ()


def satisfies(have, op, want):
    a, b = vkey(have), vkey(want)
    n = max(len(a), len(b))
    a, b = a + (0,) * (n - len(a)), b + (0,) * (n - len(b))
    return {"==": a == b, "!=": a != b, ">=": a >= b, "<=": a <= b, ">": a > b, "<": a < b}[op]


def read_installed(path):
    # pip list: "Package  Version" header, a dashes line, then "<name> <version> [location]"
    installed = {}
    with open(path) as f:
        for line in f:
            parts = line.split()
            if len(parts) >= 2 and parts[0] != "Package" and not parts[0].startswith("-"):
                installed[norm(parts[0])] = parts[1]
    return installed


def read_requirements(path):
    # yields the package tokens of every `pip install` line, options and their values dropped
    with open(path) as f:
        for line in f:
            m = re.match(r"\s*pip3?\s+install\s+(.*)", line.split("#", 1)[0])
            if not m:
                continue
            toks = iter(shlex.split(m.group(1)))
            for t in toks:
                if t.startswith("-"):
                    if t in TAKES_VALUE:
                        next(toks, None)
                    continue
                yield t


def main(common_sh, packages_txt):
    installed = read_installed(packages_txt)
    bad = []
    for req in read_requirements(common_sh):
        m = REQ_RE.fullmatch(req)
        if not m:
            bad.append(f"cannot check {req}")
            continue
        name = norm(m.group(1))
        if name not in installed:
            bad.append(f"missing {name}")
            continue
        for op, want in SPEC_RE.findall(m.group(3)):
            if not satisfies(installed[name], op, want):
                bad.append(f"{name} {installed[name]} does not satisfy {op}{want}")
    for b in bad:
        print("packages check:", b)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1], sys.argv[2]))
