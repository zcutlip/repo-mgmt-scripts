#!/usr/bin/env python3

"""Read __version__ from a package __about__.py without importing it.

Usage: python3 read_about_version.py <path-to-__about__.py>

AST-parses the file and prints the first string assigned to __version__
(plain or annotated assignment). Exits nonzero when the file cannot be
parsed or contains no string __version__ assignment.

Deliberately avoids importing the target package: version reads must not
execute package __init__ code or require third-party dependencies.
"""

import ast
import sys


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: read_about_version.py <path-to-__about__.py>", file=sys.stderr)
        return 2
    path = sys.argv[1]
    try:
        with open(path, encoding="utf-8") as handle:
            tree = ast.parse(handle.read(), filename=path)
    except (OSError, SyntaxError) as exc:
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
        if (
            "__version__" in names
            and isinstance(value, ast.Constant)
            and isinstance(value.value, str)
        ):
            print(value.value)
            return 0
    print(f"no __version__ assignment found in {path}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
