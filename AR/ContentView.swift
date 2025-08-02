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
            // ▼▼▼ このRealityViewの中身を変更 ▼▼▼
            RealityView { content in
                // 1. アンカーを作成
                let anchor = AnchorEntity(plane: .horizontal)
                content.add(anchor)
                
                // 2. ライトを作成してアンカーに追加
                let lightEntity = Entity()
                lightEntity.components.set(PointLightComponent(color: .white, intensity: 5000))
                lightEntity.position = [0, 0.5, 0] // モデルの少し上、手前に配置
                anchor.addChild(lightEntity)
                
                // 3. シマエナガのモデルを生成してアンカーに追加
                if let shimaenaga = createShimaenaga() {
                    anchor.addChild(shimaenaga)
                }
                
                content.camera = .spatialTracking
            }
            .edgesIgnoringSafeArea(.all)
            // ▲▲▲ ここまで ▲▲▲
            
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
                    Button("お世話") { selectedMode = .care; isMenuOpen = false; aiComment = ""} .foregroundColor(Color.green)
                    Button("お散歩") { selectedMode = .walk; isMenuOpen = false; aiComment = ""} .foregroundColor(Color.green)
                    Button("おやすみ") { selectedMode = .sleep; isMenuOpen = false; aiComment = ""} .foregroundColor(Color.green)
                    Button("お着替え") { selectedMode = .dressUp; isMenuOpen = false; aiComment = ""} .foregroundColor(Color.green)
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
                        .cornerRadius(20)
                        .padding(24)
                } else if !aiComment.isEmpty {
                    VStack(alignment: .leading, spacing: 8){
                        Text("シマちゃん")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.6))
                            .padding(.top, 16)
                            .padding(.horizontal, 24)
                        
                        Text(aiComment)
                            .font(.system(size: 16))
                            .foregroundColor(Color.black)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 24)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.white.opacity(0.95))
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color(red: 0.95, green: 0.9, blue: 0.8).opacity(0.6), lineWidth: 4) // ピンクの枠線
                            )
                            .shadow(color: Color.pink.opacity(0.3), radius: 10, x: 0, y: 5))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            Task {
                await generateAIComment()
            }
        }
    }
    
    // ▼▼▼ この関数を追加 ▼▼▼
    /// シマエナガの各パーツを組み合わせて一体のモデルとして返す関数
    func createShimaenaga() -> ModelEntity? {
        // --- マテリアルの準備 ---
        let bodyMaterial = SimpleMaterial(color: .white, roughness: 1.0, isMetallic: false)
        let wingMaterial = SimpleMaterial(color: .brown, roughness: 1.0, isMetallic: false)
        let eyeMaterial = SimpleMaterial(color: .black, isMetallic: false)

        // --- 各パーツの作成 ---
        let body = ModelEntity(mesh: .generateSphere(radius: 0.05), materials: [bodyMaterial])

        let head = ModelEntity(mesh: .generateSphere(radius: 0.035), materials: [bodyMaterial])
        head.position = [0, 0.045, 0]

        let leftEye = ModelEntity(mesh: .generateSphere(radius: 0.003), materials: [eyeMaterial])
        leftEye.position = [-0.01, 0.015, 0.032]
        let rightEye = ModelEntity(mesh: .generateSphere(radius: 0.003), materials: [eyeMaterial])
        rightEye.position = [0.01, 0.015, 0.032]

        let beak = ModelEntity(mesh: .generateCone(height: 0.004, radius: 0.005), materials: [eyeMaterial])
        beak.position = [0, 0.01, 0.033]

        let wingMesh = MeshResource.generateSphere(radius: 0.03)
        let leftWing = ModelEntity(mesh: wingMesh, materials: [wingMaterial])
        leftWing.position = [-0.025, 0.0, -0.01]
        let rightWing = ModelEntity(mesh: wingMesh, materials: [wingMaterial])
        rightWing.position = [0.025, 0.0, -0.01]

        // --- 全パーツを合体 ---
        let shimaenagaModel = ModelEntity()
        shimaenagaModel.addChild(body)
        shimaenagaModel.addChild(head)
        head.addChild(leftEye)
        head.addChild(rightEye)
        head.addChild(beak)
        body.addChild(leftWing)
        body.addChild(rightWing)

        return shimaenagaModel
    }
    // ▲▲▲ ここまで ▲▲▲
    
    func buildPrompt() -> String {
        var prompt = "以下はユーザーのアンケート回答です。それに合った一言コメントを優しく伝えてください。友達に話すみたいに。\n\n"
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
        
        guard let apiKey = loadAPIKeyFromCSV() else {
                print("APIキーをCSVから読み込めませんでした。")
                return "APIキー設定エラー"
            }
        
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
    // CSVファイルからAPIキーを読み込むヘルパー関数
        func loadAPIKeyFromCSV() -> String? {
            // プロジェクト内の keys.csv ファイルを探す
            guard let filepath = Bundle.main.path(forResource: "keys", ofType: "csv") else {
                return nil
            }
            
            do {
                let data = try String(contentsOfFile: filepath, encoding: .utf8)
                // 行ごとに分割
                let rows = data.components(separatedBy: "\n")
                
                for row in rows {
                    // カンマで列を分割
                    let columns = row.components(separatedBy: ",")
                    // 最初の列が "apiKey" であれば、2番目の列を返す
                    if columns.count > 1 && columns[0].trimmingCharacters(in: .whitespaces) == "apiKey" {
                        return columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            } catch {
                print("CSVファイルの読み込みエラー: \(error)")
            }
            
            return nil
        }
}
