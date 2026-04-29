import Foundation
import Observation

@Observable
@MainActor
final class AppLaunchViewModel {
    typealias SleepHandler = @Sendable (Duration) async -> Void

    private let minimumSplashDuration: Duration
    private let sleep: SleepHandler
    private var hasStarted = false

    private(set) var phase: AppPhase = .splash
    let imageListViewModel: ImageListViewModel

    init(
        imageListViewModel: ImageListViewModel,
        minimumSplashDuration: Duration,
        sleep: @escaping SleepHandler
    ) {
        self.imageListViewModel = imageListViewModel
        self.minimumSplashDuration = minimumSplashDuration
        self.sleep = sleep
    }

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true

        _ = Task {
            await imageListViewModel.loadImages()
        }
        await Task.yield()

        await sleep(minimumSplashDuration)
        phase = .main
    }
}
