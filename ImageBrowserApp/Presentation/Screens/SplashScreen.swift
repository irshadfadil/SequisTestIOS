import SwiftUI

struct SplashScreen: View {
    @State private var animatePolish = false
    @State private var animateGlowPulse = false

    var body: some View {
        ZStack {
            splashBaseColor
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color(red: 0.43, green: 0.24, blue: 0.17),
                    Color(red: 0.76, green: 0.48, blue: 0.32),
                    Color(red: 0.97, green: 0.85, blue: 0.74),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(animatePolish ? 1 : 0)
            .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 10)
                .opacity(animatePolish ? 1 : 0)
                .scaleEffect(animateGlowPulse ? 1.08 : 0.95)
                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: animateGlowPulse)
                .accessibilityHidden(true)

            VStack(spacing: 18) {
                ZStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 128, height: 128)
                        .overlay {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.white.opacity(0.22), lineWidth: 1)
                        }

                    RoundedRectangle(cornerRadius: animatePolish ? 28 : 6, style: .continuous)
                        .fill(Color.clear)
                        .frame(width: 128, height: 128)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.white.opacity(0.92), lineWidth: 2)
                                .frame(width: 22, height: 22)
                                .offset(y: -10)
                        }
                }

                VStack(spacing: 8) {
                    Text("Image Browser")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Curated images. Clean cards. Fast browsing.")
                        .font(.headline)
                        .foregroundStyle(Color.white.opacity(0.86))
                        .multilineTextAlignment(.center)
                        .opacity(animatePolish ? 1 : 0)
                        .offset(y: animatePolish ? 0 : -6)
                }
            }
            .padding(32)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("splash-screen")
        .onAppear {
            animateGlowPulse = true
            withAnimation(.easeOut(duration: 0.45)) {
                animatePolish = true
            }
        }
    }

    private var splashBaseColor: Color {
        Color(red: 0.92, green: 0.78, blue: 0.63)
    }
}

#Preview {
    SplashScreen()
}
