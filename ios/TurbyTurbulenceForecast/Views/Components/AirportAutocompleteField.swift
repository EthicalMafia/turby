import SwiftUI

struct AirportAutocompleteField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    let onAirportSelected: (AirportInfo) -> Void
    @State private var suggestions: [AirportInfo] = []
    @State private var showSuggestions: Bool = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                TextField(placeholder, text: $text)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .focused($isFocused)
                if !text.isEmpty {
                    Button {
                        text = ""
                        suggestions = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )

            if showSuggestions && !suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(suggestions.prefix(6).enumerated()), id: \.element.id) { index, airport in
                        Button {
                            text = airport.iata
                            showSuggestions = false
                            isFocused = false
                            onAirportSelected(airport)
                        } label: {
                            HStack(spacing: 12) {
                                Text(airport.iata)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.primary)
                                    .frame(width: 40, alignment: .leading)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(airport.name)
                                        .font(.caption)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Text(airport.subtitle)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.quaternary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                        }
                        if index < min(suggestions.count, 6) - 1 {
                            Divider().padding(.leading, 14)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                )
                .padding(.top, 4)
            }
        }
        .onChange(of: text) { _, newValue in
            let trimmed = newValue.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                suggestions = []
                showSuggestions = false
            } else {
                suggestions = AirportDatabase.search(trimmed)
                showSuggestions = isFocused && !suggestions.isEmpty
            }
        }
        .onChange(of: isFocused) { _, focused in
            if focused && !text.trimmingCharacters(in: .whitespaces).isEmpty {
                suggestions = AirportDatabase.search(text.trimmingCharacters(in: .whitespaces))
                showSuggestions = !suggestions.isEmpty
            } else if !focused {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showSuggestions = false
                }
            }
        }
    }
}
