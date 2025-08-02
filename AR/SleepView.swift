import SwiftUI
import RealityKit
import ARKit
import Combine
import AVFoundation

// MARK: - SleepView

struct SleepView: View {
    @State private var isMenuOpen = false
    @State private var selectedMode: Mode? = nil
    @State private var isLightOff = false
    @State private var showZzzBubble = false
    @State private var shimaScreenPosition: CGPoint? = nil
    
    // State to hold the star model entities
    @State private var starEntities: [ModelEntity] = []
    @State private var animationTimer: Timer?

    enum Mode {
        case care, walk, dressUp, content
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Pass the binding for stars to the ARViewContainer
            ARViewContainer(shimaScreenPosition: $shimaScreenPosition, starEntities: $starEntities)

            // zzz 吹き出し（キャラクター上に追従）
            if let position = shimaScreenPosition, showZzzBubble {
                Text("💤 zzz")
                    .font(.largeTitle)
                    .padding(12)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(15)
                    .shadow(radius: 4)
                    .position(position)
                    .transition(.opacity)
                    .zIndex(10)
            }

            // ライトオフのオーバーレイ
            if isLightOff {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(.easeInOut, value: isLightOff)
            }

            // ハンバーガーメニュー
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

            // ライトボタン（右上）
            VStack {
                Spacer().frame(height: 40)
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            isLightOff.toggle()
                        }
                    }) {
                        Image(systemName: isLightOff ? "lightbulb.slash.fill" : "lightbulb.fill")
                            .resizable()
                            .frame(width: 25, height: 25)
                            .foregroundColor(isLightOff ? .gray : .yellow)
                            .padding(10)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.trailing, 20)
                }
            }

            // メニュー内容
            if isMenuOpen {
                VStack(alignment: .leading, spacing: 20) {
                    Button("お世話") { selectedMode = .care; isMenuOpen = false }
                        .foregroundColor(Color.green)
                    Button("お散歩") { selectedMode = .walk; isMenuOpen = false }
                        .foregroundColor(Color.green)
                    Button("お着替え") { selectedMode = .dressUp; isMenuOpen = false }
                        .foregroundColor(Color.green)
                    Button("ホーム") { selectedMode = .content; isMenuOpen = false }
                        .foregroundColor(Color.green)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 5)
                .padding(.top, 70)
                .padding(.leading, 10)
                .transition(.move(edge: .leading))
            }

            // モードビュー表示
            if let mode = selectedMode {
                switch mode {
                case .care: CareView() // Assuming these views exist
                case .walk: WalkView()
                case .dressUp: DressUpView()
                case .content: ContentView()
                }
            }
        }
        .onAppear {
            AudioManager.shared.playBGM(named: "bgm-sleep")
            generateStars()
            startStarAnimation()
        }
        .onDisappear {
            AudioManager.shared.stopBGM()
            stopStarAnimation()
        }
        .onReceive(NotificationCenter.default.publisher(for: .zzzHitNotification)) { _ in
            withAnimation {
                showZzzBubble = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation {
                    showZzzBubble = false
                }
            }
        }
    }

    /// Creates star entities at random positions and stores them in state.
    func generateStars(count: Int = 80) {
        var newStars: [ModelEntity] = []
        for _ in 0..<count {
            // Create a shiny, unlit material
            let material = SimpleMaterial(color: .white, roughness: 0.2, isMetallic: true)
            let star = ModelEntity(mesh: .generateSphere(radius: Float.random(in: 0.005...0.01)), materials: [material])
            
            // Unlit material makes it glow
            if var unlitMaterial = try? UnlitMaterial(color: .yellow) {
                unlitMaterial.color = .init(tint: .yellow.withAlphaComponent(0.99), texture: nil)
                star.model?.materials = [unlitMaterial]
            }

            // ★ここでライト追加
            let light = PointLightComponent(color: .yellow, intensity: 200000)
            
            star.components.set(light)

            // Position stars in a sphere around the user
            let theta = Float.random(in: 0..<(2 * .pi)) // Horizontal angle
            let phi = acos(2 * Float.random(in: 0...1) - 1) // Vertical angle
            let radius = Float.random(in: 1.5...3.0) // Distance from center
            
            let x = radius * sin(phi) * cos(theta)
            let y = radius * sin(phi) * sin(theta) + 0.5 // Centered a bit higher
            let z = radius * cos(phi)

            star.position = SIMD3<Float>(x, y, z)
            newStars.append(star)
        }

        self.starEntities = newStars
    }

    /// Starts a timer to animate the stars.
    func startStarAnimation() {
        animationTimer?.invalidate() // Invalidate old timer
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            for star in self.starEntities {
                // Gently move the star up and down relative to its anchor
                 star.position.y += Float.random(in: -0.002...0.002)
            }
        }
    }

    /// Stops the animation timer.
    func stopStarAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

