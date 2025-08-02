//
//  ContentView.swift
//  AR
//
//  Created by owner on 2025/07/29.
//
import SwiftUI
import RealityKit

struct ContentView: View {
    
    // StartViewから正しく渡される userResponses: [Int: Int] に型を合わせる
    var userResponses: [Int: Int] = [:]
    
    @State private var isMenuOpen = false
    @State private var selectedMode: Mode? = nil
    @State private var isLoading: Bool = false
    @State private var aiComment: String = ""
    
    enum Mode {
        case care, walk, sleep, dressUp
    }
    
    let questions: [Int: String] = [
        0: "今日の気分は⁇",
        1: "今の気分は⁇",
        2: "お話は⁇"
    ]
    
    let answersOptions: [Int:[String]] = [
        0:["元気☺️","ちょっと元気🙂","普通😶","ちょっとお疲れ😕","お疲れ🥲"],
        1:["楽しい☺️","悲しい😭","何ともない😶","怒る😕","眠い🥱"],
        2:["たくさんしたい☺️","多めにしたい🙂","普通😶","あまりしたくない😕","したくない🥲"]
    ]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RealityView { content in
                let model = Entity()
                let mesh = MeshResource.generateBox(size: 0.1, cornerRadius: 0.005)
                let material = SimpleMaterial(color: .gray, roughness: 0.15, isMetallic: true)
                model.components.set(ModelComponent(mesh: mesh, materials: [material]))
                model.position = [0, 0.05, 0]
                
                let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
                anchor.addChild(model)
                content.add(anchor)
                
                content.camera = .spatialTracking
            }
            .edgesIgnoringSafeArea(.all)
            
            Button(action: {
                withAnimation {
                    isMenuOpen.toggle()
                }
            }) {
                Image(systemName: "line.3.horizontal")
                    .resizable()
                    .frame(width: 30, height: 20)
                    .foregroundColor(Color.green)
                    .padding()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding()
            
            if isMenuOpen {
                VStack(alignment: .leading, spacing: 20) {
                    Button("お世話") { selectedMode = .care; isMenuOpen = false} .foregroundColor(Color.green)
                    Button("お散歩") { selectedMode = .walk; isMenuOpen = false} .foregroundColor(Color.green)
                    Button("おやすみ") { selectedMode = .sleep; isMenuOpen = false} .foregroundColor(Color.green)
                    Button("お着替え") { selectedMode = .dressUp; isMenuOpen = false} .foregroundColor(Color.green)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 5)
                .padding(.top, 70)
                .padding(.leading, 10)
                .transition(.move(edge: .leading))
            }
            
            if let mode = selectedMode {
                switch mode {
                case .care: CareView()
                case .walk: WalkView()
                case .sleep: SleepView()
                case .dressUp: DressUpView()
                }
            }
            VStack {
                Spacer()
                if isLoading {
                    ProgressView("コメントを生成中...")
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding()
                } else if !aiComment.isEmpty {
                    Text(aiComment)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding()
                }
            }
        }
        .onAppear {
            Task {
                await generateAIComment()
            }
        }
    }
    
    func buildPrompt() -> String {
        var prompt = "以下はユーザーのアンケート回答です。それに合った一言コメントを優しく伝えてください。\n\n"
        for (qIndex, answerIndex) in userResponses.sorted(by: { $0.key < $1.key }) {
            if let question = questions[qIndex],
               let options = answersOptions[qIndex],
               answerIndex < options.count {
                let answerText = options[answerIndex]
                prompt += "Q: \(question)\nA: \(answerText)\n\n"
            }
        }
        prompt += "→ 一言メッセージ:"
        return prompt
    }
    
    // OpenAI APIを呼ぶ
    func generateAIComment() async {
        isLoading = true
        defer { isLoading = false }
        
        let prompt = buildPrompt()
        aiComment = await callOpenAI(prompt: prompt)
    }
    
    // 実際のAPI呼び出し部分（APIキーは自分のものに変えてください）
    func callOpenAI(prompt: String) async -> String {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            return "URLエラー"
        }
        
        // ★★★注意：ここに新しいAPIキーを貼り付けてください★★★
        let apiKey = "sk-proj-YOUR_NEW_API_KEY_HERE"
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
        
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [["role": "user", "content": prompt]],
            "max_tokens": 100
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: body)
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = headers
            request.httpBody = data
            
            let (responseData, _) = try await URLSession.shared.data(for: request)
            if let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                return content.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                return "ちょっと待ってね。"
            }
        } catch {
            return "ちょっと待ってね。: \(error.localizedDescription)"
        }
    }
}

// ContentViewのプレビュー用コード
#Preview {
    ContentView(userResponses: [
        0: 0, // サンプル回答
        1: 0,
        2: 0
    ])
}
