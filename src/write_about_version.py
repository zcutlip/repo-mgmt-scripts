#!/usr/bin/env python3

"""Write __version__ to a package __about__.py without disturbing the rest.

Usage: write_about_version.py <path-to-__about__.py> <new-version>

AST-parses the file, locates the first string assignment to __version__
(plain or annotated), and replaces only that value's source span. Every
other byte — docstring, other assignments, comments, quoting, trailing
newline state — is preserved verbatim.

Exits nonzero when the file cannot be parsed or contains no string
__version__ assignment.

Deliberately avoids importing the target package: version writes must not
execute package __init__ code or require third-party dependencies.
"""

import ast
import sys


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: write_about_version.py <path> <new-version>", file=sys.stderr)
        return 2
    path = sys.argv[1]
    new_version = sys.argv[2]
    try:
        with open(path, encoding="utf-8") as handle:
            source = handle.read()
    except OSError as exc:
        print(f"cannot read {path}: {exc}", file=sys.stderr)
        return 1
    try:
        tree = ast.parse(source, filename=path)
    except SyntaxError as exc:
        print(f"cannot parse {path}: {exc}", file=sys.stderr)
        return 1
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign):
            targets = node.targets
            value = node.value
        elif isinstance(node, ast.AnnAssign):
            targets = [node.target]
            value = node.value
        else:
            continue
        if value is None:
            continue
        names = [t.id for t in targets if isinstance(t, ast.Name)]
        # The splice below treats the value's span as line-relative, which
        # only holds for a value on a single line. A triple-quoted value
        # spanning multiple lines has no single-line span to replace; skip
        # it (and any other non-constant) so the file is never mis-spliced
        # and the call falls through to the missing-assignment error.
        if (
            "__version__" in names
            and isinstance(value, ast.Constant)
            and isinstance(value.value, str)
            and value.end_col_offset is not None
            and value.end_lineno == value.lineno
        ):
            # col_offset is line-relative; convert to absolute file offset
            # using the node's line number.
            lines = source.splitlines(keepends=True)
            line_start = sum(len(lines[i]) for i in range(value.lineno - 1))
            start = line_start + value.col_offset
            end = line_start + value.end_col_offset
            replacement = f'"{new_version}"'
            new_source = source[:start] + replacement + source[end:]
            try:
                with open(path, "w", encoding="utf-8") as handle:
                    handle.write(new_source)
            except OSError as exc:
                print(f"cannot write {path}: {exc}", file=sys.stderr)
                return 1
            return 0
    print(f"no __version__ assignment found in {path}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
