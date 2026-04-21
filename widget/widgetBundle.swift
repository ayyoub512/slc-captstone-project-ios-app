import SwiftUI
import WidgetKit

@main
struct VibeWidgetBundle: WidgetBundle {
    var body: some Widget {
        VibeWidget()
        // widgetControl() — remove, it's tutorial boilerplate
        // widgetLiveActivity() — keep commented until you need it
    }
}
