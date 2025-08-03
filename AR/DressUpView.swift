//
//  DressUpView.swift
//  AR
//
//  Created by owner on 2025/08/01.
//

import SwiftUI
import RealityKit

struct DressUpView: View {
    @State private var red: Double = 1.0
    @State private var green: Double = 1.0
    @State private var blue: Double = 1.0
    @State private var selectedAccessory: HeadAccessory = .ribbon
    @State private var anchor = AnchorEntity(plane: .horizontal)
    @State private var loadedEntity: Entity?

    @State private var isMenuOpen = false
    @State private var selectedMode: Mode? = nil

    enum HeadAccessory {
        case none, ribbon, hat, headband
    }

    enum Mode {
        case care, walk, sleep, content
    }

    var body: some View {
        ZStack {
            RealityView { content in
                content.add(anchor)
                content.camera = .spatialTracking

                if anchor.children.isEmpty {
                    let light = Entity()
                    light.components.set(PointLightComponent(color: .white, intensity: 5000))
                    light.position = [0, 0.5, 0]
                    anchor.addChild(light)

                    reloadModel()
                }
            }
            .edgesIgnoringSafeArea(.all)

            // ✅ ハンバーガーメニュー（左上）位置修正
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
                    .padding(.top, 50)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading) // これが重要！
            
            // ✅ モード選択メニュー（表示中）
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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            // ✅ カラーバーとアクセサリーボタンは selectedMode == nil のときだけ表示
            if selectedMode == nil {
                VStack {
                    Spacer()
                    VStack {
                        ColorSlider(label: "Red", value: $red, onUpdate: reloadModel)
                        ColorSlider(label: "Green", value: $green, onUpdate: reloadModel)
                        ColorSlider(label: "Blue", value: $blue, onUpdate: reloadModel)
                    }
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(12)
                    .padding(.bottom, 40)
                }
                
                VStack(spacing: 10) {
                    AccessoryButton(imageName: "ribbon", action: { selectedAccessory = .ribbon; reloadModel() })
                    AccessoryButton(imageName: "hat", action: { selectedAccessory = .hat; reloadModel() })
                    AccessoryButton(imageName: "headband", action: { selectedAccessory = .headband; reloadModel() })
                    AccessoryButton(imageName: "none", action: { selectedAccessory = .none; reloadModel() })
                }
                .padding()
                .background(Color.white.opacity(0.8))
                .cornerRadius(12)
                .shadow(radius: 5)
                .padding(.trailing, 10)
                .padding(.bottom, 150)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 40)
            }

            // ✅ モードによる切り替えビュー（後ろに置く）
            if let mode = selectedMode {
                switch mode {
                case .care: CareView()
                case .walk: WalkView()
                case .sleep: SleepView()
                case .content: ContentView()
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }

    // モデル再生成
    func reloadModel() {
        if let entity = loadedEntity {
            entity.removeFromParent()
        }

        let model = createShimaenaga(red: red, green: green, blue: blue, accessory: selectedAccessory)
        anchor.addChild(model)
        loadedEntity = model
    }

    // モデル生成
    func createShimaenaga(red: Double, green: Double, blue: Double, accessory: HeadAccessory) -> ModelEntity {
        let bodyColor = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
        let bodyMaterial = SimpleMaterial(color: bodyColor, roughness: 1.0, isMetallic: false)
        let wingMaterial = SimpleMaterial(color: .brown, roughness: 1.0, isMetallic: false)
        let eyeMaterial = SimpleMaterial(color: .black, isMetallic: false)

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

        // アクセサリー
        switch accessory {
        case .ribbon:
            let triangleMesh = MeshResource.generateCone(height: 0.02, radius: 0.005)
            let triangleMaterial = SimpleMaterial(color: .red, isMetallic: false)

            // 左リボン：90度回転（X軸回転）
            let leftRibbon = ModelEntity(mesh: triangleMesh, materials: [triangleMaterial])
            leftRibbon.position = [-0.007, 0.035, 0.03]
            let rotationX_left = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])  // X軸回転90度
            let rotationZ_left = simd_quatf(angle: -(.pi / 2), axis: [0, 0, 1])
            leftRibbon.orientation = simd_mul(rotationX_left, rotationZ_left)

            // 右リボン：90度回転（X軸回転）＋左右反転（Y軸回転180度）
            let rightRibbon = ModelEntity(mesh: triangleMesh, materials: [triangleMaterial])
            rightRibbon.position = [0.007, 0.035, 0.03]
            // X軸90度回転 + Y軸180度回転で反転させる
            let rotationX = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            let rotationZ = simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
            let rotationY = simd_quatf(angle: .pi, axis: [0, 1, 0])

            rightRibbon.orientation = simd_mul(simd_mul(rotationX, rotationZ), rotationY)

            head.addChild(leftRibbon)
            head.addChild(rightRibbon)

        case .hat:
            let hatBodyMesh = MeshResource.generateCylinder(height: 0.035, radius: 0.01) // 高さを0.04から0.035に少し低く
            let hatBodyMaterial = SimpleMaterial(color: .yellow, isMetallic: false)
            let hatBody = ModelEntity(mesh: hatBodyMesh, materials: [hatBodyMaterial])
            hatBody.position = [0, 0.05, 0]

            let brimMesh = MeshResource.generateCylinder(height: 0.003, radius: 0.02)
            let brimMaterial = SimpleMaterial(color: .yellow, isMetallic: false)
            let brim = ModelEntity(mesh: brimMesh, materials: [brimMaterial])
            brim.position = [0, 0.035, 0]

            head.addChild(hatBody)
            head.addChild(brim)

        case .headband:
            let greenColor = UIColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 1.0)
            let greenMaterial = SimpleMaterial(color: greenColor, isMetallic: false)

            let sphere = ModelEntity(mesh: .generateSphere(radius: 0.025), materials: [greenMaterial])  //
            sphere.position = [0, 0.015, 0]

            head.addChild(sphere)

        case .none:
            break
        }


        // 合体
        let model = ModelEntity()
        model.addChild(body)
        body.addChild(leftWing)
        body.addChild(rightWing)
        body.addChild(head)
        head.addChild(leftEye)
        head.addChild(rightEye)
        head.addChild(beak)

        return model
    }
}

// カラースライダー
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

// アクセサリーボタン
struct AccessoryButton: View {
    var imageName: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(imageName)
                .resizable()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}
