import SwiftUI

struct SettingsView: View {
    let viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showAirportPicker: Bool = false
    @State private var showAirlinePicker: Bool = false
    @State private var showNameEditor: Bool = false
    @State private var editingName: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                TurbyTurbulenceForecastTheme.calmBackground(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        profileSection
                        preferencesSection
                        subscriptionSection
                        aboutSection
                        legalSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.headline)
                }
            }
            .sheet(isPresented: $showAirportPicker) {
                AirportPickerView(selectedAirport: Binding(
                    get: { viewModel.homeAirport },
                    set: { viewModel.homeAirport = $0 }
                ))
            }
            .sheet(isPresented: $showAirlinePicker) {
                AirlinePickerView(selectedAirline: Binding(
                    get: { viewModel.favoriteAirline },
                    set: { viewModel.favoriteAirline = $0 }
                ))
            }
            .alert("Edit Name", isPresented: $showNameEditor) {
                TextField("First name", text: $editingName)
                    .textInputAutocapitalization(.words)
                Button("Save") {
                    viewModel.firstName = editingName.trimmingCharacters(in: .whitespaces)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter your first name")
            }
        }
    }

    private var airportDisplayValue: String {
        if let airport = viewModel.homeAirport {
            return "\(airport.name) (\(airport.iata))"
        }
        return "Not set"
    }

    private var airlineDisplayValue: String {
        if let airline = viewModel.favoriteAirline {
            return "\(airline.name) (\(airline.iata))"
        }
        return "Not set"
    }

    private var profileSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Your Profile", icon: "person.crop.circle.fill")

            VStack(spacing: 0) {
                settingsRow(
                    icon: "person.fill",
                    iconColor: Color(red: 0.4, green: 0.7, blue: 0.45),
                    title: "Name",
                    value: viewModel.firstName.isEmpty ? "Not set" : viewModel.firstName
                ) {
                    Button {
                        editingName = viewModel.firstName
                        showNameEditor = true
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }

                Divider().padding(.leading, 52)

                settingsRow(
                    icon: "heart.circle.fill",
                    iconColor: TurbyTurbulenceForecastTheme.accent,
                    title: "Passenger Type",
                    value: viewModel.passengerProfile.title
                ) {
                    Menu {
                        ForEach(PassengerProfile.allCases, id: \.self) { profile in
                            Button {
                                viewModel.passengerProfile = profile
                            } label: {
                                Label(profile.title, systemImage: profile.icon)
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }

                Divider().padding(.leading, 52)

                settingsRow(
                    icon: "airplane.circle.fill",
                    iconColor: TurbyTurbulenceForecastTheme.accentLight,
                    title: "Home Airport",
                    value: airportDisplayValue
                ) {
                    Button { showAirportPicker = true } label: {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }

                Divider().padding(.leading, 52)

                settingsRow(
                    icon: "star.circle.fill",
                    iconColor: Color(red: 0.95, green: 0.65, blue: 0.2),
                    title: "Favorite Airline",
                    value: airlineDisplayValue
                ) {
                    Button { showAirlinePicker = true } label: {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(.systemBackground).opacity(0.9))
                    .shadow(color: TurbyTurbulenceForecastTheme.cardShadow(for: colorScheme), radius: 12, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.6), lineWidth: 0.5)
            )
        }
    }

    private var preferencesSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Preferences", icon: "slider.horizontal.3")

            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    Image(systemName: "gauge.with.dots.needle.33percent")
                        .font(.title3)
                        .foregroundStyle(TurbyTurbulenceForecastTheme.turbulenceColor(for: .smooth))
                        .frame(width: 28)
                    Text("Pilot Mode")
                        .font(.subheadline)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { viewModel.isPilotMode },
                        set: { viewModel.isPilotMode = $0 }
                    ))
                    .labelsHidden()
                    .tint(TurbyTurbulenceForecastTheme.accent)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Divider().padding(.leading, 52)

                HStack(spacing: 14) {
                    Image(systemName: viewModel.appearanceMode.icon)
                        .font(.title3)
                        .foregroundStyle(Color(red: 0.55, green: 0.4, blue: 0.85))
                        .frame(width: 28)
                    Text("Appearance")
                        .font(.subheadline)
                    Spacer()
                    Menu {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Button {
                                viewModel.appearanceMode = mode
                            } label: {
                                Label(mode.title, systemImage: mode.icon)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.appearanceMode.title)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Divider().padding(.leading, 52)

                Button {
                    Task { await viewModel.notificationService.requestPermission() }
                } label: {
                    settingsRow(
                        icon: "bell.badge.fill",
                        iconColor: Color(red: 0.9, green: 0.3, blue: 0.3),
                        title: "Push Notifications",
                        value: "Manage"
                    ) {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(.systemBackground).opacity(0.9))
                    .shadow(color: TurbyTurbulenceForecastTheme.cardShadow(for: colorScheme), radius: 12, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.6), lineWidth: 0.5)
            )
        }
    }

    private var subscriptionSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Subscription", icon: "creditcard.fill")

            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    Image(systemName: viewModel.subscriptionService.isSubscribed ? "checkmark.seal.fill" : "lock.fill")
                        .font(.title3)
                        .foregroundStyle(viewModel.subscriptionService.isSubscribed ? TurbyTurbulenceForecastTheme.turbulenceColor(for: .smooth) : .orange)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.subscriptionService.isSubscribed ? "Active Subscription" : "Free Plan")
                            .font(.subheadline)
                        Text(viewModel.subscriptionService.isSubscribed ? "You have full access" : "Upgrade to unlock all features")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if !viewModel.subscriptionService.isSubscribed {
                        Button {
                            viewModel.showPaywall = true
                        } label: {
                            Text("Upgrade")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [TurbyTurbulenceForecastTheme.accent, TurbyTurbulenceForecastTheme.accentLight],
                                                startPoint: .leading, endPoint: .trailing
                                            )
                                        )
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Divider().padding(.leading, 52)

                Button {
                    Task {
                        _ = await viewModel.subscriptionService.restorePurchases()
                    }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                            .foregroundStyle(TurbyTurbulenceForecastTheme.accentLight)
                            .frame(width: 28)
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        if viewModel.subscriptionService.isProcessing {
                            ProgressView()
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.impact(weight: .light), trigger: viewModel.subscriptionService.isProcessing)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(.systemBackground).opacity(0.9))
                    .shadow(color: TurbyTurbulenceForecastTheme.cardShadow(for: colorScheme), radius: 12, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.6), lineWidth: 0.5)
            )
        }
    }

    private var aboutSection: some View {
        VStack(spacing: 0) {
            sectionHeader("About", icon: "info.circle.fill")

            VStack(spacing: 0) {
                infoRow(title: "Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                Divider().padding(.leading, 16)
                HStack {
                    Text("Made with")
                        .font(.subheadline)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                            .font(.subheadline)
                        Text("for nervous flyers")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(.systemBackground).opacity(0.9))
                    .shadow(color: TurbyTurbulenceForecastTheme.cardShadow(for: colorScheme), radius: 12, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.6), lineWidth: 0.5)
            )
        }
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
    }

    private func settingsRow<Accessory: View>(
        icon: String,
        iconColor: Color,
        title: String,
        value: String,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                Text(value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            accessory()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private var legalSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Legal", icon: "doc.text.fill")

            VStack(spacing: 0) {
                linkRow(title: "Privacy Policy", icon: "hand.raised.fill", iconColor: TurbyTurbulenceForecastTheme.accent, url: "https://turby.app/privacy")
                Divider().padding(.leading, 52)
                linkRow(title: "Terms of Use", icon: "doc.plaintext.fill", iconColor: Color(.secondaryLabel), url: "https://turby.app/terms")
                Divider().padding(.leading, 52)
                linkRow(title: "Licenses", icon: "text.badge.checkmark", iconColor: Color(red: 0.4, green: 0.7, blue: 0.45), url: "https://turby.app/licenses")
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(.systemBackground).opacity(0.9))
                    .shadow(color: TurbyTurbulenceForecastTheme.cardShadow(for: colorScheme), radius: 12, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.6), lineWidth: 0.5)
            )
        }
    }

    private func linkRow(title: String, icon: String, iconColor: Color, url: String) -> some View {
        Button {
            if let link = URL(string: url) {
                UIApplication.shared.open(link)
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
                    .frame(width: 28)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
