#!/usr/bin/env python3
"""SyncAccounts.py — merge SentiAccountInfoDB across WoW accounts on this PC.

WoW addons can only read their own account's SavedVariables
(WTF/Account/<name>/SavedVariables/). This script finds every account's
SentiAccountInfoDB.lua, merges the `chars` tables, stamps each character
with its home account folder, and writes the merged table back into every
account file — so all accounts see all characters.

Run after logging out (WoW writes SavedVariables on logout/reload).
Usage:
    python SyncAccounts.py [--wtf PATH_TO_WTF] [--dry-run]
"""

import argparse
import io
import re
import sys
from pathlib import Path

VAR_NAME = "SentiAccountInfoDB"


# ---------------------------------------------------------------------------
# Minimal parser/emitter for the Lua-table subset WoW writes in SavedVariables
# ---------------------------------------------------------------------------

class ParseError(Exception):
    pass


_TOKEN_RE = re.compile(
    r"""
    (?P<ws>[\s,;]+)
  | (?P<comment>--[^\n]*)
  | (?P<str>"(?:\\.|[^"\\])*")
  | (?P<num>-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)
  | (?P<name>[A-Za-z_][A-Za-z0-9_]*)
  | (?P<sym>.)
    """,
    re.VERBOSE,
)


def _tokenize(text):
    pos = 0
    while pos < len(text):
        m = _TOKEN_RE.match(text, pos)
        if not m:
            raise ParseError(f"unexpected char at {pos}")
        pos = m.end()
        kind = m.lastgroup
        if kind in ("ws", "comment"):
            continue
        yield kind, m.group(0)
    yield "eof", ""


def _unescape(s):
    out = io.StringIO()
    i = 1  # skip opening quote
    while i < len(s) - 1:
        c = s[i]
        if c == "\\":
            i += 1
            e = s[i]
            if e == "n":
                out.write("\n")
            elif e == "t":
                out.write("\t")
            elif e == "r":
                out.write("\r")
            elif e.isdigit():
                digits = e
                while i + 1 < len(s) - 1 and s[i + 1].isdigit() and len(digits) < 3:
                    i += 1
                    digits += s[i]
                out.write(chr(int(digits)))
            else:
                out.write(e)
            i += 1
        else:
            out.write(c)
            i += 1
    return out.getvalue()


def _escape(s):
    out = []
    for ch in s:
        if ch == '"':
            out.append('\\"')
        elif ch == "\\":
            out.append("\\\\")
        elif ch == "\n":
            out.append("\\n")
        elif ch == "\r":
            out.append("\\r")
        elif ch == "\t":
            out.append("\\t")
        elif ord(ch) < 0x20:
            out.append("\\%d" % ord(ch))
        else:
            out.append(ch)
    return '"' + "".join(out) + '"'


class _Parser:
    def __init__(self, text):
        self.tokens = list(_tokenize(text))
        self.i = 0
        self.array_index = 0  # implicit [n] keys inside a table

    def peek(self):
        return self.tokens[self.i]

    def next(self):
        tok = self.tokens[self.i]
        self.i += 1
        return tok

    def expect(self, kind, value=None):
        kind_got, value_got = self.next()
        if kind_got != kind or (value is not None and value_got != value):
            raise ParseError(f"expected {kind} {value}, got {kind_got} {value_got}")
        return value_got

    def parse_value(self):
        kind, value = self.peek()
        if kind == "str":
            self.next()
            return _unescape(value)
        if kind == "num":
            self.next()
            f = float(value)
            return int(f) if f.is_integer() and "." not in value and "e" not in value.lower() else f
        if kind == "name":
            self.next()
            if value == "true":
                return True
            if value == "false":
                return False
            if value == "nil":
                return None
            raise ParseError(f"unexpected name {value}")
        if value == "{":
            return self.parse_table()
        raise ParseError(f"unexpected token {kind} {value}")

    def parse_table(self):
        self.expect("sym", "{")
        result = {}
        outer_index, self.array_index = self.array_index, 0
        while True:
            kind, value = self.peek()
            if kind == "eof":
                raise ParseError("unclosed table")
            if value == "}":
                self.next()
                self.array_index = outer_index
                return result
            if value == "[":
                self.next()
                key = self.parse_value()
                self.expect("sym", "]")
                self.expect("sym", "=")
            else:
                # implicit array entry
                self.array_index += 1
                key = self.array_index
                result[key] = self.parse_value()
                continue
            result[key] = self.parse_value()


def _emit(value, out, indent):
    tab = "\t" * indent
    if isinstance(value, dict):
        if not value:
            out.write("{}")
            return
        out.write("{\n")
        for key in sorted(value, key=lambda k: (str(type(k)), str(k))):
            out.write(tab + "\t[")
            if isinstance(key, str):
                out.write(_escape(key))
            else:
                out.write(_emit_number(key))
            out.write("] = ")
            _emit(value[key], out, indent + 1)
            out.write(",\n")
        out.write(tab + "}")
    elif isinstance(value, str):
        out.write(_escape(value))
    elif isinstance(value, bool):
        out.write("true" if value else "false")
    elif isinstance(value, (int, float)):
        out.write(_emit_number(value))
    elif value is None:
        out.write("nil")
    else:
        raise ParseError(f"cannot emit {type(value)}")


