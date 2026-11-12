import SwiftUI

final class ThemeManager: ObservableObject {
    @AppStorage("appColorScheme") private var storedScheme: String = "system"

    var colorScheme: ColorScheme? {
        switch storedScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    func toggle() {
        switch storedScheme {
        case "light": storedScheme = "dark"
        case "dark": storedScheme = "system"
        default: storedScheme = "light"
        }
    }

    var iconName: String {
        switch storedScheme {
        case "light": return "sun.max.fill"
        case "dark": return "moon.fill"
        default: return "circle.lefthalf.filled"
        }
    }
}
