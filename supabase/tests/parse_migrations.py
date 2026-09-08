"""Parse migrations with PostgreSQL's libpg_query grammar (via pglast)."""

from __future__ import annotations

import re
import sys
from pathlib import Path

from pglast.parser import ParseError, parse_plpgsql_json, parse_sql


def plpgsql_functions(source: str):
    pattern = re.compile(
        r"(?P<statement>create\s+(?:or\s+replace\s+)?function\b.*?"
        r"(?P<tag>\$[A-Za-z0-9_]*\$).*?(?P=tag)\s*;)",
        re.DOTALL | re.IGNORECASE,
    )
    for match in pattern.finditer(source):
        statement = match.group("statement")
        if re.search(r"language\s+plpgsql", statement, re.IGNORECASE):
            yield match.start("statement"), statement


def main() -> int:
    root = Path(__file__).resolve().parents[1] / "migrations"
    files = sorted(root.glob("*.sql"))
    failures: list[str] = []
    catalog_warnings: list[str] = []
    function_count = 0
    for path in files:
        source = path.read_text(encoding="utf-8-sig")
        try:
            parse_sql(source)
        except ParseError as error:
            failures.append(f"{path.name}: SQL: {error}")
            continue
        for offset, statement in plpgsql_functions(source):
            function_count += 1
            try:
                parse_plpgsql_json(statement)
            except ParseError as error:
                line = source.count("\n", 0, offset) + 1
                # libpg_query has no project catalog, so a local enum array may
                # be represented as the internal _record pseudo-type. The full
                # SQL statement was still parsed above; keep this visible but
                # do not misreport it as a grammar failure.
                if "pseudo-type _record" in str(error):
                    catalog_warnings.append(f"{path.name}:{line}: {error}")
                else:
                    failures.append(f"{path.name}:{line}: PL/pgSQL: {error}")
    if failures:
        print("\n".join(failures))
        return 1
    print(f"Parsed {len(files)} migrations and {function_count} PL/pgSQL functions successfully.")
    for warning in catalog_warnings:
        print(f"CATALOG WARNING: {warning}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
