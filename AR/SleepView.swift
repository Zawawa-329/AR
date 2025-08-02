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
    
    @StateObject private var coordinator = ARViewCoordinator()

    enum Mode {
        case care, walk, dressUp, content
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ARViewContainer(shimaScreenPosition: $shimaScreenPosition, coordinator: coordinator)

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
                            coordinator.toggleEyes(isClosed: isLightOff) // 👈 ここで目の状態を反映！
                               
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
                case .care: CareView()
                case .walk: WalkView()
                case .dressUp: DressUpView()
                case .content: ContentView()
                }
            }
        }
        .onAppear {
            AudioManager.shared.playBGM(named: "bgm-sleep") // BGM 再生
        }
        .onDisappear {
            AudioManager.shared.stopBGM() // BGM 停止
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
}

// MARK: - ARViewContainer

struct ARViewContainer: UIViewRepresentable {
    @Binding var shimaScreenPosition: CGPoint?
    var coordinator: ARViewCoordinator

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        coordinator.arView = arView

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)

        // アンカー設置
        let anchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.2, 0.2])
        arView.scene.anchors.append(anchor)
        
        // カメラ位置を取得
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let cameraTransform = arView.session.currentFrame?.camera.transform {
                let cameraPosition = SIMD3<Float>(
                    cameraTransform.columns.3.x,
                    cameraTransform.columns.3.y,
                    cameraTransform.columns.3.z
                )
                
               
                // 足元に大きめの雲を置く
                    let bigCloud = createCloud()
                bigCloud.scale = [1.5, 1.5, 0.5]  // 大きさ調整
                bigCloud.position = SIMD3<Float>(cameraPosition.x, cameraPosition.y - 0.3, cameraPosition.z)
// 足元より少し下
                    anchor.addChild(bigCloud)
            }else {
                print("⚠️ カメラ位置の取得に失敗しました")
            }
        }
        
        
        let lightEntity = Entity()
        lightEntity.components.set(PointLightComponent(color: .white, intensity: 10000))
        lightEntity.position = [0, 0.5, 0]
        anchor.addChild(lightEntity)

        // 🐦 シマエナガの作成と追加
        let shimaEntity = createShimaenaga()
        anchor.addChild(shimaEntity)
        context.coordinator.shimaEntity = shimaEntity

        // フレームごとに座標更新
        arView.scene.subscribe(to: SceneEvents.Update.self) { _ in
            if let position = context.coordinator.screenPosition(for: context.coordinator.shimaEntity) {
                DispatchQueue.main.async {
                    self.shimaScreenPosition = position
                }
            }
        }.store(in: &context.coordinator.cancellables)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    class Coordinator: ARViewCoordinator {
        var cancellables = Set<AnyCancellable>()
    }
}

// MARK: - ARViewCoordinator

class ARViewCoordinator:ObservableObject {
    var arView: ARView?
    var shimaEntity: Entity?
    
    func screenPosition(for entity: Entity?) -> CGPoint? {
        guard let entity = entity, let arView = arView else { return nil }
        let worldPosition = entity.position(relativeTo: nil)
        let projected = arView.project(worldPosition + SIMD3<Float>(0, 0.15, 0)) // 頭上少し上
        return projected.map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) }
    }
    
    // ✅ 目の開閉ロジック
        func toggleEyes(isClosed: Bool) {
            let openEyes = ["leftEye", "rightEye"]
            let closedEyes = ["closedLeftEye", "closedRightEye"]

            for name in openEyes {
                shimaEntity?.findEntity(named: name)?.isEnabled = !isClosed
            }
            for name in closedEyes {
                shimaEntity?.findEntity(named: name)?.isEnabled = isClosed
            }
        }
    
}

// MARK: - 通知定義

extension Notification.Name {
    static let zzzHitNotification = Notification.Name("zzzHitNotification")
}

// MARK: - AudioManager




