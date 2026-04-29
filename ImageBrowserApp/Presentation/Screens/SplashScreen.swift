import SwiftUI

struct SplashScreen: View {
    @State private var animateBadge = false
    @State private var animateGlow = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.29, green: 0.16, blue: 0.11),
                    Color(red: 0.76, green: 0.45, blue: 0.28),
                    Color(red: 0.97, green: 0.87, blue: 0.76),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 10)
                .scaleEffect(animateGlow ? 1.08 : 0.92)
                .animation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true), value: animateGlow)
                .accessibilityHidden(true)

            VStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 122, height: 122)
                        .overlay {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.white.opacity(0.22), lineWidth: 1)
                        }

                    Image(systemName: "photo.stack.fill")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(animateBadge ? 1 : 0.9)
                .opacity(animateBadge ? 1 : 0.7)

                VStack(spacing: 8) {
                    Text("Image Browser")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Curated images. Clean cards. Fast browsing.")
                        .font(.headline)
                        .foregroundStyle(Color.white.opacity(0.86))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(32)
        }
        .onAppear {
            animateGlow = true
            withAnimation(.spring(duration: 0.9, bounce: 0.28)) {
                animateBadge = true
            }
        }
    }
}

#Preview {
    SplashScreen()
}
