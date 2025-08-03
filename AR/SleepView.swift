import SwiftUI
import AVFoundation

struct SleepView: View {
    @State private var isMenuOpen = false
    @State private var selectedMode: Mode? = nil
    @State private var isLightOff = false
    @State private var showZzzBubble = false
    @State private var sleepStartTime: Date? = nil
    @State private var sleepDuration: TimeInterval? = nil
    @State private var showSleepSummary: Bool = false
    @State private var isFeeding = false
    @State private var wiggle = false
    @State private var speechBubbleText: String? = nil
    @State private var sleepLog: [String] = []
    
    
    let sleepTalks = [
        "むにゃむにゃ…",
        "すやすや…💤",
        "おやつ…🐛",
        "うとうと…☁️",
        "zzz…🌙",
        
        "ラーメン食べたいなぁ",
        "明日も話したいなぁ"
        
    ]


    enum Mode {
        case care, walk, dressUp, content
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(isLightOff ? .black :Color(red: 0.6, green: 0.8, blue: 1.0))
                .ignoresSafeArea()

            if selectedMode == nil {
                ZStack {
                    if showZzzBubble {
                        Text("💤")
                            .font(.title)
                            .padding(8)
                            .background(Color.white.opacity(0))
                            .cornerRadius(10)
                            .shadow(radius: 4)
                            .transition(.opacity)
                            .offset(y: -10)
                            .offset(x: 250)
                    }
                }

                ShimaFaceView(isLightOn: !isLightOff)
                    .frame(width: 400, height: 400)
                    .rotationEffect(.degrees(wiggle ? 3 : -3))
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: wiggle)
                    .onAppear {
                        wiggle = true
                    }

                if let text = speechBubbleText {
                    VStack {
                        Spacer()
                        SpeechBubble(text: text)
                        Spacer()
                    }
                    .frame(height: 400)
                    .offset(y: 300)
                    .offset(x: 150)
                    .transition(.opacity)
                }

                // ライトボタン
                VStack {
                    Spacer().frame(height: 40)
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation {
                                isLightOff.toggle()
                                let now = Date()
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
                                if isLightOff {
                                    sleepStartTime = Date()
                                    sleepDuration = nil
                                    speechBubbleText = "おやすみ😚"
                                    showZzzAnimation()
                                    sleepLog.append("🛌 寝た時刻: \(formatter.string(from: now))")
                                } else if let start = sleepStartTime {
                                    sleepDuration = Date().timeIntervalSince(start)
                                    showSleepSummary = true
                                    speechBubbleText = "おはよう☺️"
                                    sleepLog.append("🌞 起きた時刻: \(formatter.string(from: now))")
                                }
                               

                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    withAnimation {
                                        speechBubbleText = nil
                                    }
                                }
                            }
                        }) {
                            Image(systemName: isLightOff ? "lightbulb.slash.fill" : "lightbulb.fill")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .foregroundColor(isLightOff ? .gray : .yellow)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 20)
                    }
                }

                // 夜食ボタン
                VStack {
                    Spacer()
                    HStack {
                        Button(action: {
                            feedShima()
                        }) {
                            Text("夜食を与える")
                                .font(.headline)
                                .padding()
                                .background(
                                    Image("ramen")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(radius: 3)
                        }
                        .disabled(isFeeding)
                        Spacer()
                    }
                    .padding()
                }

                // 睡眠サマリー
                if showSleepSummary, let duration = sleepDuration {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("睡眠時間: \(formattedDuration(duration))")
                                .font(.title3)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(12)
                                .shadow(radius: 4)
                                .transition(.opacity)
                        }
                        .padding(.trailing, 20)
                    }
                    .zIndex(100)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            withAnimation { showSleepSummary = false }
                        }
                    }
                }

                // ▼▼▼ sleepLog表示 ▼▼▼
                VStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(sleepLog.suffix(5), id: \.self) { entry in
                            Text(entry)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 100)
                }
                // ▲▲▲ sleepLog表示ここまで ▲▲▲
            }

            // メニューボタン
            Button(action: {
                withAnimation { isMenuOpen.toggle() }
            }) {
                Image(systemName: "line.3.horizontal")
                    .resizable()
                    .frame(width: 30, height: 20)
                    .foregroundColor(.green)
                    .padding()
            }
            .padding()

            // メニュー表示
            if isMenuOpen {
                VStack(alignment: .leading, spacing: 20) {
                    Button("お世話") { attemptNavigation(to: .care)  }
                    Button("お散歩") { attemptNavigation(to: .walk)}
                    Button("お着替え") {  attemptNavigation(to: .dressUp)}
                    Button("ホーム") {  attemptNavigation(to: .content)  }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 5)
                .padding(.top, 70)
                .padding(.leading, 10)
            }

            // モード表示（他ページ）
            if let mode = selectedMode {
                switch mode {
                    case .care: CareView()
                    case .walk: WalkView()
                    case .dressUp: DressUpView()
                    case .content: ContentView()
                }
            }
        }
        .onAppear {
            startSleepTalkTimer()
        }
        .onDisappear {
            AudioManager.shared.stopBGM()
        }
    }

    func showZzzAnimation() {
        showZzzBubble = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showZzzBubble = false
            }
        }
    }

    func feedShima() {
        guard !isFeeding else { return }
        isFeeding = true
        isLightOff = false
        showZzzBubble = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            isLightOff = true
            isFeeding = false
            showZzzAnimation()
        }
    }
    
    
    // SleepView の中の適切な位置に追加（例えば feedShima() の下とかでOK）
    func attemptNavigation(to mode: Mode) {
        if isLightOff {
            speechBubbleText = "おいていかないで…😭"
            isMenuOpen = false  // メニューだけ閉じる

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    speechBubbleText = nil
                }
            }
        } else {
            selectedMode = mode
            isMenuOpen = false
        }
    }
    
    
    func startSleepTalkTimer() {
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            guard isLightOff, speechBubbleText == nil else { return }
            
            if Bool.random() {  // ランダムに寝言を出す
                withAnimation {
                    speechBubbleText = sleepTalks.randomElement()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        speechBubbleText = nil
                    }
                }
            }
        }
    }


}

func formattedDuration(_ interval: TimeInterval) -> String {
    let hours = Int(interval) / 3600
    let minutes = (Int(interval) % 3600) / 60
    let seconds = Int(interval) % 60
    return String(format: "%02d時間 %02d分 %02d秒", hours, minutes, seconds)
}



struct ShimaFaceView: View {
    let isLightOn: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 300, height: 300)
                .shadow(radius: 4)

            HStack(spacing: 45) {
                if isLightOn {
                    Circle().fill(Color.black).frame(width: 30, height: 30)
                    Circle().fill(Color.black).frame(width: 30, height: 30)
                } else {
                    Capsule().fill(Color.black).frame(width: 30, height: 5)
                    Capsule().fill(Color.black).frame(width: 30, height: 5)
                }
            }
            .offset(y: -45)

            Triangle()
                .fill(Color.black)
                .frame(width: 20, height: 15)
                .offset(y: 0)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct SpeechBubble: View {
    let text: String

    var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .font(.title2)
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
                .shadow(radius: 4)
            Triangle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 30, height: 10)
                .offset(y: -75)
        }
    }
}


