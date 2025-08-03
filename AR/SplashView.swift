import SwiftUI

struct SplashView: View {
    @State private var isActive = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack {
                Spacer()

                Image("logo2")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .opacity(isActive ? 1 : 0)
                    .scaleEffect(isActive ? 1 : 0.8)
                    .animation(.easeIn(duration: 1.2), value: isActive)

                Spacer()
            }
        }
        .onAppear {
            isActive = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    AppState.shared.showSplash = false
                }
            }
        }
    }
}

