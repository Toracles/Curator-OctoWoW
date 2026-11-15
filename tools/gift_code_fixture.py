from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory


def gift_code_fixture():
    with TemporaryDirectory() as directory:
        key = str(Path(directory) / "test.pem")
        generator = ["node", "tools/gift-code.cjs"]
        public = subprocess.check_output(generator + ["init", "--key", key], text=True)
        gift = subprocess.check_output(generator + [
            "issue", "--key", key, "--to", "Tester-N'Zoth", "--zone", "1", "--rubies", "100"
        ], text=True).strip()
    prefix, payload, signature = gift.split(".")
    altered_signature = ("B" if signature[0] == "A" else "A") + signature[1:]
    altered = ".".join((prefix, payload, altered_signature))
    return (f"local ns = CuratorOctoFull\n{public}\n"
            f'octoGiftTestCode = "{gift}"\noctoGiftBadCode = "{altered}"\n')
