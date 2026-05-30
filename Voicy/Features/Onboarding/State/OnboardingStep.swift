import Foundation

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome
    case microphone
    case accessibility
    case fnKey
    case model
    case brain
    case language
    case practice

    var id: Int { rawValue }
}
