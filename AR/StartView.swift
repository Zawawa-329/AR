//
//  StareView.swift
//  AR
//
//  Created by owner on 2025/07/31.
//

import SwiftUI


struct StartView: View {
    var userName: String
    @State private var showAR = false
    
    struct Question {
        let id = UUID()
        let text: String
        let options: [String]
    }
    
    let questions: [Question] = [
        Question(text: "今日の気分は⁇", options: ["元気☺️", "ちょっと元気🙂", "普通😶", "ちょっとお疲れ😕", "お疲れ🥲"]),
        Question(text: "今の気分は⁇", options: ["楽しい☺️", "悲しい😭", "何ともない😶", "怒る😕", "眠い🥱"]),
        Question(text: "お話は⁇", options: ["たくさんしたい☺️", "多めにしたい🙂", "普通😶", "あまりしたくない😕", "したくない🥲"])
    ]
    
    // ContentViewが期待する [Int: Int] 型に修正
    @State private var userResponses: [Int: Int] = [:]

    var body: some View {
        VStack(spacing: 40) {
            Text("こんにちは、\(userName) さん")
                .font(.title)
                .padding()
            
            ScrollView {
                VStack(spacing: 30) {
                    // ForEachの記述をシンプルに修正
                    ForEach(0..<questions.count, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(questions[index].text)
                                .font(.headline)
                            
                            ForEach(0..<questions[index].options.count, id: \.self) { optionIndex in
                                let option = questions[index].options[optionIndex]
                                Button(action: {
                                    // 選択されたオプションのインデックスを保存
                                    userResponses[index] = optionIndex
                                }) {
                                    HStack {
                                        Text(option)
                                            .foregroundColor(.black)
                                        Spacer()
                                        // userResponsesのキーと値を使って選択状態を判定
                                        if userResponses[index] == optionIndex {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    if userResponses.count == questions.count {
                        Button(action: {
                            showAR = true
                        }) {
                            Text("カメラを起動する")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            Spacer()
        }
        .fullScreenCover(isPresented: $showAR) {
            // ContentViewにuserResponsesを正しく渡す
            ContentView(userResponses: userResponses)
        }
    }
}
