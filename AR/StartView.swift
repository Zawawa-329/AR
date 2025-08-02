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
    
    @State private var userResponses: [Int: Int] = [:]

    var body: some View {
        ZStack { // ★ ここにZStackを追加
            // ★ 背景色を薄い茶色に設定
            Color(red: 0.95, green: 0.9, blue: 0.8)
                .edgesIgnoringSafeArea(.all)
            
            // 既存のVStackはZStackの中に移動
            VStack(spacing: 40) {
                Text("こんにちは、\(userName) さん")
                    .font(.title)
                    .padding()
            
                ScrollView {
                    VStack(spacing: 30) {
                        ForEach(0..<questions.count, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(questions[index].text)
                                    .font(.headline)
                                
                                ForEach(0..<questions[index].options.count, id: \.self) { optionIndex in
                                    let option = questions[index].options[optionIndex]
                                    Button(action: {
                                        userResponses[index] = optionIndex
                                    }) {
                                        HStack {
                                            Text(option)
                                                .foregroundColor(.black)
                                            Spacer()
                                            if userResponses[index] == optionIndex {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.black)
                                            }
                                        }
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(10)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                
                if userResponses.count == questions.count {
                    Button(action: {
                        showAR = true
                    }) {
                        Text("カメラを起動する📸")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.horizontal) // VStackに水平方向のpaddingを追加
        } // ★ ここでZStackを閉じる
        .fullScreenCover(isPresented: $showAR) {
            ContentView(userResponses: userResponses)
        }
    }
}
