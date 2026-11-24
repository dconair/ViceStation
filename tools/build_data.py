#!/usr/bin/env python3
"""Erzeugt aus data/*.json:
  - ViceStation/Resources/Stations.json  (wird in die App gebündelt)
  - docs/SONGLIST.md                     (Einkaufs-/Sammelliste mit Ziel-Dateinamen)
  - docs/songlist.csv                    (dasselbe als Tabelle)
Aufruf: python3 tools/build_data.py
"""
import csv, json, os, re, unicodedata

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
tracks = json.load(open(os.path.join(ROOT, "data/gta6_tracklist.json"), encoding="utf-8"))
meta = json.load(open(os.path.join(ROOT, "data/stations_meta.json"), encoding="utf-8"))

def slug(s):
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")

def safe(s):
    # Zeichen, die in Dateinamen (iOS/Windows/macOS) Probleme machen
    s = re.sub(r'[\\/:*?"<>|]', "-", s)
    return re.sub(r"\s+", " ", s).strip()

stations = []
for m in meta:
    name = m["name"]
    assert name in tracks, name
    sid = slug(name)
    ts = []
    for i, t in enumerate(tracks[name], 1):
        ts.append({
            "number": i,
            "title": t["title"],
            "artist": t["artist"],
            "fileName": f"{i:03d} - {safe(t['artist'])} - {safe(t['title'])}.mp3",
        })
    stations.append({
        "id": sid, "name": name, "genre": m["genre"], "hosts": m["hosts"],
        "colors": m["colors"], "secret": m.get("secret", False), "tracks": ts,
    })
missing = set(tracks) - {m["name"] for m in meta}
assert not missing, missing

out = os.path.join(ROOT, "ViceStation/Resources/Stations.json")
json.dump({"game": "Grand Theft Auto VI", "stations": stations}, open(out, "w", encoding="utf-8"),
          ensure_ascii=False, indent=1)

total = sum(len(s["tracks"]) for s in stations)
md = ["# ViceStation – benötigte Songs (GTA VI Radio)", "",
      f"**{len(stations)} Musiksender · {total} Songs.** Die Talk-Sender *WKTT* und *The Wipe* spielen keine Musik und fehlen deshalb.", "",
      "## So legst du die Dateien ab", "",
      "1. App einmal starten – sie legt in der **Dateien-App** unter *Auf meinem iPhone › ViceStation › Stations* für jeden Sender einen Ordner an.",
      "2. Lege die Songs in den passenden Ordner. Der empfohlene Dateiname steht unten in der Spalte *Datei*.",
      "   Die App erkennt Songs aber auch, wenn der Dateiname nur Titel (und idealerweise Interpret) enthält, z. B. `Dua Lipa - Houdini.m4a`.",
      "3. Unterstützt: `.mp3`, `.m4a`, `.aac`, `.wav`, `.aiff`, `.flac`, `.caf`.",
      "4. Optional pro Sender: `logo.png` (quadratisch, eigenes Senderlogo) und ein Unterordner `_extras/` mit Jingles, DJ-Ansagen oder Werbung – die werden zufällig zwischen den Songs eingestreut.",
      "", "## Senderübersicht", "", "| Sender | Ordner | Genre | Songs |", "|---|---|---|---|"]
for s in stations:
    md.append(f"| {s['name']} | `Stations/{s['id']}/` | {s['genre']} | {len(s['tracks'])} |")
for s in stations:
    md += ["", f"## {s['name']}", "", f"*{s['genre']} · Hosts: {s['hosts']}* — Ordner: `Stations/{s['id']}/`", "",
           "| # | Interpret | Titel | Datei |", "|---|---|---|---|"]
    for t in s["tracks"]:
        md.append(f"| {t['number']} | {t['artist'].replace('|','/')} | {t['title'].replace('|','/')} | `{t['fileName']}` |")
md += ["", "---", "Quelle der Trackliste: keengamer.com, „GTA 6: All Radio Stations and Full Soundtrack List“ (19.11.2026). Vor dem Kauf ggf. mit dem In-Game-Radio abgleichen.", ""]
open(os.path.join(ROOT, "docs/SONGLIST.md"), "w", encoding="utf-8").write("\n".join(md))

with open(os.path.join(ROOT, "docs/songlist.csv"), "w", encoding="utf-8-sig", newline="") as f:
    w = csv.writer(f, delimiter=";")
    w.writerow(["Sender", "Ordner", "Nr", "Interpret", "Titel", "Dateiname"])
    for s in stations:
        for t in s["tracks"]:
            w.writerow([s["name"], f"Stations/{s['id']}", t["number"], t["artist"], t["title"], t["fileName"]])
print(f"{len(stations)} Sender, {total} Songs")
