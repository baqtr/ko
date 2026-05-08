#!/usr/bin/env python3
import os
import sys
import time
import tarfile
import urllib.request
import subprocess
from pathlib import Path

XMRIG_VERSION = os.getenv("XMRIG_VERSION", "6.26.0")
XMRIG_URL = os.getenv(
    "XMRIG_URL",
    f"https://github.com/xmrig/xmrig/releases/download/v{XMRIG_VERSION}/xmrig-{XMRIG_VERSION}-linux-static-x64.tar.gz",
)
WORK_DIR = Path(os.getenv("XMRIG_WORKDIR", "/tmp/xmrig-run"))
ARCHIVE = WORK_DIR / "xmrig.tar.gz"
BIN = WORK_DIR / "xmrig"


def require_env(name: str) -> str:
    value = os.getenv(name, "").strip()
    if not value or "PUT_YOUR" in value:
        print(f"❌ المتغير {name} غير مضبوط. ضع القيمة في Heroku Config Vars أو config.env قبل النشر.", flush=True)
        sys.exit(1)
    return value


def download_xmrig() -> None:
    WORK_DIR.mkdir(parents=True, exist_ok=True)
    if BIN.exists():
        BIN.chmod(0o755)
        return

    print(f"⬇️ Downloading XMRig {XMRIG_VERSION}...", flush=True)
    urllib.request.urlretrieve(XMRIG_URL, ARCHIVE)

    with tarfile.open(ARCHIVE, "r:gz") as tar:
        members = tar.getmembers()
        xmrig_member = None
        for member in members:
            if member.name.endswith("/xmrig") or member.name == "xmrig":
                xmrig_member = member
                break
        if xmrig_member is None:
            print("❌ لم يتم العثور على ملف xmrig داخل الأرشيف.", flush=True)
            sys.exit(1)
        extracted = tar.extractfile(xmrig_member)
        if extracted is None:
            print("❌ فشل استخراج xmrig.", flush=True)
            sys.exit(1)
        BIN.write_bytes(extracted.read())
    BIN.chmod(0o755)
    print("✅ XMRig is ready.", flush=True)


def main() -> None:
    wallet = require_env("XMR_WALLET")
    pool = os.getenv("XMR_POOL", "pool.supportxmr.com:3333").strip()
    worker = os.getenv("WORKER_NAME", "heroku1").strip()
    threads = os.getenv("XMR_THREADS", "2").strip()
    donate = os.getenv("XMR_DONATE_LEVEL", "1").strip()

    download_xmrig()

    cmd = [
        str(BIN),
        "-o", pool,
        "-u", wallet,
        "-p", worker,
        "--coin", "monero",
        "--donate-level", donate,
        "--threads", threads,
        "--print-time", "30",
    ]

    print("🚀 Starting authorized XMR mining worker...", flush=True)
    print(f"Pool: {pool}", flush=True)
    print(f"Worker: {worker}", flush=True)
    print(f"Threads: {threads}", flush=True)
    print("ملاحظة: إذا ظهرت كلمة accepted في السجل فهذا يعني أن التعدين يعمل.", flush=True)

    while True:
        proc = subprocess.Popen(cmd)
        code = proc.wait()
        print(f"⚠️ XMRig exited with code {code}. Restarting in 10 seconds...", flush=True)
        time.sleep(10)


if __name__ == "__main__":
    main()
