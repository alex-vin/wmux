public import SwiftUI

/// Injects the stored cmux font magnification percent into a SwiftUI subtree.
struct WmuxFontMagnificationEnvironmentModifier: ViewModifier {
    @AppStorage(GlobalFontMagnification.percentKey) private var percent = GlobalFontMagnification.defaultPercent

    func body(content: Content) -> some View {
        content.environment(\.cmuxGlobalFontMagnificationPercent, percent)
    }
}
