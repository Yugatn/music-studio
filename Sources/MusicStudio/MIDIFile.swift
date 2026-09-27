import Foundation

enum MIDIFileError: Error {
    case invalidHeader
    case unsupportedFormat
    case truncated
    case invalidTrack
}

struct MIDIFile {
    static func export(project: MusicProject) throws -> Data {
        var trackData: [UInt8] = []
        let tempo = UInt32(max(1, Int(60_000_000.0 / project.bpm)))

        trackData += [0x00, 0xFF, 0x51, 0x03,
                      UInt8((tempo >> 16) & 0xFF),
                      UInt8((tempo >> 8) & 0xFF),
                      UInt8(tempo & 0xFF)]
        trackData += [0x00, 0xFF, 0x58, 0x04, 0x04, 0x02, 0x18, 0x08]

        let notes = project.tracks.compactMap(\.pattern).flatMap(\.notes)
            .sorted { $0.startBeat == $1.startBeat ? $0.pitch < $1.pitch : $0.startBeat < $1.startBeat }

        let ppq = 480.0
        var cursorTicks = 0

        for note in notes {
            let start = Int((note.startBeat * ppq).rounded())
            let duration = max(1, Int((note.durationBeats * ppq).rounded()))
            let delta = max(0, start - cursorTicks)
            trackData += variableLength(delta)
            trackData += [UInt8(0x90 | (note.channel & 0x0F)), UInt8(note.pitch), UInt8(max(1, min(127, note.velocity)))]
            trackData += variableLength(duration)
            trackData += [UInt8(0x80 | (note.channel & 0x0F)), UInt8(note.pitch), 0]
            cursorTicks = start + duration
        }

        trackData += [0x00, 0xFF, 0x2F, 0x00]

        var data = Array("MThd".utf8)
        data += bigEndian(6)
        data += bigEndian(0)
        data += bigEndian(UInt16(480))
        data += Array("MTrk".utf8)
        data += bigEndian(UInt32(trackData.count))
        data += trackData
        return Data(data)
    }

    private static func variableLength(_ value: Int) -> [UInt8] {
        var buffer = [UInt8(value & 0x7F)]
        var value = value >> 7
        while value > 0 {
            buffer.insert(UInt8((value & 0x7F) | 0x80), at: 0)
            value >>= 7
        }
        return buffer
    }

    private static func bigEndian(_ value: UInt16) -> [UInt8] {
        [UInt8(value >> 8), UInt8(value & 0xFF)]
    }

    private static func bigEndian(_ value: UInt32) -> [UInt8] {
        [UInt8((value >> 24) & 0xFF), UInt8((value >> 16) & 0xFF), UInt8((value >> 8) & 0xFF), UInt8(value & 0xFF)]
    }
}

extension Data {
    var midiBytes: [UInt8] { Array(self) }
}
