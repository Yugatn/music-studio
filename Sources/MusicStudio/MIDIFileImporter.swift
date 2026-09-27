import Foundation

enum MIDIImportError: Error {
    case invalidHeader
    case truncated
    case unsupportedFormat
    case invalidTrack
}

struct MIDIFileImporter {
    private struct Cursor {
        var bytes: [UInt8]
        var index: Int = 0

        mutating func readByte() throws -> UInt8 {
            guard index < bytes.count else { throw MIDIImportError.truncated }
            defer { index += 1 }
            return bytes[index]
        }

        mutating func read(_ count: Int) throws -> [UInt8] {
            guard count >= 0, index + count <= bytes.count else { throw MIDIImportError.truncated }
            let result = Array(bytes[index..<index + count])
            index += count
            return result
        }

        mutating func readUInt16() throws -> UInt16 {
            let b = try read(2)
            return UInt16(b[0]) << 8 | UInt16(b[1])
        }

        mutating func readUInt32() throws -> UInt32 {
            let b = try read(4)
            return UInt32(b[0]) << 24 | UInt32(b[1]) << 16 | UInt32(b[2]) << 8 | UInt32(b[3])
        }

        mutating func variableLength() throws -> Int {
            var value = 0
            for _ in 0..<4 {
                let byte = try readByte()
                value = (value << 7) | Int(byte & 0x7F)
                if byte & 0x80 == 0 { return value }
            }
            throw MIDIImportError.invalidTrack
        }
    }

    static func importProject(data: Data, name: String = "Imported MIDI") throws -> MusicProject {
        var cursor = Cursor(bytes: Array(data))
        guard try cursor.read(4) == Array("MThd".utf8) else { throw MIDIImportError.invalidHeader }
        guard try cursor.readUInt32() == 6 else { throw MIDIImportError.invalidHeader }

        let format = try cursor.readUInt16()
        let trackCount = try cursor.readUInt16()
        let division = try cursor.readUInt16()

        guard format <= 1, trackCount > 0, division > 0, (division & 0x8000) == 0 else {
            throw MIDIImportError.unsupportedFormat
        }

        let ppq = Int(division)
        var allNotes: [NoteEvent] = []
        var maxTick = 0
        var tempoBPM = 120.0

        for _ in 0..<trackCount {
            guard try cursor.read(4) == Array("MTrk".utf8) else { throw MIDIImportError.invalidTrack }
            let length = Int(try cursor.readUInt32())
            var track = Cursor(bytes: try cursor.read(length))

            var tick = 0
            var runningStatus: UInt8?
            var active: [String: (start: Int, velocity: Int, channel: Int)] = [:]

            while track.index < track.bytes.count {
                tick += try track.variableLength()
                maxTick = max(maxTick, tick)

                var status = try track.readByte()
                if status < 0x80 {
                    guard let runningStatus else { throw MIDIImportError.invalidTrack }
                    track.index -= 1
                    status = runningStatus
                } else if status < 0xF0 {
                    runningStatus = status
                }

                if status == 0xFF {
                    let metaType = try track.readByte()
                    let length = try track.variableLength()
                    let payload = try track.read(length)
                    if metaType == 0x51 && payload.count == 3 {
                        let micros = (Int(payload[0]) << 16) | (Int(payload[1]) << 8) | Int(payload[2])
                        if micros > 0 { tempoBPM = 60_000_000.0 / Double(micros) }
                    }
                    continue
                }

                if status == 0xF0 || status == 0xF7 {
                    let length = try track.variableLength()
                    _ = try track.read(length)
                    continue
                }

                let command = status & 0xF0
                let channel = Int(status & 0x0F)

                switch command {
                case 0x80, 0x90:
                    let pitch = try track.readByte()
                    let velocity = try track.readByte()
                    let key = "\(channel):\(pitch)"

                    if command == 0x90 && velocity > 0 {
                        active[key] = (tick, Int(velocity), channel)
                    } else if let note = active.removeValue(forKey: key) {
                        let duration = max(1, tick - note.start)
                        allNotes.append(
                            NoteEvent(
                                pitch: Int(pitch),
                                startBeat: Double(note.start) / Double(ppq),
                                durationBeats: Double(duration) / Double(ppq),
                                velocity: note.velocity,
                                channel: note.channel
                            )
                        )
                    }
                case 0xC0, 0xD0:
                    _ = try track.readByte()
                default:
                    _ = try track.readByte()
                    _ = try track.readByte()
                }
            }
        }

        let lengthBeats = max(4, ceil(Double(maxTick) / Double(ppq) / 4) * 4)
        let pattern = Pattern(
            name: "Imported MIDI",
            lengthBeats: lengthBeats,
            notes: allNotes.sorted {
                $0.startBeat == $1.startBeat ? $0.pitch < $1.pitch : $0.startBeat < $1.startBeat
            }
        )

        return MusicProject(
            name: name,
            bpm: min(240, max(40, tempoBPM)),
            key: "C",
            scale: "Major",
            tracks: [
                Track(id: UUID(), name: "MIDI Import", kind: .instrument, pattern: pattern)
            ]
        )
    }
}
