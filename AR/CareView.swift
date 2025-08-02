import SwiftUI

struct CareView: View {
    // StartViewから受け取るuserResponsesを追加 -> 削除します
    // var userResponses: [Int: Int] // ★この行を削除

    // AppStateを環境オブジェクトとして追加
    @EnvironmentObject var appState: AppState // ★追加

    @State private var isMenuOpen = false
    @State private var selectedMode: Mode? = nil

    enum Mode {
        case walk, sleep, dressUp, content
    }

    // userResponsesに基づいて表示するテキストやアクションを決定するプロパティ
    private var careAction: String {
        // userResponsesではなく、appState.userResponsesを参照するように変更
        // 「今日の気分」と「今の気分」の質問の回答を取得します。
        // 質問のインデックスはStartViewのquestions配列に基づいて0と1です。
        // 回答がない場合はデフォルト値（普通）としてインデックス2を使用します。
        let todayMoodIndex = appState.userResponses[0] ?? 2 // ★appState.userResponsesに変更
        let currentMoodIndex = appState.userResponses[1] ?? 2 // ★appState.userResponsesに変更

        // 気分のスコアを計算します。インデックスが小さいほど「プラス」、大きいほど「マイナス」とします。
        // 例えば、元気(0) + 楽しい(0) = 0 (最もプラス)
        // お疲れ(4) + 眠い(4) = 8 (最もマイナス)
        let totalMoodScore = todayMoodIndex + currentMoodIndex

        // スコアに基づいてアクションを決定します。
        // 例: スコアが低い（プラスな気分）なら餌やり、高い（マイナスな気分）なら撫でる
        if totalMoodScore <= 3 { // 例: 元気+楽しい (0), 元気+何ともない (2), ちょっと元気+楽しい (1) など
            return "鳥に餌をあげましょう！"
        } else if totalMoodScore >= 5 { // 例: ちょっとお疲れ+何ともない (5), お疲れ+悲しい (5), お疲れ+眠い (8) など
            return "鳥を撫でてあげましょう。"
        } else { // その他の場合（普通など）
            return "鳥と遊びましょう！"
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // MARK: - Image View and Background
            ZStack {
                // 背景色
                Color(red: 1.0, green: 0.94, blue: 0.96)
                    .ignoresSafeArea()

                // アップロードされた画像を表示
                Image("kubikashige-shimaenaga") // Assets.xcassetsに追加した画像名を指定
                    .resizable()
                    .scaledToFit()
                    .frame(width:100 ) // 表示サイズを調整

                // CareViewでuserResponsesを利用して表示する内容
                VStack {
                    Spacer()
                    Text(careAction) // ここで計算されたアクションを表示
                        .font(.title2)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                    Spacer()
                }
            }

            // MARK: - Menu UI (変更なし)
            Button(action: {
                withAnimation {
                    isMenuOpen.toggle()
                }
            }) {
                Image(systemName: "line.3.horizontal")
                    .resizable()
                    .frame(width: 30, height: 20)
                    .foregroundColor(.gray)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15))
            }
            .padding()

            if isMenuOpen {
                VStack(alignment: .leading, spacing: 20) {
                    Button("お散歩") { selectedMode = .walk; isMenuOpen = false }.foregroundColor(.primary)
                    Button("おやすみ") { selectedMode = .sleep; isMenuOpen = false }.foregroundColor(.primary)
                    Button("お着替え") { selectedMode = .dressUp; isMenuOpen = false }.foregroundColor(.primary)
                    // ホームボタン
                    Button("ホーム") { selectedMode = .content; isMenuOpen = false }.foregroundColor(.primary)
                }
                .padding(25)
                .background(.regularMaterial)
                .cornerRadius(20)
                .shadow(radius: 5)
                .padding(.top, 90)
                .padding(.leading, 10)
                .transition(.move(edge: .leading))
            }

            if let mode = selectedMode {
                switch mode {
                case .walk: WalkView()
                    .environmentObject(appState) // ★追加: appStateにアクセスできるように注入
                case .sleep: SleepView()
                    .environmentObject(appState) // ★追加: appStateにアクセスできるように注入
                case .dressUp: DressUpView()
                    .environmentObject(appState) // ★追加: appStateにアクセスできるように注入
                case .content:
                    // ContentViewに戻る場合、userResponses引数なしで呼び出し、appStateを注入
                    ContentView(userResponses: [:]) // ★引数は仮の空の辞書を渡す
                        .environmentObject(appState) // ★追加: appStateにアクセスできるように注入
                }
            }
        }
    }
}
