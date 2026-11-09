#!/usr/bin/env python3
"""Build f5Rocket Q-SYS plugins from Q-SYS-style include directives."""

from __future__ import annotations

import base64
import json
import re
import sys
from pathlib import Path


QSYS_DIR = Path(__file__).resolve().parents[1]
REPO_ROOT = QSYS_DIR.parent
PLUGINS_DIR = QSYS_DIR / "plugins"
DIST_DIR = QSYS_DIR / "dist"
GAME_GENERATED_ASSETS = PLUGINS_DIR / "game" / "generated" / "assets_data.lua"

TARGETS = {
    "compat": {
        "source_root": PLUGINS_DIR / "compat",
        "entry": PLUGINS_DIR / "compat" / "plugin.lua",
        "output": DIST_DIR / "f5Rocket_Compat.qplug",
    },
    "game": {
        "source_root": PLUGINS_DIR / "game",
        "entry": PLUGINS_DIR / "game" / "plugin.lua",
        "output": DIST_DIR / "f5Rocket.qplug",
    },
}

ASSET_MANIFEST = (
    ("player_idle", "assets/player/player_idle.png"),
    ("player_left", "assets/player/player_left.png"),
    ("player_right", "assets/player/player_right.png"),
    ("enemy_01", "assets/enemy/enemy_01.png"),
    ("bullet_player", "assets/bullet/player_bullet.png"),
    ("bullet_enemy", "assets/bullet/enemy_bullet.png"),
    ("explosion_01", "assets/explosion/explosion_01.png"),
    ("explosion_02", "assets/explosion/explosion_02.png"),
    ("explosion_03", "assets/explosion/explosion_03.png"),
    ("background_tile", "assets/background/background_tile.png"),
)

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
INCLUDE_PATTERN = re.compile(
    r'^(?P<indent>[ \t]*)--\[\[ #include "(?P<name>[^"\r\n]+)" \]\][ \t]*(?:\r?\n)?$'
)


class BuildError(Exception):
    """Raised for an invalid asset or include graph."""


def read_source(path: Path) -> str:
    try:
        return path.read_bytes().decode("utf-8")
    except FileNotFoundError as error:
        raise BuildError(f"missing include file: {path}") from error
    except UnicodeDecodeError as error:
        raise BuildError(f"source is not valid UTF-8: {path}") from error


def indent_text(text: str, indent: str) -> str:
    if not indent:
        return text

    lines = text.splitlines(keepends=True)
    return "".join(indent + line if line.strip() else line for line in lines)


def expand_file(path: Path, source_root: Path, stack: tuple[Path, ...] = ()) -> str:
    resolved = path.resolve()
    resolved_root = source_root.resolve()

    if resolved in stack:
        cycle = " -> ".join(item.name for item in (*stack, resolved))
        raise BuildError(f"circular include detected: {cycle}")

    try:
        resolved.relative_to(resolved_root)
    except ValueError as error:
        raise BuildError(f"source escapes plugin tree: {resolved}") from error

    source = read_source(resolved)
    expanded = []
    next_stack = (*stack, resolved)

    for line_number, line in enumerate(source.splitlines(keepends=True), start=1):
        match = INCLUDE_PATTERN.fullmatch(line)
        if match is None:
            expanded.append(line)
            continue

        include_name = match.group("name")
        include_path = (resolved.parent / include_name).resolve()
        try:
            include_path.relative_to(resolved_root)
        except ValueError as error:
            raise BuildError(
                f"include escapes plugin tree at {resolved}:{line_number}: {include_name}"
            ) from error

        included = expand_file(include_path, source_root, next_stack)
        expanded.append(indent_text(included, match.group("indent")))

    return "".join(expanded)


