import Foundation

/// A reusable musical starting point. Presets guide generation; they do not promise a
/// specific emotional response and never replace the musician's decisions.
public struct CompositionPreset: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let summary: String
    public let intent: CompositionIntent
    public let instrumentation: [String]
    public let arrangementNotes: [String]
    public let avoid: [String]
    public let promptTemplate: String
    public let instrumentalByDefault: Bool

    public init(id: String, title: String, summary: String, intent: CompositionIntent, instrumentation: [String], arrangementNotes: [String], avoid: [String], promptTemplate: String, instrumentalByDefault: Bool = true) {
        self.id = id
        self.title = title
        self.summary = summary
        self.intent = intent
        self.instrumentation = instrumentation
        self.arrangementNotes = arrangementNotes
        self.avoid = avoid
        self.promptTemplate = promptTemplate
        self.instrumentalByDefault = instrumentalByDefault
    }
}

/// First-party sound palettes. They remain editable and provider-neutral.
public enum CompositionPresets {
    public static let all: [CompositionPreset] = [
        CompositionPreset(
            id: "shamanic-cinematic", title: "Шаманский кинематографический ритуал",
            summary: "Глубокая ритуальная пульсация, пространство и постепенное раскрытие темы.",
            intent: CompositionIntent(styles: [.cinematic, .ambient], emotions: [.mysterious, .intimate, .triumphant], energy: 0.62, complexity: 0.48, groove: 0.82, brightness: 0.32, humanization: 0.72, references: ["shamanic percussion", "cinematic strings", "organic ritual ambience"], avoid: ["busy pop drums", "cheerful commercial hooks", "unrequested vocals"]),
            instrumentation: ["deep shamanic frame drums as the dominant pulse", "jaw harp or vargan as a dry, repeating motif", "warm acoustic guitar in sparse phrases", "low strings and distant atmospheric textures", "subtle drones and restrained natural ambience"],
            arrangementNotes: ["Open with space, low drone and a distant pulse.", "Introduce the main drum pattern before adding melodic layers.", "Let the jaw harp establish a hypnotic ostinato; guitar answers rather than competes.", "Build intensity through layered percussion, register and harmonic tension, not constant loudness.", "Reach one clear cinematic peak, then remove layers gradually and leave a resonant ending."],
            avoid: ["No lead vocal by default.", "No wall-to-wall percussion; preserve dynamic breathing room.", "No abrupt genre switch or overly bright pop production."],
            promptTemplate: "Instrumental shamanic cinematic meditation. Deep frame drums dominate with a grounded, hypnotic pulse; dry jaw harp (vargan) ostinato; sparse warm acoustic guitar; low cinematic strings; dark atmospheric drones. Organic, spacious, ancient and intimate, with gradual tension and one emotionally powerful orchestral peak. Human timing, deep low end, natural transients, wide but uncluttered space, slow evolving arrangement, resonant outro. No lead vocals, no pop beat, no glossy EDM drop."
        ),
        CompositionPreset(
            id: "dark-matrix-ambient", title: "Тёмная матрица",
            summary: "Медленный электронный пульс, фрактальные повторения и ощущение виртуальной реальности.",
            intent: CompositionIntent(styles: [.ambient, .electronic, .cinematic], emotions: [.mysterious, .tense, .dreamy], energy: 0.42, complexity: 0.66, groove: 0.58, brightness: 0.18, humanization: 0.28, references: ["dark ambient", "minimal pulse", "fractal repetition", "cinematic sound design"], avoid: ["festival EDM drop", "bright major-key pop", "constant dense percussion"]),
            instrumentation: ["sub-bass pulse with controlled movement", "granular or bit-crushed texture used sparingly", "slow analog-style pads", "distant metallic resonances and reversed tails", "minimal percussion with occasional ritual drum accents"],
            arrangementNotes: ["Begin almost empty and let small details emerge from the noise floor.", "Use repetition with tiny timbral changes to suggest a living system.", "Keep the bass pulse stable while upper layers drift.", "Use silence and filtering as structural events.", "End with an unresolved but intentional residual texture."],
            avoid: ["No horror stingers or random jumpscares.", "No overly bright synth leads.", "No vocals unless requested."],
            promptTemplate: "Instrumental dark ambient and cinematic electronic soundscape about a virtual reality matrix. Slow sub-bass pulse, granular black-code textures, restrained metallic resonances, analog drones and minimal ritual percussion. Hypnotic fractal repetition with tiny evolving details, deep negative space, low brightness, subtle tension, no conventional pop chorus and no festival drop. Carefully controlled low end, long evolving transitions, unresolved atmospheric ending. No vocals."
        ),
        CompositionPreset(
            id: "existential-guitar-cinema", title: "Экзистенциальная гитарная киномузыка",
            summary: "Живая гитара, струнные и мелодия о памяти, выборе и продолжении пути.",
            intent: CompositionIntent(styles: [.cinematic, .rock, .classical], emotions: [.melancholic, .intimate, .triumphant], energy: 0.58, complexity: 0.52, groove: 0.46, brightness: 0.44, humanization: 0.78, references: ["expressive guitar", "cinematic orchestration", "slow-building existential theme"], avoid: ["virtuosic shredding throughout", "over-compressed drums", "sentimental stock-music clichés"]),
            instrumentation: ["expressive electric or acoustic guitar as the main voice", "warm cello and restrained violin layers", "low toms or frame drum for selected climactic accents", "bass that supports the melodic contour", "subtle atmospheric bed"],
            arrangementNotes: ["State a simple memorable motif on a relatively exposed guitar.", "Repeat the motif with changed harmony or register rather than replacing it.", "Let strings answer the guitar and widen the emotional frame.", "Reserve the strongest percussion for the final third.", "Return to a reduced version of the opening motif at the end."],
            avoid: ["No constant shredding or excessive soloing.", "No forced happy resolution.", "No lead vocal by default."],
            promptTemplate: "Instrumental existential cinematic guitar piece. An expressive, human guitar motif carries the story, supported by warm cello, restrained violin, deep bass and occasional low frame-drum accents. Melancholic, intimate and searching, gradually becoming resolute without turning into triumphal cliché. Organic performance, audible phrasing and breath, evolving harmony, a carefully earned peak, then a quiet return to the opening motif. Dynamic, spacious mix; no constant shredding, no glossy pop drums, no vocals."
        )
    ]

    public static func preset(id: String) -> CompositionPreset? {
        all.first { $0.id == id }
    }
}
