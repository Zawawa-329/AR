import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var sparkles: [UUID: CGPoint] = [:]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    Image("logo2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .opacity(isActive ? 1 : 0)
                        .scaleEffect(isActive ? 1 : 0.8)
                        .animation(.easeIn(duration: 1.2), value: isActive)
                    
                    Spacer()
                }
                
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
                            DispatchQueue.main.async {
                                sparkles[id] = sparklePosition
                            }
                        }
                    }
        )
            .onAppear {
                isActive = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        AppState.shared.showSplash = false
                    }
                }
            }
        }
    }
}