func createShimaenaga() -> ModelEntity {
    let pajamaColor = UIColor(red: 0.6, green: 0.85, blue: 1.0, alpha: 1.0)
    let bodyMaterial = SimpleMaterial(color: .white, roughness: 1.0, isMetallic: false)
    let wingMaterial = SimpleMaterial(color: .brown, roughness: 1.0, isMetallic: false)
    let eyeMaterial = SimpleMaterial(color: .black, isMetallic: false)
    let closedEyeMaterial = SimpleMaterial(color: .black, isMetallic: false)

    let body = ModelEntity(mesh: .generateSphere(radius: 0.05), materials: [bodyMaterial])
    let head = ModelEntity(mesh: .generateSphere(radius: 0.035), materials: [bodyMaterial])
    head.position = [0, 0.045, 0]

    let leftEye = ModelEntity(mesh: .generateSphere(radius: 0.003), materials: [eyeMaterial])
    leftEye.position = [-0.01, 0.015, 0.032]
    let rightEye = ModelEntity(mesh: .generateSphere(radius: 0.003), materials: [eyeMaterial])
    rightEye.position = [0.01, 0.015, 0.032]
    
    // 閉じた目（楕円または薄い球体で代用）
    let closedLeftEye = ModelEntity(mesh: .generateBox(size: [0.01, 0.001, 0.001]), materials: [closedEyeMaterial])
    closedLeftEye.position = [-0.01, 0.015, 0.032]
    closedLeftEye.name = "closedLeftEye"
    closedLeftEye.isEnabled = false // 初期状態では非表示
    
    let closedRightEye = ModelEntity(mesh: .generateBox(size: [0.01, 0.001, 0.001]), materials: [closedEyeMaterial])
    closedRightEye.position = [0.01, 0.015, 0.032]
    closedRightEye.name = "closedRightEye"
    closedRightEye.isEnabled = false

    let beak = ModelEntity(mesh: .generateCone(height: 0.004, radius: 0.005), materials: [eyeMaterial])
    beak.position = [0, 0.01, 0.033]

    let wingMesh = MeshResource.generateSphere(radius: 0.03)
    let leftWing = ModelEntity(mesh: wingMesh, materials: [wingMaterial])
    leftWing.position = [-0.025, 0.0, -0.01]
    let rightWing = ModelEntity(mesh: wingMesh, materials: [wingMaterial])
    rightWing.position = [0.025, 0.0, -0.01]
    
    
    // フード（頭にかぶせる半球 or 小さな球体）
    let hoodMaterial = SimpleMaterial(color: pajamaColor,
                                      roughness: 1.0,
                                      isMetallic: false)
    let hood = ModelEntity(mesh: .generateSphere(radius: 0.038), materials: [hoodMaterial])
    hood.position = [0, 0.035, 0] // 頭にかぶさるように
    hood.name = "hood"
    // フードは常に表示するので isEnabled = true（または書かない）

    // 🐰 左耳
    let leftEar = ModelEntity(mesh:.generateSphere(radius: 0.01), materials: [hoodMaterial])
    leftEar.position = [-0.015, 0.045, 0]
    leftEar.orientation = simd_quatf(angle: .pi / 12, axis: [0, 0, 1])
    hood.addChild(leftEar)

    // 🐰 右耳
    let rightEar = ModelEntity(mesh: .generateSphere(radius: 0.01), materials: [hoodMaterial])
    rightEar.position = [0.015, 0.045, 0]
    rightEar.orientation = simd_quatf(angle: -.pi / 12, axis: [0, 0, 1])
    hood.addChild(rightEar)

    // フードを head にかぶせる
    head.addChild(hood)

    let shimaenagaModel = ModelEntity()
    shimaenagaModel.addChild(body)
    shimaenagaModel.addChild(head)
    head.addChild(leftEye)
    head.addChild(rightEye)
    head.addChild(closedLeftEye)
    head.addChild(closedRightEye)
    head.addChild(beak)
    body.addChild(leftWing)
    body.addChild(rightWing)
    
    // 1. createShimaenaga()の中に小さい雲を置く（今のコードのまま）
    let smallCloud = createCloud()
    smallCloud.position = [0, 0, -0.06]
    shimaenagaModel.addChild(smallCloud)


    
    shimaenagaModel.orientation = simd_quatf(angle: .pi/2, axis: [1, 0, 0])
    * simd_quatf(angle: .pi, axis: [0, 1, 0])

    return shimaenagaModel
}





func createCloud() -> ModelEntity {
    let cloudMaterial = SimpleMaterial(color: .white.withAlphaComponent(0.8), isMetallic: false)
    
    let main = ModelEntity(mesh: .generateSphere(radius: 0.2), materials: [cloudMaterial])
    let puff1 = ModelEntity(mesh: .generateSphere(radius: 0.12), materials: [cloudMaterial])
    let puff2 = ModelEntity(mesh: .generateSphere(radius: 0.15), materials: [cloudMaterial])
    let puff3 = ModelEntity(mesh: .generateSphere(radius: 0.13), materials: [cloudMaterial])
    
    puff1.position = [0.15, 0.02, 0]
    puff2.position = [-0.13, 0.01, 0.05]
    puff3.position = [0, 0, -0.15]
    
    main.addChild(puff1)
    main.addChild(puff2)
    main.addChild(puff3)
    
    main.name = "mokomokoCloud"
    return main
    
    
}

