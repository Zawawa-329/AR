import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var inputName = ""

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("login_background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()

                VStack(spacing: 30) {
                    Text("おかえりなさい")
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .foregroundColor(.brown)
                    
                    TextField("あなたの名前を入力してね！", text: $inputName)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(15)
                        .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 40)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 18, design: .rounded))

                    Button(action: {
                        if !inputName.isEmpty {
                            appState.userNameStore = inputName
                            appState.isLoggedIn = true
                        }
                    }) {
                        Text("ログイン")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 60)
                            .background(Color.brown)
                            .cornerRadius(25)
                            .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .disabled(inputName.isEmpty)

                    Spacer()
                }
                .padding(.top, 100)
            }
            .onAppear {
                AudioManager.shared.playBGM(named: "bgm")  // ここでログイン用BGMを再生
            }
            .onDisappear {
                AudioManager.shared.stopBGM()
            }
        }
    }
}

