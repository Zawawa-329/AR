import SwiftUI
import AVFoundation

var bgmPlayer: AVAudioPlayer?

func playBGM() {
    guard let url = Bundle.main.url(forResource: "sample1", withExtension: "mp3") else {
        print("BGM ファイルが見つかりません")
        return
    }

    do {
        bgmPlayer = try AVAudioPlayer(contentsOf: url)
        bgmPlayer?.numberOfLoops = -1
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

    @State private var sparkles: [UUID: CGPoint] = [:]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                LinearGradient(gradient: Gradient(colors: [Color.pink.opacity(0.3), Color.white]),
                               startPoint: .top,
                               endPoint: .bottom)
                    .ignoresSafeArea()

                // メインUI
                VStack(spacing: 30) {
                    Text(displayedText)
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .foregroundColor(.purple)
                        .animation(.easeIn(duration: 0.2), value: displayedText)

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
                            .background(inputName.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(25)
                            .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .disabled(inputName.isEmpty)

                    Spacer()
                }
                .padding(.top, 100)

                // キラキラ表示
                ForEach(Array(sparkles.keys), id: \.self) { id in
                    if let position = sparkles[id] {
                        Sparkle(position: position)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    sparkles.removeValue(forKey: id)
                                }
                            }
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        // ジオメトリ座標系での位置取得が重要
                        let center = value.location

                        let count = 12
                        let radius: CGFloat = 40

                        for i in 0..<count {
                            let angle = 2 * .pi / CGFloat(count)
                            let theta = angle * CGFloat(i)

                            let x = center.x + cos(theta) * radius
                            let y = center.y + sin(theta) * radius
                            let sparklePosition = CGPoint(x: x, y: y)

                            let id = UUID()
                            sparkles[id] = sparklePosition
                        }
                    }
            )
            .onAppear {
                playBGM()
                startTypewriter()
            }
        }
    }

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
