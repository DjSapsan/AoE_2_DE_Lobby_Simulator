#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path


def latest_version_key(maps_data: dict) -> str:
    keys = {
        int(version)
        for versions in maps_data.values()
        if isinstance(versions, dict)
        for version in versions.keys()
        if str(version).isdigit()
    }
    if not keys:
        raise ValueError("No numeric version keys found in JSON")
    return str(max(keys))


def extract_existing_ids(maps_block: str) -> set[int]:
    return {int(m.group(1)) for m in re.finditer(r'^\s*(\d+)\s*:\s*".*?"\s*,', maps_block, re.MULTILINE)}


def escape_gd_string(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def main() -> int:
    parser = argparse.ArgumentParser(description="Append missing map IDs from maps_aoe2.json to MAPS_TABLE in Tables.gd")
    parser.add_argument("--json", default="txt/maps_aoe2.json", help="Path to maps_aoe2.json")
    parser.add_argument("--tables", default="Scripts/Tables.gd", help="Path to Tables.gd")
    args = parser.parse_args()

    json_path = Path(args.json)
    tables_path = Path(args.tables)

    maps_data = json.loads(json_path.read_text(encoding="utf-8"))
    version_key = latest_version_key(maps_data)

    source = tables_path.read_text(encoding="utf-8")
    start_marker = "const MAPS_TABLE: Dictionary = {"
    end_marker = "\nconst GAME_TYPE_TABLE: Dictionary = {"

    start = source.find(start_marker)
    if start == -1:
        raise ValueError("MAPS_TABLE start marker not found")
    end = source.find(end_marker, start)
    if end == -1:
        raise ValueError("MAPS_TABLE end marker not found")

    maps_block = source[start:end]
    existing_ids = extract_existing_ids(maps_block)

    additions: list[str] = []
    for name, versions in maps_data.items():
        if not isinstance(versions, dict):
            continue
        map_id = versions.get(version_key)
        if not isinstance(map_id, int):
            continue
        if map_id in existing_ids:
            continue
        additions.append(f'\t{map_id} : "{escape_gd_string(name)}" ,\n')

    if not additions:
        print(f"No new entries. Latest version key: {version_key}")
        return 0

    additions.sort(key=lambda line: int(line.strip().split(" : ", 1)[0]))

    closing = maps_block.rfind("\t}")
    if closing == -1:
        closing = maps_block.rfind("}")
    if closing == -1:
        raise ValueError("Could not find MAPS_TABLE closing brace")

    new_maps_block = maps_block[:closing] + "".join(additions) + maps_block[closing:]
    new_source = source[:start] + new_maps_block + source[end:]
    tables_path.write_text(new_source, encoding="utf-8")

    print(f"Inserted {len(additions)} entries using latest version key {version_key}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
