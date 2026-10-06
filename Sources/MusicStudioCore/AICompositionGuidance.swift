import Foundation

public enum MusicalEmotion: String, Codable, CaseIterable, Sendable {
    case calm, melancholic, joyful, energetic, tense, mysterious, triumphant, intimate, dreamy, aggressive
}

public enum MusicalStyle: String, Codable, CaseIterable, Sendable {
    case ambient, cinematic, electronic, house, techno, hipHop, rock, funk, jazz, classical, loFi, trance
}

public struct CompositionIntent: Codable, Sendable {
    public var styles: [MusicalStyle]
    public var emotions: [MusicalEmotion]
    public var energy: Double
    public var complexity: Double
    public var groove: Double
    public var brightness: Double
    public var humanization: Double
    public var references: [String]
    public var avoid: [String]

    public init(styles: [MusicalStyle] = [], emotions: [MusicalEmotion] = [], energy: Double = 0.5, complexity: Double = 0.5, groove: Double = 0.5, brightness: Double = 0.5, humanization: Double = 0.25, references: [String] = [], avoid: [String] = []) {
        self.styles=styles; self.emotions=emotions; self.energy=energy; self.complexity=complexity; self.groove=groove; self.brightness=brightness; self.humanization=humanization; self.references=references; self.avoid=avoid
    }
}

public struct CompositionRecommendation: Codable, Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let reason: String
    public let changes: [String]
    public let confidence: Double

    public init(id: UUID = UUID(), title: String, reason: String, changes: [String], confidence: Double) {
        self.id=id; self.title=title; self.reason=reason; self.changes=changes; self.confidence=confidence
    }
}

public protocol CompositionAdvisor: Sendable {
    func analyze(project: MusicProject, intent: CompositionIntent) async throws -> [CompositionRecommendation]
}

public struct LocalCompositionAdvisor: CompositionAdvisor {
    public init() {}

    public func analyze(project: MusicProject, intent: CompositionIntent) async throws -> [CompositionRecommendation] {
        let notes = project.tracks.compactMap { $0.pattern?.notes }.flatMap { $0 }
        let metrics = MusicalAnalyzer.analyze(project)
        guard !notes.isEmpty else {
            return [CompositionRecommendation(title: "Добавить музыкальное ядро", reason: "В проекте пока нет нот для анализа.", changes: ["Создать мелодический или ритмический материал"], confidence: 1)]
        }

        var result: [CompositionRecommendation] = []
        let velocities = notes.map(\.velocity)
        let averageVelocity = Double(velocities.reduce(0,+)) / Double(velocities.count)
        if intent.energy > 0.7 && averageVelocity < 85 {
            result.append(CompositionRecommendation(title: "Усилить динамику", reason: "Заявлена высокая энергия, но средняя velocity ниже ожидаемой.", changes: ["Поднять velocity ключевых нот", "Добавить контраст между сильными и слабыми долями"], confidence: 0.82))
        }
        if intent.humanization > 0.6 {
            result.append(CompositionRecommendation(title: "Добавить живое исполнение", reason: "Высокая степень humanization предполагает небольшие вариации timing и velocity.", changes: ["Внести микровариации timing", "Избегать одинаковой velocity"], confidence: 0.78))
        }
        if intent.complexity > 0.7 && notes.count < 12 {
            result.append(CompositionRecommendation(title: "Развить музыкальную фразу", reason: "Высокая сложность сочетается с небольшим количеством событий.", changes: ["Добавить ответную фразу", "Ввести ритмическую вариацию"], confidence: 0.71))
        }
        if intent.brightness > 0.7 {
            result.append(CompositionRecommendation(title: "Осветлить гармонический спектр", reason: "Для яркого характера можно увеличить долю высоких регистров.", changes: ["Добавить верхний голос", "Использовать более высокий регистр в кульминации"], confidence: 0.69))
        }
        if result.isEmpty {
            result.append(CompositionRecommendation(title: "Сохранить основу и варьировать детали", reason: "Текущий материал совместим с заданным намерением.", changes: ["Создать две небольшие вариации", "Сравнить их до фиксации результата"], confidence: 0.62))
        }
        return result
    }
}
