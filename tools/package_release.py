"""Assemble an installable Curator ZIP from current scripts and verified media."""

import argparse
import hashlib
from pathlib import Path, PurePosixPath
import re
import tempfile
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo


REPO = Path(__file__).resolve().parents[1]
MEDIA_SHA256 = "fecd9351b599222a291f451d834eb2c6eb69675712578d612b103c5dc75a70e0"
# Complete v0.5.0 also contains the same verified media, for missing alpha.2 inputs.
MEDIA_SHA256S = {MEDIA_SHA256, "dda295ef266ab8e9d86723404937a8d67bafee33bd4285888013131a7fef39e7"}
MEDIA_PREFIX = "Curator/Media/"
TOC = "Curator/Curator.toc"


def reject_private_admin(files):
    """Fail closed if maintainer-only code reaches the public addon tree."""
    for name, data in files.items():
        parts = PurePosixPath(name.replace("\\", "/")).parts
        if any(part.lower() in {"private-local", "curatoradmin", "admin", "admin.lua", "admin.xml", "admin.toc"} for part in parts):
            raise ValueError(f"Private admin file forbidden in release: {name}")
        if name.lower().endswith(".lua") and re.search(
            rb"(?:ns|CuratorOctoFull)\s*\.\s*Admin\s*=(?!=)", data
        ):
            raise ValueError(f"Private admin activation forbidden in release: {name}")


def write_member(package, name, data):
    info = ZipInfo(name)
    info.compress_type = ZIP_DEFLATED
    package.writestr(info, data, compresslevel=3)


def build(version, media_archive):
    addon = REPO / "curator-test"
    files = {
        "Curator/" + path.relative_to(addon).as_posix(): path.read_bytes()
        for path in sorted(addon.rglob("*"))
        if path.is_file() and path.suffix.lower() in {".lua", ".xml", ".toc", ".txt"}
    }
    reject_private_admin(files)
    toc = files[TOC]
    for line in toc.decode("utf-8-sig").splitlines():
        entry = line.strip()
        if entry and not entry.startswith("#"):
            name = "Curator/" + entry.replace("\\", "/")
            if name not in files:
                raise ValueError(f"TOC entry missing from addon: {entry}")
    newline = b"\r\n" if b"\r\n" in toc else b"\n"
    files[TOC] = toc.replace(
        newline, newline + f"## X-OctoWoW-Release: {version}".encode() + newline, 1
    )

    output = REPO / "release" / f"Curator-OctoWoW-v{version}.zip"
    output.parent.mkdir(exist_ok=True)
    with media_archive.open("rb") as source:
        if hashlib.file_digest(source, "sha256").hexdigest() not in MEDIA_SHA256S:
            raise ValueError("The media archive does not match a verified alpha.2 or v0.5.0 ZIP.")
        with tempfile.NamedTemporaryFile(dir=output.parent, suffix=".zip", delete=False) as temp:
            temporary = Path(temp.name)
        try:
            with ZipFile(source) as media, ZipFile(temporary, "w") as package:
                assets = {
                    info.filename: info
                    for info in media.infolist()
                    if not info.is_dir() and info.filename.startswith(MEDIA_PREFIX)
                }
                if not assets or files.keys() & assets.keys():
                    raise ValueError("Missing media or duplicate addon paths.")
                for name, data in files.items():
                    write_member(package, name, data)
                for name, info in sorted(assets.items()):
                    if ".." in PurePosixPath(name).parts or "\\" in name:
                        raise ValueError(f"Invalid media path: {name}")
                    write_member(package, name, media.read(info))

            with ZipFile(temporary) as package:
                if set(package.namelist()) != files.keys() | assets.keys() or package.testzip():
                    raise ValueError("The assembled ZIP failed its integrity check.")
                for name, data in files.items():
                    if package.read(name) != data:
                        raise ValueError(f"Packaged addon file differs: {name}")
                for name, info in assets.items():
                    packed = package.getinfo(name)
                    if (packed.CRC, packed.file_size) != (info.CRC, info.file_size):
                        raise ValueError(f"Packaged media file differs: {name}")
            temporary.replace(output)
        finally:
            temporary.unlink(missing_ok=True)
    print(f"{output} ({len(files)} addon files, {len(assets)} media files)")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("version", help="Version without the v prefix, such as 0.5.0")
    parser.add_argument("--media-archive", type=Path, required=True, help="Verified alpha.2 base or complete v0.5.0 ZIP")
    args = parser.parse_args()
    if not re.fullmatch(r"\d+\.\d+\.\d+(?:-[A-Za-z0-9]+(?:[.-][A-Za-z0-9]+)*)?", args.version):
        parser.error("Use a version such as 0.5.0 or 0.6.0-alpha.1.")
    build(args.version, args.media_archive)


if __name__ == "__main__":
    main()
