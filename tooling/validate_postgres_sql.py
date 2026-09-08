"""Parse every migration, including each PL/pgSQL function body."""

from __future__ import annotations

import re
from pathlib import Path

from pglast import parse_sql
from pglast.parser import parse_plpgsql_json


ROOT = Path(__file__).resolve().parents[1]
MIGRATIONS = ROOT / "supabase" / "migrations"
PLPGSQL_BODY = re.compile(
    r"language\s+plpgsql\b.*?\bas\s+\$([A-Za-z0-9_]*)\$(.*?)\$\1\$",
    re.IGNORECASE | re.DOTALL,
)
CATALOG_ENUM_ARRAY = re.compile(r"\bpublic\.[a-z_][a-z0-9_]*\[\]", re.IGNORECASE)


def main() -> None:
    files = sorted(MIGRATIONS.glob("*.sql"))
    function_count = 0
    for path in files:
        # PowerShell-created migrations may carry a UTF-8 BOM. PostgreSQL
        # clients accept the file, and stripping it here keeps parser QA from
        # failing before it reaches the SQL grammar.
        source = path.read_text(encoding="utf-8-sig")
        parse_sql(source)
        bodies = PLPGSQL_BODY.findall(source)
        # libpg_query's PL/pgSQL entry point consumes the original SQL and
        # validates embedded function bodies with their declaration context.
        # The standalone parser has no project catalog and otherwise assigns
        # qualified enum arrays the pseudo-type `_record`. Normalizing only
        # their declaration type lets it validate the PL/pgSQL grammar; the
        # original SQL is still parsed unchanged above and by Supabase.
        parse_plpgsql_json(CATALOG_ENUM_ARRAY.sub("text[]", source))
        function_count += len(bodies)
        print(f"OK {path.name} ({len(bodies)} PL/pgSQL bodies)")
    print(f"Parsed {len(files)} migrations and {function_count} PL/pgSQL bodies.")


if __name__ == "__main__":
    main()
