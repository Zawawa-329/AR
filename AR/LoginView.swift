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
    
    
    
    var body: some View {
        VStack(spacing: 30) {
            Text("ようこそ")
                .font(.largeTitle)
                .padding()
            
            TextField("名前を入力してください", text: $inputName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button(action: {
                if !inputName.isEmpty {
                    appState.userNameStore = inputName
                    appState.isLoggedIn = true
                }
            }) {
                Text("ログイン")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(inputName.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            .disabled(inputName.isEmpty)
            
            Spacer()
        }
        
        .onAppear {
            playBGM() // ログイン画面が表示されたら BGM 再生
            
        }
    }
}
