import SwiftUI

struct AppRootView: View {
    @State private var viewModel = AppDependencies.makeLaunchViewModel()

    var body: some View {
        ZStack {
            ImageListScreen(viewModel: viewModel.imageListViewModel)
                .allowsHitTesting(viewModel.phase == .main)
                .accessibilityHidden(viewModel.phase != .main)

            if viewModel.phase != .main {
                SplashScreen()
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.15), value: viewModel.phase)
        .task {
            await viewModel.start()
        }
    }
}

#Preview {
    AppRootView()
}
