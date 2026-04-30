import SwiftUI

struct ImageDetailScreen: View {
    @State private var viewModel: ImageDetailViewModel

    init(viewModel: ImageDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            imageSection
            commentsSection
        }
        .listStyle(.plain)
        .navigationTitle("Image Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await viewModel.addComment()
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier("add-comment-button")
            }
        }
        .alert(
            "Unable to Add Comment",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { shouldShow in
                    if !shouldShow {
                        viewModel.errorMessage = nil
                    }
                }
            ),
            actions: {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            },
            message: {
                Text(viewModel.errorMessage ?? "Unable to add comment.")
            }
        )
        .task {
            viewModel.loadComments()
        }
    }

    private var imageSection: some View {
        AsyncImage(url: viewModel.image.detailImageURL) { phase in
            switch phase {
            case .empty:
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.94, green: 0.91, blue: 0.86), Color(red: 0.88, green: 0.84, blue: 0.79)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        ProgressView()
                            .tint(.white)
                    }
            case let .success(image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                Color(red: 0.87, green: 0.86, blue: 0.83)
                    .overlay {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
            @unknown default:
                Color(red: 0.87, green: 0.86, blue: 0.83)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 250)
        .clipped()
        .listRowInsets(.init())
        .listRowSeparator(.hidden)
        .accessibilityIdentifier("detail-image")
    }

    private var commentsSection: some View {
        ForEach(Array(viewModel.comments.enumerated()), id: \.element.id) { index, comment in
            CommentRowView(
                comment: comment,
                relativeDateText: viewModel.relativeDateText(for: comment),
                index: index
            )
            .swipeActions {
                Button(role: .destructive) {
                    viewModel.deleteComment(id: comment.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

private struct CommentRowView: View {
    let comment: CommentItem
    let relativeDateText: String
    let index: Int

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(comment.initials)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(Color.black.opacity(0.24))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(comment.authorName)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.black)
                    .accessibilityIdentifier("comment-author-\(index)")

                Text(comment.content)
                    .font(.body)
                    .foregroundStyle(Color.black.opacity(0.86))
                    .fixedSize(horizontal: false, vertical: true)

                Text(relativeDateText)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.black.opacity(0.32))
                    .accessibilityIdentifier("comment-date-\(index)")
            }
        }
        .padding(.vertical, 6)
        .accessibilityIdentifier("comment-row-\(index)")
    }
}

#Preview {
    NavigationStack {
        ImageDetailScreen(
            viewModel: AppDependencies.makeDetailViewModel(for: ImageItem.stubItems[0])
        )
    }
}
