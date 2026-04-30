import SwiftUI

struct SplashScreen: View {
    @State private var settleBranding = false
    @State private var revealSubtitle = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.96, blue: 0.92),
                    Color(red: 0.88, green: 0.95, blue: 0.92),
                    Color(red: 0.76, green: 0.94, blue: 0.95),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white.opacity(0.28))
                        .frame(width: 128, height: 128)
                        .overlay {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.white.opacity(0.42), lineWidth: 1)
                        }

                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.clear)
                        .frame(width: 128, height: 128)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color(red: 0.18, green: 0.34, blue: 0.37), lineWidth: 2)
                                .frame(width: 22, height: 22)
                                .offset(y: -10)
                        }
                }
                .scaleEffect(settleBranding ? 1 : 0.96)

                VStack(spacing: 8) {
                    Text("Image Browser")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.18, green: 0.34, blue: 0.37))
                        .scaleEffect(settleBranding ? 1 : 0.985)

                    Text("Curated images. Clean cards. Fast browsing.")
                        .font(.headline)
                        .foregroundStyle(Color(red: 0.18, green: 0.34, blue: 0.37).opacity(0.72))
                        .multilineTextAlignment(.center)
                        .opacity(revealSubtitle ? 1 : 0)
                        .offset(y: revealSubtitle ? 0 : 8)
                }
            }
            .padding(32)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("splash-screen")
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                settleBranding = true
            }

            withAnimation(.easeOut(duration: 0.45).delay(0.12)) {
                revealSubtitle = true
            }
        }
    }
}

#Preview {
    SplashScreen()
}
