"""Validate the built font families and package them with their build inputs."""

import argparse
import hashlib
import io
import json
import subprocess
import tomllib
import zipfile
from pathlib import Path

import uharfbuzz as hb
from fontTools.ttLib import TTFont


def shape(data, text, calt):
    font = hb.Font(hb.Face(data))
    buffer = hb.Buffer()
    buffer.add_str(text)
    buffer.guess_segment_properties()
    hb.shape(font, buffer, {"calt": calt, "dlig": False, "liga": False})
    return [
        (glyph.codepoint, pos.x_advance, pos.x_offset, pos.y_offset)
        for glyph, pos in zip(buffer.glyph_infos, buffer.glyph_positions)
    ]


def axis(plans, plan, name):
    values = plan[name]
    if "inherits" in values:
        inherited = values["inherits"].removeprefix("buildPlans.")
        return plans[inherited][name]
    return values


def collect_fonts(source, plans):
    files = []
    for name, plan in plans.items():
        widths = axis(plans, plan, "widths")
        expected = {
            (weight["menu"], width["menu"], round(-slope["angle"], 2))
            for weight in plan["weights"].values()
            for width in widths.values()
            for slope in axis(plans, plan, "slopes").values()
        }
        actual = set()
        fonts = sorted((source / "dist" / name / "TTF").glob("*.ttf"))
        if len(fonts) != len(expected):
            raise ValueError(f"{name}: expected {len(expected)} TTFs, found {len(fonts)}")
        for path in fonts:
            data = path.read_bytes()
            with TTFont(io.BytesIO(data)) as font:
                family = font["name"].getDebugName(16) or font["name"].getDebugName(1)
                if family != plan["family"]:
                    raise ValueError(f"{path.name}: unexpected family {family!r}")
                actual.add((
                    font["OS/2"].usWeightClass,
                    font["OS/2"].usWidthClass,
                    round(font["post"].italicAngle, 2),
                ))
                # Include symbols used in code and in the existing Powerline separators.
                required = {ord(char) for char in "0aIlλ∀∃→\ue0b1\ue0b3"}
                missing = required - font.getBestCmap().keys()
                if missing:
                    raise ValueError(f"{path.name}: missing codepoints {sorted(missing)}")
                features = font["GSUB"].table.FeatureList.FeatureRecord
                if not any(record.FeatureTag == "calt" for record in features):
                    raise ValueError(f"{path.name}: missing default ligature feature")
            for sample in ("->", "--", "(*"):
                if shape(data, sample, False) == shape(data, sample, True):
                    raise ValueError(f"{path.name}: calt has no effect on {sample!r}")
            files.append((path, f"{name}/{path.name}"))
            print(f"Verified {path.name}")
        if actual != expected:
            raise ValueError(f"{name}: style mismatch; expected {expected}, found {actual}")
    return files


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="Iosevka source checkout containing dist/")
    parser.add_argument("output", type=Path, help="Directory for the ZIP and release notes")
    parser.add_argument("--dotfiles-commit", required=True)
    args = parser.parse_args()
    config_dir = Path(__file__).resolve().parent
    config_path = config_dir / "private-build-plans.toml"
    plans = tomllib.loads(config_path.read_text())["buildPlans"]
    version = (config_dir / "version.txt").read_text().strip()
    upstream_commit = subprocess.check_output(
        ["git", "-C", str(args.source), "rev-parse", "HEAD"], text=True
    ).strip()
    files = collect_fonts(args.source, plans)
    manifest = {
        "iosevka_version": version,
        "iosevka_commit": upstream_commit,
        "dotfiles_commit": args.dotfiles_commit,
        "config_sha256": hashlib.sha256(config_path.read_bytes()).hexdigest(),
        "fonts": {name: hashlib.sha256(path.read_bytes()).hexdigest() for path, name in files},
    }
    args.output.mkdir(parents=True, exist_ok=True)
    archive_path = args.output / f"iosevka-shengyi-{version}-{args.dotfiles_commit[:7]}.zip"
    with zipfile.ZipFile(archive_path, "x", compression=zipfile.ZIP_DEFLATED) as archive:
        for path, name in files:
            archive.write(path, name)
        archive.write(args.source / "LICENSE.md", "LICENSE.md")
        for name in ("private-build-plans.toml", "version.txt", "README.md"):
            archive.write(config_dir / name, name)
        archive.writestr("build-info.json", json.dumps(manifest, indent=2) + "\n")
    notes = (
        f"Iosevka Shengyi 与 Iosevka Term Shengyi，共 {len(files)} 个 TTF 文件。\n\n"
        f"- Iosevka：{version}（`{upstream_commit}`）\n"
        f"- dotfiles：`{args.dotfiles_commit}`\n"
        "- Curly / ss20、长点零、双层带衬线 a、dlig 连字预设。\n"
        "- 安装方法、构建配置、字体许可证和 SHA-256 校验值均包含在 ZIP 中。\n"
    )
    (args.output / "RELEASE_NOTES.md").write_text(notes)
    print(f"Packaged {len(files)} fonts: {archive_path}")


if __name__ == "__main__":
    main()
