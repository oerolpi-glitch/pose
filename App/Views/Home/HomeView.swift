import SwiftUI

struct HomeView: View {
    var body: some View {
        Text("home")
            .font(Theme.Typography.header(34))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
    }
}
