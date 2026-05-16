import Foundation

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome
    case microphone
    case accessibility
    case model
    case brain
    case language
    case practice
    case allSet

    var id: Int { rawValue }

    var chapter: String { String(format: "%02d", rawValue) }

    var title: String {
        switch self {
        case .welcome:       return "Welcome"
        case .microphone:    return "Microphone"
        case .accessibility: return "Accessibility"
        case .model:         return "Voice model"
        case .brain:         return "The brain"
        case .language:      return "Language"
        case .practice:      return "First dictation"
        case .allSet:        return "All set"
        }
    }

    var shortLabel: String {
        switch self {
        case .welcome:       return "Welcome"
        case .microphone:    return "Microphone"
        case .accessibility: return "Access"
        case .model:         return "Voice"
        case .brain:         return "Brain"
        case .language:      return "Language"
        case .practice:      return "First word"
        case .allSet:        return "Ready"
        }
    }
}
