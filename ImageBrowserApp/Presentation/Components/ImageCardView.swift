import SwiftUI

struct ImageCardView: View {
    let item: ImageItem
    let index: Int

    var body: some View {
        HStack(spacing: 0) {
            imagePanel

            VStack(spacing: 6) {
                Text("Author:")
                    .font(.headline)
                    .foregroundStyle(Color.black.opacity(0.82))

                Text(item.author)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .accessibilityIdentifier("author-label-\(index)")
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity, minHeight: 104, maxHeight: 104)
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Author \(item.author)")
    }

    private var imagePanel: some View {
        AsyncImage(url: item.thumbnailURL) { phase in
            switch phase {
            case .empty:
                placeholder
            case let .success(image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                fallback
            @unknown default:
                fallback
            }
        }
        .frame(width: 104, height: 104)
        .clipped()
    }

    private var placeholder: some View {
        LinearGradient(
            colors: [Color(red: 0.94, green: 0.91, blue: 0.86), Color(red: 0.88, green: 0.84, blue: 0.79)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Image(systemName: "photo")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.8))
                .accessibilityHidden(true)
        }
    }

    private var fallback: some View {
        Color(red: 0.87, green: 0.86, blue: 0.83)
            .overlay {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
    }
}

#Preview {
    ImageCardView(item: ImageItem.stubItems[0], index: 0)
        .padding()
        .background(Color(red: 0.96, green: 0.95, blue: 0.93))
}
