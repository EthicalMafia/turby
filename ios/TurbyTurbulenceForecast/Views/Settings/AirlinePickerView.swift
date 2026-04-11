import SwiftUI

struct AirlinePickerView: View {
    @Binding var selectedAirline: AirlineInfo?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""

    private var filteredAirlines: [AirlineInfo] {
        if searchText.isEmpty {
            return Array(AirlineDatabase.allAirlines.prefix(50))
        }
        return AirlineDatabase.search(searchText)
    }

    var body: some View {
        NavigationStack {
            List {
                if let current = selectedAirline {
                    Section {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(current.name)
                                    .font(.headline)
                                Text("\(current.iata) · \(current.country)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color(red: 0.22, green: 0.45, blue: 0.78))
                        }
                    } header: {
                        Text("Current Selection")
                    }
                }

                Section {
                    if filteredAirlines.isEmpty && !searchText.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    } else {
                        ForEach(filteredAirlines) { airline in
                            Button {
                                selectedAirline = airline
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Text(airline.iata)
                                        .font(.headline.monospaced())
                                        .foregroundStyle(Color(red: 0.22, green: 0.45, blue: 0.78))
                                        .frame(width: 36, alignment: .leading)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(airline.name)
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                        Text(airline.country)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if selectedAirline?.iata == airline.iata {
                                        Image(systemName: "checkmark")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Color(red: 0.22, green: 0.45, blue: 0.78))
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    if searchText.isEmpty {
                        Text("Popular Airlines")
                    } else {
                        Text("\(filteredAirlines.count) results")
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search by name, code, or country")
            .navigationTitle("Favorite Airline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if selectedAirline != nil {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear") {
                            selectedAirline = nil
                            dismiss()
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
        }
    }
}