// MARK: - ARViewContainer

struct ARViewContainer: UIViewRepresentable {
    @Binding var shimaScreenPosition: CGPoint?
    @Binding var starEntities: [ModelEntity] // Receive the star entities

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        context.coordinator.arView = arView

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)

        // Anchor for the character, placed on a horizontal surface
        let characterAnchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.2, 0.2])
        arView.scene.anchors.append(characterAnchor)

        // Load shima entity and add to its anchor
        Task {
            do {
                let shimaEntity = try await Entity(named: "shima")
                characterAnchor.addChild(shimaEntity)
                context.coordinator.shimaEntity = shimaEntity
            } catch {
                print("Failed to load shima entity: \(error)")
            }
        }

        // Subscribe to scene updates to track the character's screen position
        arView.scene.subscribe(to: SceneEvents.Update.self) { _ in
            if let position = context.coordinator.screenPosition(for: context.coordinator.shimaEntity) {
                DispatchQueue.main.async {
                    self.shimaScreenPosition = position
                }
            }
        }.store(in: &context.coordinator.cancellables)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // This function is called when @Binding properties change.
        // We add the stars here, but only once.
        if !starEntities.isEmpty && !context.coordinator.starsAdded {
            for starModel in starEntities {
                // 1. Create an AnchorEntity at the star's desired world position.
                let starAnchor = AnchorEntity(world: starModel.position)
                
                // 2. The model's position is now relative to its anchor, so reset it.
                starModel.position = .zero
                
                // 3. Add the star model as a child of the anchor.
                starAnchor.addChild(starModel)
                
                // 4. Add the anchor (with the star) to the scene.
                uiView.scene.addAnchor(starAnchor)
            }
            // 5. Set the flag so we don't add the stars again on the next update.
            context.coordinator.starsAdded = true
        }
    }

    class Coordinator: ARViewCoordinator {
        var cancellables = Set<AnyCancellable>()
        var starsAdded = false // Flag to track if stars have been added
    }
}

// MARK: - ARViewCoordinator

class ARViewCoordinator {
    weak var arView: ARView?
    var shimaEntity: Entity?

    func screenPosition(for entity: Entity?) -> CGPoint? {
        guard let entity = entity, let arView = arView else { return nil }
        let worldPosition = entity.position(relativeTo: nil)
        // Project the position slightly above the entity's origin
        let projected = arView.project(worldPosition + SIMD3<Float>(0, 0.15, 0))
        return projected.map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) }
    }
}

// MARK: - 通知定義

extension Notification.Name {
    static let zzzHitNotification = Notification.Name("zzzHitNotification")
}

// MARK: - AudioManager

class AudioManager {
    static let shared = AudioManager()
    private var player: AVAudioPlayer?

    func playBGM(named fileName: String, withExtension ext: String = "mp3") {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: ext) else {
            print("❌ BGM file not found: \(fileName).\(ext)")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1 // Infinite loop
            player?.volume = 0.5
            player?.play()
            print("🎵 BGM started")
        } catch {
            print("❌ Failed to play BGM: \(error)")
        }
    }

    func stopBGM() {
        player?.stop()
        print("🛑 BGM stopped")
    }
}

// MARK: - Dummy Views for Compilation
// These are placeholders so the code can compile without errors.
// You should have your own implementations for these.


