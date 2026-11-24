import SwiftUI

struct RootView: View {
    @Environment(StationLibrary.self) private var library
    @State private var tab: Tab = .radio
    @State private var logoTaps = 0
    @State private var showUnlock = false

    enum Tab: String, CaseIterable {
        case radio = "Radio", stations = "Sender", library = "Sammlung"
        var icon: String {
            switch self {
            case .radio: "dot.radiowaves.left.and.right"
            case .stations: "list.bullet.rectangle"
            case .library: "music.note.house"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                SunsetBackground()
                VStack(spacing: 0) {
                    header
                    Group {
                        switch tab {
                        case .radio:
                            VStack {
                                Spacer(minLength: 0)
                                RadioWheelView().padding(.horizontal, 8)
                                Spacer(minLength: 140)
                            }
                        case .stations: StationListView()
                        case .library: LibraryView()
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
                VStack(spacing: 10) {
                    NowPlayingBar()
                    tabBar
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(Vice.teal)
        .alert("Geheimsender freigeschaltet", isPresented: $showUnlock) {
            Button("Einschalten") {}
        } message: {
            Text("The Vault Radio ist jetzt im Radio-Rad.")
        }
    }

    private var header: some View {
        HStack {
            ViceLogo()
                .onTapGesture {
                    logoTaps += 1
                    if logoTaps >= 5, !library.vaultUnlocked {
                        library.vaultUnlocked = true
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        showUnlock = true
                    }
                }
            Spacer()
            Text("LEONIDA · VI")
                .font(.vice(13, weight: .heavy))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .overlay(Capsule().strokeBorder(Vice.teal.opacity(0.7)))
        }
        .padding(.horizontal)
        .padding(.top, 6)
    }

    private var tabBar: some View {
        HStack {
            ForEach(Tab.allCases, id: \.self) { item in
                Button {
                    withAnimation(.snappy) { tab = item }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: item.icon).font(.system(size: 19, weight: .semibold))
                        Text(item.rawValue.uppercased()).font(.vice(12, weight: .heavy))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(tab == item ? AnyShapeStyle(Vice.logo) : AnyShapeStyle(Color.white.opacity(0.6)))
                    .background {
                        if tab == item {
                            Capsule().fill(Color.white.opacity(0.08))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(.black.opacity(0.55), in: Capsule())
        .overlay(Capsule().strokeBorder(LinearGradient(colors: [Vice.sunsetPink, Vice.teal], startPoint: .leading, endPoint: .trailing).opacity(0.6)))
    }
}
