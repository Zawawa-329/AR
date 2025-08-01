//
//  LoginView.swift
//  AR
//
//  Created by 小池紗矢 on 2025/08/01.
//
import SwiftUI
import AVFoundation

var bgmPlayer: AVAudioPlayer?

// BGM 再生関数
func playBGM() {
    guard let url = Bundle.main.url(forResource: "sample1", withExtension: "mp3") else {
        print("BGM ファイルが見つかりません")
        return
    }

    do {
        bgmPlayer = try AVAudioPlayer(contentsOf: url)
        bgmPlayer?.numberOfLoops = -1  // ループ再生
        bgmPlayer?.play()
    } catch {
        print("BGM 再生エラー: \(error.localizedDescription)")
    }
}


struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var inputName: String = ""
    
    private let fullText = "お帰りなさい"
    @State private var displayedText = ""
    @State private var charIndex = 0

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.pink.opacity(0.3), Color.white]),
                           startPoint: .top,
                           endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                
                // 🎀 一文字ずつ表示
                Text(displayedText)
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .foregroundColor(.purple)
                    .animation(.easeIn(duration: 0.2), value: displayedText)

                // ✏️ 名前入力欄
                TextField("あなたの名前を入力してね！", text: $inputName)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(15)
                    .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 40)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 18, design: .rounded))

                // 🩵 ログインボタン
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
                        .background(inputName.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(25)
                        .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .disabled(inputName.isEmpty)

                Spacer()
            }
            .padding(.top, 100)
        }
        .onAppear {
            playBGM()
            startTypewriter()
        }
    }

    // 🎬 一文字ずつ表示させるタイマー
    func startTypewriter() {
        displayedText = ""
        charIndex = 0

        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            if charIndex < fullText.count {
                let index = fullText.index(fullText.startIndex, offsetBy: charIndex)
                displayedText.append(fullText[index])
                charIndex += 1
            } else {
                timer.invalidate()
            }
        }
    }
}
