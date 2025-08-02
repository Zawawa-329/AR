//
//  DressUpView.swift
//  AR
//
//  Created by owner on 2025/08/01.
//
import SwiftUI
import RealityKit

struct DressUpView: View {
    @State private var isMenuOpen = false
    @State private var selectedMode: Mode? = nil

    @State private var red: Double = 1.0
    @State private var green: Double = 1.0
    @State private var blue: Double = 1.0

    @State private var loadedEntity: Entity?

    enum Mode {
        case care, walk, sleep, content
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RealityView { content in
                let anchor = AnchorEntity(plane: .horizontal)
                content.add(anchor)

                let light = Entity()
                light.components.set(PointLightComponent(color: .white, intensity: 5000))
                light.position = [0, 0.5, 0]
                anchor.addChild(light)

                if loadedEntity == nil {
                    let model = createShimaenaga(red: red, green: green, blue: blue)
                    anchor.addChild(model)
                    loadedEntity = model
                }

                content.camera = .spatialTracking
            }
            .edgesIgnoringSafeArea(.all)

            // メニュー開閉ボタン
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

            // モード選択メニュー
            if isMenuOpen {
                VStack(alignment: .leading, spacing: 20) {
                    Button("お世話") { selectedMode = .care; isMenuOpen = false }
                    Button("お散歩") { selectedMode = .walk; isMenuOpen = false }
                    Button("おやすみ") { selectedMode = .sleep; isMenuOpen = false }
                    Button("ホーム") { selectedMode = .content; isMenuOpen = false }
                }
                .foregroundColor(.green)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 5)
                .padding(.top, 70)
                .padding(.leading, 10)
                .transition(.move(edge: .leading))
            }

            // モードによる切り替えビュー
            if let mode = selectedMode {
                switch mode {
                case .care: CareView()
                case .walk: WalkView()
                case .sleep: SleepView()
                case .content: ContentView()
                }
            }

            // スライダーUI（DressUp画面のみ表示）
            if selectedMode == nil {
                VStack {
                    Spacer()
                    VStack {
                        ColorSlider(label: "Red", value: $red, onUpdate: updateMaterial)
                        ColorSlider(label: "Green", value: $green, onUpdate: updateMaterial)
                        ColorSlider(label: "Blue", value: $blue, onUpdate: updateMaterial)
                    }
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(12)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    func updateMaterial() {
        if let model = loadedEntity as? ModelEntity {
            let color = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
            let newMaterial = SimpleMaterial(color: color, roughness: 1.0, isMetallic: false)

            // ボディの色だけ更新
            if let body = model.children.first(where: { $0.name == "body" }) as? ModelEntity {
                body.model?.materials = [newMaterial]
            }
        }
    }

    // MARK: - モデル生成
    func createShimaenaga(red: Double, green: Double, blue: Double) -> ModelEntity {
        let bodyColor = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
        let bodyMaterial = SimpleMaterial(color: bodyColor, roughness: 1.0, isMetallic: false)
        let wingMaterial = SimpleMaterial(color: .brown, roughness: 1.0, isMetallic: false)
        let eyeMaterial = SimpleMaterial(color: .black, isMetallic: false)
        let ribbonMaterial = SimpleMaterial(color: .red, isMetallic: false)

        let body = ModelEntity(mesh: .generateSphere(radius: 0.05), materials: [bodyMaterial])
        body.name = "body"

        let head = ModelEntity(mesh: .generateSphere(radius: 0.035), materials: [bodyMaterial])
        head.position = [0, 0.045, 0]

        let leftEye = ModelEntity(mesh: .generateSphere(radius: 0.003), materials: [eyeMaterial])
        leftEye.position = [-0.01, 0.015, 0.032]
        let rightEye = ModelEntity(mesh: .generateSphere(radius: 0.003), materials: [eyeMaterial])
        rightEye.position = [0.01, 0.015, 0.032]

        let beak = ModelEntity(mesh: .generateCone(height: 0.004, radius: 0.005), materials: [eyeMaterial])
        beak.position = [0, 0.01, 0.033]

        let leftWing = ModelEntity(mesh: .generateSphere(radius: 0.03), materials: [wingMaterial])
        leftWing.position = [-0.025, 0.0, -0.01]
        let rightWing = ModelEntity(mesh: .generateSphere(radius: 0.03), materials: [wingMaterial])
        rightWing.position = [0.025, 0.0, -0.01]

        // 🎀 リボン
        let ribbon = ModelEntity(mesh: .generateBox(size: [0.015, 0.005, 0.005]), materials: [ribbonMaterial])
        ribbon.position = [0, 0.035, 0.03]

        // 合体
        let model = ModelEntity()
        model.addChild(body)
        body.addChild(leftWing)
        body.addChild(rightWing)

        body.addChild(head)
        head.addChild(leftEye)
        head.addChild(rightEye)
        head.addChild(beak)
        head.addChild(ribbon)

        return model
    }
}

// MARK: - スライダーコンポーネント
struct ColorSlider: View {
    var label: String
    @Binding var value: Double
    var onUpdate: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text("\(label): \(Int(value * 255))")
                .font(.caption)
                .foregroundColor(.gray)
            Slider(value: $value, in: 0...1, step: 0.01)
                .onChange(of: value) { _ in
                    onUpdate()
                }
        }
    }
}
