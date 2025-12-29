#!/usr/bin/env python3
import argparse
import glob
import json
import os


def load_events(dirpath: str):
    events = []
    for fp in glob.glob(os.path.join(dirpath, "*.jsonl")):
        with open(fp, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                e = json.loads(line)
                ts = e.get("ts_ms") or e.get("timestamp_ms") or e.get("ts") or 0
                events.append((int(ts), fp, e))
    return sorted(events, key=lambda x: x[0])


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True)
    ap.add_argument("--out", required=True)
    a = ap.parse_args()

    events = load_events(a.input)
    os.makedirs(os.path.dirname(a.out), exist_ok=True)

    with open(a.out, "w", encoding="utf-8") as w:
        for ts, fp, e in events:
            w.write(
                json.dumps(
                    {"ts_ms": ts, "src": os.path.basename(fp), "keys": list(e.keys())},
                    ensure_ascii=False,
                )
                + "\n"
            )

    print("events:", len(events))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
