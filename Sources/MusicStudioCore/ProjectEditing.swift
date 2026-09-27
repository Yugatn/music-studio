import Foundation

public enum ProjectEditing {
    public static func addNote(to project: inout MusicProject, trackID: UUID? = nil, pitch: Int, startBeat: Double, durationBeats: Double = 0.5, velocity: Int = 96) -> UUID? {
        guard let index = project.tracks.firstIndex(where: { trackID == nil ? true : $0.id == trackID }),
              project.tracks[index].pattern != nil else { return nil }
        var pattern = project.tracks[index].pattern!
        let duration = max(0.05, min(durationBeats, pattern.lengthBeats))
        let start = max(0, min(pattern.lengthBeats - duration, startBeat))
        let note = NoteEvent(pitch: max(0, min(127, pitch)), startBeat: start, durationBeats: duration, velocity: max(1, min(127, velocity)))
        pattern.notes.append(note)
        project.tracks[index].pattern = pattern
        return note.id
    }

    public static func moveNote(to project: inout MusicProject, noteID: UUID, pitch: Int? = nil, startBeat: Double? = nil) {
        for trackIndex in project.tracks.indices {
            guard var pattern = project.tracks[trackIndex].pattern,
                  let noteIndex = pattern.notes.firstIndex(where: { $0.id == noteID }) else { continue }
            var note = pattern.notes[noteIndex]
            if let pitch { note.pitch = max(0, min(127, pitch)) }
            if let startBeat { note.startBeat = max(0, min(pattern.lengthBeats - note.durationBeats, startBeat)) }
            pattern.notes[noteIndex] = note
            project.tracks[trackIndex].pattern = pattern
            return
        }
    }

    public static func resizeNote(to project: inout MusicProject, noteID: UUID, durationBeats: Double) {
        for trackIndex in project.tracks.indices {
            guard var pattern = project.tracks[trackIndex].pattern,
                  let noteIndex = pattern.notes.firstIndex(where: { $0.id == noteID }) else { continue }
            var note = pattern.notes[noteIndex]
            note.durationBeats = max(0.05, min(durationBeats, pattern.lengthBeats - note.startBeat))
            pattern.notes[noteIndex] = note
            project.tracks[trackIndex].pattern = pattern
            return
        }
    }

    public static func deleteNote(from project: inout MusicProject, noteID: UUID) {
        for trackIndex in project.tracks.indices {
            guard var pattern = project.tracks[trackIndex].pattern else { continue }
            if pattern.notes.contains(where: { $0.id == noteID }) {
                pattern.notes.removeAll { $0.id == noteID }
                project.tracks[trackIndex].pattern = pattern
                return
            }
        }
    }
}
