import SwiftUI
import Bartinter

struct ContentView: View {
    private let shades: [Double] = [1.0, 0.8, 0.6, 0.4, 0.2, 0.0]
    @State private var index = 0

    var body: some View {
        ZStack {
            Color(white: shades[index]).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("Tap to change background")
                    .foregroundColor(shades[index] > 0.5 ? .black : .white)
                Button("Next") { index = (index + 1) % shades.count }
                    .accessibilityIdentifier("nextButton")
            }
        }
        .tintsStatusBar()
    }
}

#Preview {
    ContentView()
}
