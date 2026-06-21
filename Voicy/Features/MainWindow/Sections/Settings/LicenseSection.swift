import SwiftUI

/// Settings section for Voicy Pro: paste-and-activate a license key, or open the
/// checkout. When a license is stored it shows the active state and a deactivate
/// action instead. Pure UI — all logic lives in `SettingsLicenseViewModel`.
struct LicenseSection: View {
    @State private var viewModel = SettingsLicenseViewModel()

    var body: some View {
        SettingsSection(title: "Voicy Pro", caption: "Activate your license, or upgrade") {
            Group {
                if viewModel.hasLicense {
                    activatedContent
                } else {
                    activationContent
                }
            }
            .padding(.vertical, 16)
        }
        .onAppear { viewModel.onAppear() }
    }

    private var activationContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                TextField("Paste your license key", text: $viewModel.keyInput)
                    .textFieldStyle(.plain)
                    .font(DS.Font.mono(12))
                    .foregroundStyle(DS.Palette.ink)
                    .tint(DS.Palette.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(Color.black.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(DS.Palette.ruleSoft, lineWidth: 1))
                    .onSubmit { viewModel.activate() }

                Button(action: { viewModel.activate() }) {
                    Text(viewModel.phase == .activating ? "Activating…" : "Activate")
                        .font(DS.Font.sans(12, weight: .semibold))
                        .foregroundStyle(DS.Palette.paper)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(viewModel.canActivate ? DS.Palette.ink : DS.Palette.ink3, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canActivate)
            }

            if case .error(let message) = viewModel.phase {
                Text(message)
                    .font(DS.Font.sans(11))
                    .foregroundStyle(DS.Palette.accent)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: { viewModel.openCheckout() }) {
                Text("Get Voicy Pro →")
                    .font(DS.Font.sans(12, weight: .medium))
                    .foregroundStyle(DS.Palette.accent)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var activatedContent: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Active on this device")
                    .font(DS.Font.sans(13, weight: .semibold))
                    .foregroundStyle(DS.Palette.ink)
                if let email = viewModel.snapshot?.customerEmail {
                    Text(email)
                        .font(DS.Font.sans(11))
                        .foregroundStyle(DS.Palette.ink3)
                }
            }
            Spacer()
            Button(action: { viewModel.deactivate() }) {
                Text("Deactivate")
                    .font(DS.Font.sans(12, weight: .medium))
                    .foregroundStyle(DS.Palette.ink2)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .overlay(Capsule().stroke(DS.Palette.ruleSoft, lineWidth: 1))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}
