import Foundation

/// Ordnet Dateinamen den Songs der Trackliste zu – tolerant gegenüber
/// Groß-/Kleinschreibung, Sonderzeichen, Akzenten und Nummern-Präfixen.
struct TrackMatcher: Sendable {
    private struct Entry: Sendable {
        let track: Track
        let fileName: String
        let title: String
        let artists: [String]
    }
    private let entries: [Entry]

    init(tracks: [Track]) {
        entries = tracks.map { track in
            Entry(track: track,
                  fileName: track.fileName.lowercased(),
                  title: Self.normalize(track.title),
                  artists: Self.artistTokens(track.artist))
        }
    }

    func match(fileName: String, excluding taken: Set<Int>) -> Track? {
        let lower = fileName.lowercased()
        let stem = (lower as NSString).deletingPathExtension
        // 1) exakter empfohlener Dateiname (Endung egal)
        if let exact = entries.first(where: {
            ($0.fileName as NSString).deletingPathExtension == stem && !taken.contains($0.track.number)
        }) {
            return exact.track
        }
        let norm = Self.normalize(Self.stripNumberPrefix(stem))
        guard !norm.isEmpty else { return nil }

        // 2) Titel + (ein) Interpret enthalten – längster Titel gewinnt
        let strong = entries
            .filter { !taken.contains($0.track.number) && !$0.title.isEmpty && norm.contains($0.title) }
            .filter { entry in entry.artists.contains { norm.contains($0) } }
            .max { $0.title.count < $1.title.count }
        if let strong { return strong.track }

        // 3) nur Titel – wenn er lang genug und eindeutig ist
        let weak = entries.filter {
            !taken.contains($0.track.number) && $0.title.count >= 6 && norm.contains($0.title)
        }
        if weak.count == 1 { return weak[0].track }
        return nil
    }

    static func normalize(_ s: String) -> String {
        let folded = s.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
        return String(folded.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }.map(Character.init))
            .lowercased()
    }

    static func artistTokens(_ artist: String) -> [String] {
        let separators = [" feat. ", " featuring ", " ft. ", " & ", ", ", " with ", " x ", " and the ", " and "]
        var parts = [artist]
        for sep in separators {
            parts = parts.flatMap { $0.components(separatedBy: sep) }
        }
        return parts.map(normalize).filter { $0.count >= 2 }
    }

    static func stripNumberPrefix(_ s: String) -> String {
        s.replacingOccurrences(of: #"^\s*\d{1,3}\s*[-._)]?\s*"#, with: "", options: .regularExpression)
    }

    /// Für Dateien ohne Treffer: „Interpret - Titel“ aus dem Namen raten.
    static func guessArtistTitle(from url: URL) -> (String?, String) {
        let stem = stripNumberPrefix(url.deletingPathExtension().lastPathComponent)
        let parts = stem.components(separatedBy: " - ")
        if parts.count >= 2 {
            return (parts[0].trimmingCharacters(in: .whitespaces),
                    parts.dropFirst().joined(separator: " - ").trimmingCharacters(in: .whitespaces))
        }
        return (nil, stem)
    }
}
