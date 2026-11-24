import Foundation

struct StationCatalog: Decodable {
    let game: String
    let stations: [Station]
}

struct Station: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let genre: String
    let hosts: String
    let colors: [String]
    let secret: Bool
    let tracks: [Track]

    /// Kurzform für das Badge, wenn kein eigenes Logo vorhanden ist.
    var shortName: String {
        let cleaned = name
            .replacingOccurrences(of: "Radio", with: "")
            .replacingOccurrences(of: "Records", with: "")
            .trimmingCharacters(in: .whitespaces)
        return cleaned.isEmpty ? name : cleaned
    }
}

struct Track: Decodable, Hashable, Identifiable {
    let number: Int
    let title: String
    let artist: String
    let fileName: String
    var id: Int { number }
}

/// Etwas, das tatsächlich abgespielt werden kann (Song oder Jingle/Ansage).
struct PlayableItem: Hashable, Identifiable {
    enum Kind: Hashable { case song, extra }
    let url: URL
    let title: String
    let artist: String
    let kind: Kind
    /// Nummer des Songs aus der GTA-VI-Trackliste, falls erkannt.
    let trackNumber: Int?
    var id: URL { url }
}

/// Was für einen Sender auf dem Gerät liegt.
struct StationContent {
    var songs: [PlayableItem] = []
    var extras: [PlayableItem] = []
    /// Tracknummer -> Datei
    var matched: [Int: URL] = [:]
    var logoURL: URL?

    var isPlayable: Bool { !songs.isEmpty }
}
