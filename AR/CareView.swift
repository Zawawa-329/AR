import SwiftUI

struct CareView: View {
    @EnvironmentObject var appState: AppState

    enum Mode {
        case walk, sleep, dressUp, content
    }

    @State private var isMenuOpen = false
    @State private var selectedMode: Mode? = nil

    @State private var hearts: [Heart] = []
    @State private var heartGenerationTimer: Timer? = nil

    @GestureState private var isDragging = false // ドラッグ中かどうかを検知

    @State private var petCount: Int = 0
    @State private var currentShimaenagaImage: String = "kubikashige-shimaenaga" // 初期画像名
    private let imageChangeThreshold: Int = 10 // 撫でる回数で画像が変わる閾値

    // きのみの状態とドラッグ
    @State private var kinomiPosition: CGPoint = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height * 0.9)
    @State private var isKinomiDragging: Bool = false
    @State private var feedSuccessCount: Int = 0
    // ★修正: メッセージ表示用の状態変数
    @State private var showActionMessage: Bool = true // 初期表示
    @State private var showTeaMessage: Bool = false // お茶シマエナガ時のメッセージ

    @State private var isTeaShimaenagaState: Bool = false


    struct Heart: Identifiable {
        let id = UUID()
        var position: CGPoint
        var offset: CGSize = .zero
        var opacity: Double = 1.0
        var scale: CGFloat = 0.5
    }

    private var careAction: String {
        let todayMoodIndex = appState.userResponses[0] ?? 2 // キーが0の回答
        let currentMoodIndex = appState.userResponses[1] ?? 2 // キーが1の回答
        let totalMoodScore = todayMoodIndex + currentMoodIndex

        if totalMoodScore <= 3 {
            return "鳥に餌をあげましょう！"
        } else if totalMoodScore >= 5 {
            return "鳥を撫でてあげましょう。"
        } else {
            return "鳥と遊びましょう！"
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // MARK: - Background
                Color(red: 1.0, green: 0.94, blue: 0.96)
                    .ignoresSafeArea()

                // MARK: - Bird and Actions
                VStack {
                    Spacer(minLength: 100)
                    
                    // ★修正: アクションメッセージの表示ロジック
                    if showActionMessage && !isTeaShimaenagaState {
                        Text(careAction)
                            .font(.title2)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                            .transition(.opacity) // フェードアウトアニメーション
                    }
                    
                    Image(currentShimaenagaImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150)
                        // ★修正: 鳥の画像をZStackの中心に配置
                        .position(x: geometry.size.width / 2, y: geometry.size.height * 0.5) // 画面中央に配置（Y座標は調整可能）
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .updating($isDragging) { _, state, _ in
                                    state = true
                                }
                                .onChanged { _ in
                                    if careAction == "鳥を撫でてあげましょう。" {
                                        if heartGenerationTimer == nil {
                                            startHeartGeneration()
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    stopHeartGeneration()
                                    if careAction == "鳥を撫でてあげましょう。" {
                                        petCount += 1
                                        if petCount >= imageChangeThreshold {
                                            currentShimaenagaImage = "shimaenaga-heart" // 撫でる回数で変わる画像
                                            petCount = 0 // 画像を変えたらカウントをリセット
                                        }
                                    }
                                }
                        )
                        .zIndex(1) // 鳥を前面に
                    // Spacer() // positionを使ったので不要
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity) // VStackのサイズを最大に
                
                // MARK: - Hearts
                ForEach(hearts) { heart in
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20 + heart.scale * 10))
                        .foregroundColor(.red)
                        .opacity(heart.opacity)
                        .scaleEffect(heart.scale)
                        .offset(heart.offset)
                        .position(heart.position)
                        .animation(.easeOut(duration: 1.5), value: heart.offset)
                        .animation(.easeOut(duration: 1.5), value: heart.opacity)
                        .animation(.easeOut(duration: 1.5), value: heart.scale)
                        .zIndex(2) // ハートをさらに前面に
                }

                // MARK: - Kinomi (Food)
                if careAction == "鳥に餌をあげましょう！" && !isTeaShimaenagaState {
                    Image("kinomi") // ★追加したきのみの画像名
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .position(kinomiPosition)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    kinomiPosition = value.location
                                    isKinomiDragging = true
                                }
                                .onEnded { _ in
                                    isKinomiDragging = false
                                    // 鳥の画像領域との重なりを判定
                                    // 鳥の中心位置とサイズからフレームを計算
                                    let birdRect = CGRect(
                                        x: geometry.size.width / 2 - 75,
                                        y: geometry.size.height * 0.5 - 75, // 鳥のY座標の中心 - 半分の高さ
                                        width: 150,
                                        height: 150
                                    )

                                    if birdRect.contains(kinomiPosition) {
                                        feedSuccessCount += 1
                                        // きのみを画面外に一時的に移動（消えたように見せる）
                                        kinomiPosition = CGPoint(x: -100, y: -100) // 画面外に移動
                                        
                                        // 5回成功したらきのみを再表示しない
                                        if feedSuccessCount < 5 {
                                            // 0.5秒後にきのみを初期位置に戻す
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                kinomiPosition = CGPoint(x: geometry.size.width / 2, y: geometry.size.height * 0.9)
                                            }
                                        }

                                        if feedSuccessCount >= 5 {
                                            currentShimaenagaImage = "shimaenaga-tea" // 5回成功で切り替わる画像
                                            showTeaMessage = true // お茶メッセージを表示
                                            isTeaShimaenagaState = true // 最終状態へ移行
                                            // 餌やり成功カウントはもう使わないのでリセットしても良い
                                            // feedSuccessCount = 0
                                        }
                                    } else {
                                        // 鳥にドロップされなかったら、きのみを初期位置に戻す
                                        kinomiPosition = CGPoint(x: geometry.size.width / 2, y: geometry.size.height * 0.9)
                                    }
                                }
                        )
                        .zIndex(3) // きのみを最前面に
                        .transition(.opacity) // フェードイン/アウト
                }

                // MARK: - Tea Message (永久表示)
                if isTeaShimaenagaState { // ★修正: isTeaShimaenagaState が true の場合に常に表示
                    Text("鳥とくつろぎましょう！") // メッセージ内容も変更
                        .font(.title2)
                        .foregroundColor(.brown)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                        .position(x: geometry.size.width / 2, y: geometry.size.height * 0.15) // ★修正: 画面上部寄りに
                        .zIndex(4)
                        .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                }

                // MARK: - Menu UI
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
                .zIndex(5)

                if isMenuOpen {
                    VStack(alignment: .leading, spacing: 20) {
                        Button("お散歩") { selectedMode = .walk; isMenuOpen = false }.foregroundColor(.primary)
                        Button("おやすみ") { selectedMode = .sleep; isMenuOpen = false }.foregroundColor(.primary)
                        Button("お着替え") { selectedMode = .dressUp; isMenuOpen = false }.foregroundColor(.primary)
                        Button("ホーム") { selectedMode = .content; isMenuOpen = false }.foregroundColor(.primary)
                    }
                    .padding(25)
                    .background(.regularMaterial)
                    .cornerRadius(20)
                    .shadow(radius: 5)
                    .padding(.top, 90)
                    .padding(.leading, 10)
                    .transition(.move(edge: .leading))
                    .zIndex(6)
                }

                if let mode = selectedMode {
                    switch mode {
                    case .walk: WalkView().environmentObject(appState)
                    case .sleep: SleepView().environmentObject(appState)
                    case .dressUp: DressUpView().environmentObject(appState)
                    case .content:
                        ContentView(userResponses: [:])
                            .environmentObject(appState)
                    }
                }
            }
            // ★追加: ページが表示されたときにアクションメッセージを非表示にするタイマー
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { // 2秒後に消える
                    withAnimation {
                        showActionMessage = false
                    }
                }
            }
        }
    }

    // ハート生成関数 (変更なし)
    func startHeartGeneration() {
        guard heartGenerationTimer == nil else { return }
        heartGenerationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if self.careAction == "鳥を撫でてあげましょう。" {
                addHeart()
            } else {
                stopHeartGeneration()
            }
        }
    }

    func stopHeartGeneration() {
        heartGenerationTimer?.invalidate()
        heartGenerationTimer = nil
    }

    func addHeart() {
        // ハートの出現位置を鳥の頭あたりに調整
        // 鳥のImageが.positionで設定されているため、その位置を基準に計算
        let birdVisualX = UIScreen.main.bounds.width / 2
        let birdVisualY = UIScreen.main.bounds.height * 0.5 // 鳥の表示中心Y
        let birdHeight = 150.0 // 鳥のフレーム高さ

        let heartSpawnY = birdVisualY - (birdHeight / 2) + 20 // 鳥の上部から少し下

        let randomX = CGFloat.random(in: (birdVisualX - 30)...(birdVisualX + 30))
        let randomY = CGFloat.random(in: (heartSpawnY - 10)...(heartSpawnY + 10))

        var newHeart = Heart(position: CGPoint(x: randomX, y: randomY))
        hearts.append(newHeart)

        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 1.5)) {
                if let index = hearts.firstIndex(where: { $0.id == newHeart.id }) {
                    hearts[index].offset.height = -150 // 上にふわふわ移動
                    hearts[index].opacity = 0.0 // フェードアウト
                    hearts[index].scale = 2.0 // 拡大
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                hearts.removeAll { $0.id == newHeart.id }
            }
        }
    }
}
