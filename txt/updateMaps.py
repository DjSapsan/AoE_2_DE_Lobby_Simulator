#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path


def extract_existing_ids(maps_block: str) -> set[int]:
    return {int(m.group(1)) for m in re.finditer(r'^\s*(\d+)\s*:\s*".*?"\s*,', maps_block, re.MULTILINE)}


def escape_gd_string(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def normalize_token(token: str) -> str:
    if not token:
        return ""
    if token.lower() == "quickplay":
        return "Qp"
    if token.isupper() or token.islower():
        return token.capitalize()
    return token[0].upper() + token[1:]


def to_pascal_case(value: str) -> str:
    parts = re.split(r"[^A-Za-z0-9]+", value.strip())
    return "".join(normalize_token(part) for part in parts if part)


def strip_data_name_suffix(data_name: str) -> str:
    value = data_name.strip()
    value = re.sub(r"(?i)[_-]SPECIAL[_-]MAP$", "", value)
    value = re.sub(r"(?i)[_-]MAP$", "", value)
    return value


def extract_map_name(item: dict) -> str | None:
    direct_name = item.get("name")
    if isinstance(direct_name, str) and direct_name.strip():
        return direct_name.strip()

    const_name = item.get("const_name")
    if isinstance(const_name, str) and const_name.strip():
        return to_pascal_case(const_name)

    data_name = item.get("data_name")
    if isinstance(data_name, str) and data_name.strip():
        return to_pascal_case(strip_data_name_suffix(data_name))

    script_filename = item.get("script_filename")
    if isinstance(script_filename, str) and script_filename.strip():
        return to_pascal_case(Path(script_filename).stem)

    return None


def extract_maps(json_data: dict) -> list[tuple[int, str]]:
    map_list = json_data.get("map_list")
    if not isinstance(map_list, list):
        raise ValueError("Expected JSON object with a 'map_list' array")

    extracted: list[tuple[int, str]] = []
    for item in map_list:
        if not isinstance(item, dict):
            continue
        map_id = item.get("name_string_id")
        if not isinstance(map_id, int):
            continue
        map_name = extract_map_name(item)
        if not map_name:
            continue
        extracted.append((map_id, map_name))
    return extracted


def main() -> int:
    parser = argparse.ArgumentParser(description="Append missing map IDs from maps.json to MAPS_TABLE in Tables.gd")
    parser.add_argument("--json", default="txt/maps.json", help="Path to maps.json")
    parser.add_argument("--tables", default="Scripts/Tables.gd", help="Path to Tables.gd")
    args = parser.parse_args()

    json_path = Path(args.json)
    tables_path = Path(args.tables)

    maps_data = json.loads(json_path.read_text(encoding="utf-8"))
    maps = extract_maps(maps_data)

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
    for map_id, map_name in maps:
        if map_id in existing_ids:
            continue
        additions.append(f'\t{map_id} : "{escape_gd_string(map_name)}" ,\n')
        existing_ids.add(map_id)

    if not additions:
        print("No new entries.")
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

    print(f"Inserted {len(additions)} entries from map_list")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
