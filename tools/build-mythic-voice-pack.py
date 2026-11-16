"""Generate the optional bilingual SoftSpoken pack from Curator's Mythic catalogue."""

import argparse
import json
from pathlib import Path
import re
import subprocess
import tempfile
import wave
from zipfile import ZIP_DEFLATED, ZipFile

from piper import PiperVoice, SynthesisConfig


PACK = "CuratorSoftSpokenVoices"
MODELS = {"enUS": "en_GB-vctk-medium", "frFR": "fr_FR-mls-medium"}
FRENCH = {
    3977: "La Lumière a parlé !",
    4421: "Sales morveux. Je vais vous apprendre à vous mêler de mes affaires !",
    12397: "Tous les mortels périront !",
    15727: "Vous allez mourir.",
}
FEMALE = {3977, 4421, 4968, 7016, 7999, 10181, 10184, 10201, 12201, 14277, 14887}
CAST = {
    "enUS": {False: ("p226", "p227", "p232", "p237"), True: ("p225", "p228", "p229")},
    "frFR": {False: ("1840", "3698", "7423"), True: ("123", "1474", "3060")},
}
THRALL = {
    "enUS": "All members of the Horde are equal in my eyes.",
    "frFR": "Tous les membres de la Horde sont égaux à mes yeux.",
}


def encode_lua(text):
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ") + '"'


def script_line(card, locale):
    row = card[locale]
    if card["id"] == 4949:
        return THRALL[locale]
    if locale == "frFR" and card["id"] in FRENCH and not row["scripted"]:
        return FRENCH[card["id"]]
    return " ".join(row["text"].replace("%s", row["name"]).split())


def synthesize(voice, card, locale, destination, encoder, probe, wav):
    npc = card["id"]
    caption = script_line(card, locale)
    assert caption and not re.search(r"[%$|\uFFFD]", caption), (npc, locale, caption)
    names = CAST[locale][npc in FEMALE]
    speaker = voice.config.speaker_id_map[names[npc % len(names)]]
    # Spoken emphasis follows sentence punctuation without spelling uppercase words.
    speech = re.sub(r"\b[A-ZÀ-ÖØ-Þ]{2,}\b", lambda word: word[0].lower(), caption)
    heavy = card.get("kind") in (2, 3, 4, 6, 9)
    config = SynthesisConfig(speaker_id=speaker, length_scale=1.02 if heavy else 0.94)
    with wave.open(str(wav), "wb") as output:
        voice.synthesize_wav(speech, output, config)
    rate = 19400 if heavy else 21750
    filters = f"asetrate={rate},aresample=22050,highpass=f=75,alimiter=limit=0.85"
    subprocess.run(
        [encoder, "-hide_banner", "-loglevel", "error", "-y", "-i", str(wav),
         "-af", filters, "-codec:a", "libmp3lame", "-b:a", "64k", str(destination)],
        check=True,
    )
    duration = float(subprocess.check_output(
        [probe, "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(destination)],
        text=True,
    ))
    assert 0.5 <= duration <= 25, (npc, locale, duration)
    return caption, duration


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("catalogue", type=Path)
    parser.add_argument("--models", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--ffmpeg", default="ffmpeg")
    parser.add_argument("--ffprobe", default="ffprobe")
    args = parser.parse_args()
    catalogue = json.loads(args.catalogue.read_text(encoding="utf8"))
    by_npc = {}
    for card in catalogue:
        original = by_npc.setdefault(card["id"], card)
        assert all(script_line(card, locale) == script_line(original, locale) for locale in MODELS), card["id"]
    cards = list(by_npc.values())
    assert cards
    result = {}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=args.output.parent) as tmp:
        staging = Path(tmp)
        for locale, model in MODELS.items():
            voice = PiperVoice.load(args.models / f"{model}.onnx")
            folder = staging / PACK / locale
            folder.mkdir(parents=True)
            for i, card in enumerate(cards, start=1):
                npc = card["id"]
                caption, duration = synthesize(voice, card, locale, folder / f"{npc}.mp3",
                                               args.ffmpeg, args.ffprobe, staging / "line.wav")
                result.setdefault(npc, {})[locale] = (caption, duration)
                if i % 10 == 0 or i == len(cards):
                    print(f"{locale}: {i}/{len(cards)} clips", flush=True)
        toc = ("## Interface: 11200\n## Title: Curator SoftSpoken Voices\n"
               "## Notes: Optional English and French Mythic voices for Curator.\n"
               "## Version: 2\n\nVoices.lua\n")
        manifest = ["CuratorSoftSpokenVoices = {"]
        for npc, recordings in sorted(result.items()):
            manifest.append(f"    [{npc}] = {{")
            for locale, (caption, duration) in recordings.items():
                path = f"Interface\\AddOns\\{PACK}\\{locale}\\{npc}.mp3"
                manifest.append(f"        {locale} = {{path = [[{path}]], length = {duration + 0.03:.3f}, "
                                f"text = {encode_lua(caption)}}},")
            manifest.append("    },")
        manifest.append("}")
        pack_dir = staging / PACK
        (pack_dir / f"{PACK}.toc").write_text(toc, encoding="utf8")
        (pack_dir / "Voices.lua").write_text("\n".join(manifest) + "\n", encoding="utf8")
        (pack_dir / "VOICE-CREDITS.md").write_text(
            "# Voice credits\n\n"
            "Synthetic recordings generated with Piper and processed for Curator. "
            "English uses the VCTK model. French uses the Multilingual LibriSpeech model. "
            "Both model cards credit datasets licensed under CC BY 4.0.\n\n"
            "- [Piper English VCTK model card](https://huggingface.co/rhasspy/piper-voices/blob/v1.0.0/en/en_GB/vctk/medium/MODEL_CARD)\n"
            "- [Piper French MLS model card](https://huggingface.co/rhasspy/piper-voices/blob/v1.0.0/fr/fr_FR/mls/medium/MODEL_CARD)\n"
            "- [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)\n",
            encoding="utf8",
        )
        with ZipFile(args.output, "w", ZIP_DEFLATED) as archive:
            for path in sorted(pack_dir.rglob("*")):
                if path.is_file():
                    archive.write(path, path.relative_to(staging).as_posix())
        with ZipFile(args.output) as archive:
            assert archive.testzip() is None
            assert len([name for name in archive.namelist() if name.endswith(".mp3")]) == len(cards) * len(MODELS)
    print(f"Verified {len(catalogue)} cards and {len(cards) * len(MODELS)} recordings in {args.output}")


if __name__ == "__main__":
    main()
