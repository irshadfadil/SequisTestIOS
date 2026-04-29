import SwiftUI

struct AppRootView: View {
    @State private var viewModel = AppDependencies.makeLaunchViewModel()

    var body: some View {
        ZStack {
            switch viewModel.phase {
            case .splash:
                SplashScreen()
                    .transition(.opacity.combined(with: .scale(scale: 1.03)))
            case .main:
                ImageListScreen(viewModel: viewModel.imageListViewModel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.45), value: viewModel.phase)
        .task {
            await viewModel.start()
        }
    }
}

#Preview {
    AppRootView()
}
