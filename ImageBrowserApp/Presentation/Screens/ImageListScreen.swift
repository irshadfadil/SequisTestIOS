import SwiftUI

struct ImageListScreen: View {
    let viewModel: ImageListViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.96, green: 0.95, blue: 0.93)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    content
                }
            }
            .navigationTitle("Image List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarVisibility(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("Image List")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .accessibilityIdentifier("image-list-title")

            Text("Browse beautifully framed photos by author")
                .font(.subheadline)
                .foregroundStyle(Color.black.opacity(0.58))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 18)
        .padding(.bottom, 18)
        .background(
            LinearGradient(
                colors: [Color.white, Color(red: 0.96, green: 0.95, blue: 0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .bottom) {
            Divider()
                .overlay(Color.black.opacity(0.08))
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .initialLoading:
            cardsScroll {
                ForEach(0 ..< 7, id: \.self) { _ in
                    PlaceholderCardView()
                }
            }
        case let .loaded(feed):
            if feed.items.isEmpty {
                emptyState
            } else {
                cardsScroll {
                    ForEach(Array(feed.items.enumerated()), id: \.element.id) { index, item in
                        NavigationLink {
                            ImageDetailScreen(
                                viewModel: AppDependencies.makeDetailViewModel(for: item)
                            )
                        } label: {
                            ImageCardView(item: item, index: index)
                        }
                        .accessibilityIdentifier("image-card-\(index)")
                        .buttonStyle(.plain)
                        .onAppear {
                            Task {
                                await viewModel.loadMoreIfNeeded(currentItemID: item.id)
                            }
                        }
                    }

                    PaginationFooterView(
                        feed: feed,
                        retry: {
                            Task {
                                await viewModel.retryLoadMore()
                            }
                        }
                    )
                }
            }
        case let .error(message):
            errorState(message: message)
        }
    }

    private func cardsScroll<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                content()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 18)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Images Yet",
            systemImage: "photo.on.rectangle",
            description: Text("The feed is empty right now.")
        )
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 18) {
            Spacer()

            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(Color(red: 0.51, green: 0.29, blue: 0.21))
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Unable to Load Images")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.black)

                Text(message)
                    .font(.body)
                    .foregroundStyle(Color.black.opacity(0.64))
                    .multilineTextAlignment(.center)
            }

            Button {
                Task {
                    await viewModel.retry()
                }
            } label: {
                Text("Retry")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .background(Color(red: 0.52, green: 0.30, blue: 0.21))
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 18))
            .accessibilityIdentifier("retry-button")
            .padding(.horizontal, 28)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

private struct PlaceholderCardView: View {
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.08), Color.black.opacity(0.14)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 104, height: 104)

            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.black.opacity(0.08))
                    .frame(width: 84, height: 18)

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.12))
                    .frame(width: 140, height: 24)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, minHeight: 104, maxHeight: 104)
        .background(Color.white.opacity(0.92))
        .clipShape(.rect(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
        .redacted(reason: .placeholder)
        .accessibilityHidden(true)
    }
}

private struct PaginationFooterView: View {
    let feed: ImageFeedState
    let retry: () -> Void

    var body: some View {
        Group {
            if feed.isLoadingMore {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(Color(red: 0.52, green: 0.30, blue: 0.21))

                    Text("Loading more images...")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.black.opacity(0.62))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .accessibilityIdentifier("load-more-progress")
            } else if let message = feed.loadMoreError {
                VStack(spacing: 10) {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(Color.black.opacity(0.62))
                        .multilineTextAlignment(.center)

                    Button(action: retry) {
                        Text("Retry Loading More")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                    }
                    .buttonStyle(.plain)
                    .background(Color(red: 0.52, green: 0.30, blue: 0.21))
                    .foregroundStyle(.white)
                    .clipShape(.rect(cornerRadius: 18))
                    .accessibilityIdentifier("load-more-retry-button")
                }
                .padding(.top, 6)
            } else {
                Color.clear
                    .frame(height: 1)
                    .accessibilityHidden(true)
            }
        }
    }
}

#Preview("Loaded") {
    ImageListScreen(
        viewModel: ImageListViewModel(
            fetchImagesUseCase: FetchImagesUseCase(
                repository: RemoteImageRepository(apiClient: PreviewImageAPIClient())
            )
        )
    )
}

private struct PreviewImageAPIClient: ImageAPIClient {
    func fetchImages(page: Int, limit: Int) async throws -> [ImageResponseDTO] {
        let startIndex = max((page - 1) * limit, 0)
        let items = Array(ImageItem.stubItems.dropFirst(startIndex).prefix(limit))

        return items.map { item in
            ImageResponseDTO(
                id: item.id,
                author: item.author,
                width: item.width,
                height: item.height,
                url: item.sourceURL.absoluteString,
                downloadURL: item.downloadURL.absoluteString
            )
        }
    }
}