def _emit_number(n):
    if isinstance(n, float) and n.is_integer():
        return str(int(n))
    return repr(n)


def parse_sv_file(path):
    """Parse 'SentiAccountInfoDB = {...}' from a SavedVariables file."""
    text = path.read_text(encoding="utf-8", errors="replace")
    m = re.search(r"SentiAccountInfoDB\s*=\s*", text)
    if not m:
        return None
    parser = _Parser(text[m.end():])
    value = parser.parse_value()
    return value if isinstance(value, dict) else None


def write_sv_file(path, data):
    out = io.StringIO()
    out.write("SentiAccountInfoDB = ")
    _emit(data, out, 0)
    out.write("\n")
    path.write_text(out.getvalue(), encoding="utf-8")


# ---------------------------------------------------------------------------
# Merge logic
# ---------------------------------------------------------------------------

def find_sv_files(wtf):
    """Yield (account_label, path) for every account's SentiAccountInfoDB.lua."""
    accounts = wtf / "Account"
    if not accounts.is_dir():
        return
    for folder in sorted(accounts.iterdir()):
        if not folder.is_dir() or folder.name == "SavedVariables":
            continue
        path = folder / "SavedVariables" / f"{VAR_NAME}.lua"
        if path.is_file():
            yield folder.name, path


def merge(files):
    """Parse all files, merge chars, stamp home account. Returns per-file
    merged tables and a summary. Unparseable files are skipped."""
    parsed = {}   # path -> (account_label, data)
    for label, path in files:
        try:
            data = parse_sv_file(path)
        except (ParseError, OSError) as exc:
            print(f"  !! skipping {path}: {exc}", file=sys.stderr)
            continue
        if data is not None:
            parsed[path] = (label, data)

    # Collect every char; home account = stamped account or the file where
    # the record has no account/imported flags (its own scan).
    all_chars = {}
    for path, (label, data) in parsed.items():
        for key, char in (data.get("chars") or {}).items():
            if not isinstance(char, dict):
                continue
            if char.get("account") in (None, "") and not char.get("imported"):
                char["account"] = label
            existing = all_chars.get(key)
            if existing is None:
                all_chars[key] = char
            else:
                # Prefer the record with the newer `updated` timestamp.
                if (char.get("updated") or 0) > (existing.get("updated") or 0):
                    all_chars[key] = char

    changed = {}
    for path, (label, data) in parsed.items():
        chars = {}
        for key, char in all_chars.items():
            entry = dict(char)
            home = entry.get("account") or ""
            if home and home != label:
                entry["imported"] = True
            elif home == label:
                entry.pop("imported", None)
            chars[key] = entry
        merged = dict(data)
        merged["chars"] = chars
        changed[path] = merged
    return changed, all_chars


def main():
    here = Path(__file__).resolve()
    # .../WoW/Interface/AddOns/SentiAccountInfo/Tools/SyncAccounts.py
    # parents: [0]Tools [1]SentiAccountInfo [2]AddOns [3]Interface [4]WoW root
    default_wtf = here.parents[4] / "WTF" if len(here.parents) > 4 else None
    ap = argparse.ArgumentParser(description="Merge SentiAccountInfoDB across WoW accounts.")
    ap.add_argument("--wtf", type=Path, default=default_wtf,
                    help="path to the WTF folder (default: ../../../WTF)")
    ap.add_argument("--dry-run", action="store_true",
                    help="show what would be merged without writing")
    args = ap.parse_args()

    wtf = args.wtf
    if not wtf or not wtf.is_dir():
        print(f"WTF folder not found: {wtf}", file=sys.stderr)
        print("Pass it explicitly: python SyncAccounts.py --wtf \"D:/WoW/World of Warcraft/_forever_/WTF\"",
              file=sys.stderr)
        return 1

    files = list(find_sv_files(wtf))
    if len(files) < 2:
        print(f"Found {len(files)} SentiAccountInfoDB file(s) under {wtf/'Account'}")
        print("Nothing to merge — log in on at least two accounts first.")
        return 0

    print(f"Found {len(files)} account file(s):")
    for label, path in files:
        print(f"  {label}: {path}")

    changed, all_chars = merge(files)
    print(f"Merged {len(all_chars)} character(s) total")

    for path, data in changed.items():
        label = path.parents[1].name
        own = sum(1 for c in data["chars"].values() if not c.get("imported"))
        foreign = len(data["chars"]) - own
        print(f"  {label}: {len(data['chars'])} chars ({own} own, {foreign} imported)")
        if not args.dry_run:
            backup = path.with_suffix(".lua.bak")
            try:
                backup.write_text(path.read_text(encoding="utf-8"), encoding="utf-8")
                write_sv_file(path, data)
            except OSError as exc:
                print(f"  !! writing {path} failed: {exc}", file=sys.stderr)
                return 1

    print("Done." if not args.dry_run else "Dry run — no files written.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