def validate_png(path: Path, data: bytes) -> tuple[int, int]:
    if not data.startswith(PNG_SIGNATURE):
        raise BuildError(f"asset is not a PNG: {path}")
    if len(data) < 24 or data[12:16] != b"IHDR":
        raise BuildError(f"asset has no valid PNG IHDR: {path}")

    width = int.from_bytes(data[16:20], "big")
    height = int.from_bytes(data[20:24], "big")
    if width < 1 or height < 1:
        raise BuildError(f"asset has invalid PNG dimensions: {path}")
    return width, height


def lua_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=True)


def generate_game_assets() -> None:
    lines = [
        "-- GENERATED FILE - DO NOT EDIT.\n",
        "-- Source: root assets/ PNG manifest in qsys/tools/build.py\n",
        "-- Rebuild with: python3 qsys/tools/build.py game\n\n",
        "local GENERATED_ASSET_DATA = {\n",
    ]
    available_count = 0
    missing_paths = []

    for asset_id, relative_path in ASSET_MANIFEST:
        source_path = REPO_ROOT / relative_path
        available = source_path.is_file()
        data_uri = ""
        source_bytes = 0
        encoded_bytes = 0
        pixel_width = 0
        pixel_height = 0

        if available:
            data = source_path.read_bytes()
            pixel_width, pixel_height = validate_png(source_path, data)
            encoded = base64.b64encode(data).decode("ascii")
            data_uri = "data:image/png;base64," + encoded
            source_bytes = len(data)
            encoded_bytes = len(encoded)
            available_count += 1
            lines.append(f"  -- Available: {relative_path}\n")
        else:
            missing_paths.append(relative_path)
            lines.append(f"  -- Missing: {relative_path}\n")

        lines.extend(
            [
                f"  [{lua_string(asset_id)}] = {{\n",
                f"    Source = {lua_string(relative_path)},\n",
                f"    Available = {'true' if available else 'false'},\n",
                '    MimeType = "image/png",\n',
                f"    DataUri = {lua_string(data_uri)},\n",
                f"    SourceBytes = {source_bytes},\n",
                f"    EncodedBytes = {encoded_bytes},\n",
                f"    PixelWidth = {pixel_width},\n",
                f"    PixelHeight = {pixel_height}\n",
                "  },\n",
            ]
        )

    lines.append("}\n")
    output = "".join(lines).encode("utf-8")
    GAME_GENERATED_ASSETS.parent.mkdir(parents=True, exist_ok=True)
    GAME_GENERATED_ASSETS.write_bytes(output)

    relative_output = GAME_GENERATED_ASSETS.relative_to(REPO_ROOT)
    print(
        f"Generated {relative_output} "
        f"({available_count}/{len(ASSET_MANIFEST)} assets available)"
    )
    if missing_paths:
        print("Missing assets: " + ", ".join(missing_paths))


def generated_header(entry: Path) -> str:
    relative_entry = entry.relative_to(REPO_ROOT)
    return (
        "-- GENERATED FILE\n"
        f"-- Source: {relative_entry.as_posix()}\n"
        "-- Do not edit this file manually.\n\n"
    )


def build_target(name: str) -> None:
    target = TARGETS[name]
    if name == "game":
        generate_game_assets()

    entry = target["entry"]
    expanded = expand_file(entry, target["source_root"])
    if "#include" in expanded:
        raise BuildError(
            f"{name} output contains an unresolved or malformed #include"
        )

    output = (generated_header(entry) + expanded).encode("utf-8")
    output_path = target["output"]
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(output)

    relative_output = output_path.relative_to(REPO_ROOT)
    print(f"Built {relative_output} ({len(output)} bytes)")


def selected_targets(arguments: list[str]) -> tuple[str, ...]:
    if len(arguments) > 1:
        raise BuildError("usage: build.py [all|compat|game]")

    selected = arguments[0] if arguments else "all"
    if selected == "all":
        return ("compat", "game")
    if selected not in TARGETS:
        raise BuildError(f"unknown build target: {selected}")
    return (selected,)


def main() -> int:
    try:
        for target_name in selected_targets(sys.argv[1:]):
            build_target(target_name)
        return 0
    except BuildError as error:
        print(f"Build failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
