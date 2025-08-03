import SwiftUI
import RealityKit
import ARKit

struct CareView: View {
    @State private var dragCount = 0
    @State private var hearts: [Heart] = []
    @State private var heartGenerationTimer: Timer? = nil

    
    struct Heart: Identifiable {
        let id = UUID()
        var position: CGPoint
        var offset: CGSize = .zero
        var opacity: Double = 1.0
        var scale: CGFloat = 0.5
    }

    var body: some View {
        ZStack {
            RealityKitViewContainer(dragCount: $dragCount)
                .edgesIgnoringSafeArea(.all)

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
                    .zIndex(100)
            }

            VStack {
                Spacer()
                Text("ボクをなでてほしいな")
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.bottom, 10)
            }

            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { _ in
                            dragCount += 1
                            startHeartGeneration()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                stopHeartGeneration()
                            }
                        }
                )
        }
    }

    func startHeartGeneration() {
        guard heartGenerationTimer == nil else { return }
        heartGenerationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            addHeart()
        }
    }

    func stopHeartGeneration() {
        heartGenerationTimer?.invalidate()
        heartGenerationTimer = nil
    }

    func addHeart() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let baseX = screenWidth / 2
        let baseY = screenHeight / 2 - 100
        let randomX = CGFloat.random(in: (baseX - 30)...(baseX + 30))
        let randomY = CGFloat.random(in: (baseY - 30)...(baseY + 30))

        var newHeart = Heart(position: CGPoint(x: randomX, y: randomY))
        hearts.append(newHeart)

        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 1.5)) {
                if let index = hearts.firstIndex(where: { $0.id == newHeart.id }) {
                    hearts[index].offset.height = -150
                    hearts[index].opacity = 0.0
                    hearts[index].scale = 2.0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                hearts.removeAll { $0.id == newHeart.id }
            }
        }
    }
}

struct RealityKitViewContainer: UIViewRepresentable {
    @Binding var dragCount: Int

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)

        // === Directional Light 追加 ===
        let lightAnchor = AnchorEntity(world: .zero)
        let directionalLight = DirectionalLight()
        directionalLight.light.intensity = 2000  // 明るさ
        directionalLight.light.color = .white
        directionalLight.orientation = simd_quatf(angle: .pi, axis: [0, 0.5, 0]) // 上から下へ照らす
        lightAnchor.addChild(directionalLight)
        arView.scene.anchors.append(lightAnchor)

        if let shimaenaga = createShimaenaga2() {
            context.coordinator.cheekEntities = shimaenaga.cheeks
            context.coordinator.eyeEntities = shimaenaga.eyes
            let anchor = AnchorEntity(plane: .horizontal)
            anchor.addChild(shimaenaga.model)
            arView.scene.anchors.append(anchor)
        }

        context.coordinator.arView = arView
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        guard let cheeks = context.coordinator.cheekEntities,
              let eyes = context.coordinator.eyeEntities else { return }

        for cheek in cheeks {
            cheek.isEnabled = dragCount >= 3
        }

        for eye in eyes {
            eye.scale = dragCount >= 3 ? SIMD3<Float>(1.0, 0.3, 1.0) : SIMD3<Float>(1.0, 1.0, 1.0)
        }
    }

    class Coordinator {
        var arView: ARView?
        var cheekEntities: [ModelEntity]?
        var eyeEntities: [ModelEntity]?
    }
}

struct Shimaenaga {
    var model: ModelEntity
    var cheeks: [ModelEntity]
    var eyes: [ModelEntity]
}

func createShimaenaga2() -> Shimaenaga? {
    let bodyMaterial = SimpleMaterial(color: .white, roughness: 1.0, isMetallic: false)
    let wingMaterial = SimpleMaterial(color: .brown, roughness: 1.0, isMetallic: false)
    let eyeMaterial = SimpleMaterial(color: .black, isMetallic: false)

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

    let cheekMaterial = SimpleMaterial(color: UIColor(red: 1.0, green: 0.6, blue: 0.7, alpha: 1.0), isMetallic: false)
    let leftCheek = ModelEntity(mesh: .generateSphere(radius: 0.006), materials: [cheekMaterial])
    leftCheek.position = [-0.017, 0.007, 0.026]
    leftCheek.isEnabled = false

    let rightCheek = ModelEntity(mesh: .generateSphere(radius: 0.006), materials: [cheekMaterial])
    rightCheek.position = [0.017, 0.007, 0.026]
    rightCheek.isEnabled = false

    let shimaenagaModel = ModelEntity()
    shimaenagaModel.addChild(body)
    shimaenagaModel.addChild(head)
    head.addChild(leftEye)
    head.addChild(rightEye)
    head.addChild(beak)
    head.addChild(leftCheek)
    head.addChild(rightCheek)
    body.addChild(leftWing)
    body.addChild(rightWing)

    return Shimaenaga(model: shimaenagaModel,
                      cheeks: [leftCheek, rightCheek],
                      eyes: [leftEye, rightEye])
}

