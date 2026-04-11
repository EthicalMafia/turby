import SwiftUI

struct OnboardingNamePage: View {
    let viewModel: AppViewModel
    @Binding var currentPage: Int
    @State private var appeared = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, options: .repeating.speed(0.5))

                Text("What's your first name?")
                    .font(.system(.title, design: .default, weight: .bold))
                    .foregroundStyle(.white)

                Text("We'll personalize your experience")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
            }

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 24)

                    TextField("", text: Binding(
                        get: { viewModel.firstName },
                        set: { viewModel.firstName = $0 }
                    ), prompt: Text("Your first name").foregroundStyle(.white.opacity(0.45)))
                    .foregroundStyle(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .focused($isFocused)
                    .submitLabel(.continue)
                    .onSubmit {
                        if !viewModel.firstName.trimmingCharacters(in: .whitespaces).isEmpty {
                            withAnimation(.snappy) { currentPage += 1 }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.white.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 24)

            if !viewModel.firstName.trimmingCharacters(in: .whitespaces).isEmpty {
                Button {
                    isFocused = false
                    withAnimation(.snappy) { currentPage += 1 }
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white.opacity(0.25))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(.white.opacity(0.4), lineWidth: 1)
                                )
                        )
                }
                .padding(.horizontal, 24)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { isFocused = true }
        }
    }
}
