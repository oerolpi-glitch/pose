import SwiftUI

struct HomeView: View {
    var body: some View {
        Text("home")
            .font(Theme.Typography.screenTitle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
    }
}
