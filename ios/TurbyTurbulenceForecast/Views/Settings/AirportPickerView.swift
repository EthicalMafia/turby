import SwiftUI

struct AirportPickerView: View {
    @Binding var selectedAirport: AirportInfo?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""

    private var filteredAirports: [AirportInfo] {
        if searchText.isEmpty {
            return Array(AirportDatabase.allAirports.prefix(50))
        }
        return AirportDatabase.search(searchText)
    }

    var body: some View {
        NavigationStack {
            List {
                if let current = selectedAirport {
                    Section {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(current.iata)
                                    .font(.headline)
                                Text(current.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(current.subtitle)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
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
                    if filteredAirports.isEmpty && !searchText.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    } else {
                        ForEach(filteredAirports) { airport in
                            Button {
                                selectedAirport = airport
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Text(airport.iata)
                                        .font(.headline.monospaced())
                                        .foregroundStyle(Color(red: 0.22, green: 0.45, blue: 0.78))
                                        .frame(width: 44, alignment: .leading)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(airport.name)
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                        Text(airport.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if selectedAirport?.iata == airport.iata {
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
                        Text("Popular Airports")
                    } else {
                        Text("\(filteredAirports.count) results")
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search by code, city, or name")
            .navigationTitle("Home Airport")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if selectedAirport != nil {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear") {
                            selectedAirport = nil
                            dismiss()
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
        }
    }
}
