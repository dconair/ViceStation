# ViceStation 🌴📻

iOS-App für deine eigenen **GTA VI-Radiosender**: alle 21 Musiksender aus Leonida mit den kompletten Tracklisten (810 Songs). Das Design orientiert sich am Vice-City-Look: Sonnenuntergang, Palmen, Neon und ein Radio-Rad wie im Spiel.

> Musik wird **nicht** mitgeliefert. Du legst deine eigenen Dateien ab, die App ordnet sie automatisch den Sendern und Songs zu.

## 📋 Welche Songs brauche ich?

- **[docs/SONGLIST.md](docs/SONGLIST.md)**: alle Sender und Songs, mit empfohlenem Dateinamen und Ordner
- **[docs/songlist.csv](docs/songlist.csv)**: dieselbe Liste für Excel oder Numbers (Trennzeichen `;`)
- In der App unter **Sammlung › Fehlende Songs teilen**: nur das, was dir noch fehlt

## ✨ Features

- **Radio-Rad** wie im Spiel: Sender antippen oder mit dem Finger übers Rad fahren und loslassen. Lange drücken öffnet den Sender.
- **Live-Gefühl**: Beim Einschalten läuft der Sender „schon“, d. h. ein zufälliger Song startet mittendrin. Danach wird ohne Wiederholungen gemischt.
- **Funkrauschen** beim Senderwechsel (wird live erzeugt)
- **Jingles, Werbung und DJ-Ansagen**: Dateien im Unterordner `_extras/` werden zufällig zwischen die Songs gestreut (Häufigkeit einstellbar)
- **Eigene Senderlogos**: aufs Logo tippen und ein Bild aus Fotos oder Dateien wählen. Ohne eigenes Logo zeigt die App ein generiertes Badge in den Senderfarben.
- **Hintergrund-Wiedergabe**, Sperrbildschirm, Control Center und CarPlay-/Kopfhörer-Tasten (vor/zurück = Senderwechsel)
- **Tolerante Song-Erkennung**: Groß- und Kleinschreibung, Akzente, Sonderzeichen und Nummern sind egal. `Dua Lipa - Houdini.m4a` wird genauso erkannt wie der empfohlene Name.
- Eigene Songs, die nicht in der GTA-Liste stehen, laufen trotzdem mit, als „Custom Station“.
- 🤫 Geheimsender *The Vault Radio*: Tipp das ViceStation-Logo 5× an.

## 🛠 Bauen und aufs iPhone bringen

Voraussetzung: ein Mac mit Xcode 15 oder neuer, iOS 17+.

```bash
brew install xcodegen
```

```bash
xcodegen generate
```

```bash
open ViceStation.xcodeproj
```

Danach in Xcode unter *Signing & Capabilities* dein Team auswählen. Eine kostenlose Apple-ID reicht, die App läuft dann allerdings nur 7 Tage. Anschließend iPhone anschließen und ▶︎ drücken.

## 🎵 Songs aufs iPhone

1. App einmal starten. Sie legt für jeden Sender einen Ordner an.
2. **Dateien-App › Auf meinem iPhone › ViceStation › Stations › `<sender>`**: Songs hineinkopieren. Vom Mac geht das auch über den Finder: iPhone auswählen › *Dateien* › ViceStation.
3. Optional: `_extras/` für Jingles und `logo.png` als Senderlogo
4. In der App **Sammlung › Neu einlesen** tippen

Unterstützt werden `mp3`, `m4a`, `aac`, `wav`, `aiff`, `flac`, `caf`.

## 🗂 Projektstruktur

```
data/gta6_tracklist.json   Tracklisten (Quelle)
data/stations_meta.json    Genre, Hosts, Farben je Sender
tools/build_data.py        erzeugt Stations.json + SONGLIST.md + CSV
tools/make_icon.py         erzeugt das App-Icon
ViceStation/               SwiftUI-App (iOS 17)
  Services/                Bibliothek, Song-Erkennung, Radio-Player
  Views/                   Radio-Rad, Senderliste, Detail, Sammlung, Theme
```

Tracklisten ändern: `data/*.json` anpassen und danach dieses Skript ausführen:

```bash
python3 tools/build_data.py
```

## ⚖️ Hinweis

Inoffizielles Fan-Projekt ohne Verbindung zu Rockstar Games oder Take-Two Interactive. „Grand Theft Auto“ und die Sendernamen gehören ihren Rechteinhabern. Es werden keine Musikdateien und keine offiziellen Logos mitgeliefert.
Quelle der Trackliste: keengamer.com, „GTA 6: All Radio Stations and Full Soundtrack List“ (19.11.2026).
