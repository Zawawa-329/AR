//
//  ContentView.swift
//  AR
//
//  Created by owner on 2025/07/29.
//
/*import SwiftUI
import RealityKit

struct ContentView: View {
    @State private var isMenuOpen = false
    @State private var selectedMode: Mode? = nil

    enum Mode {
        case care, walk, sleep, dressUp
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RealityView { content in
                let model = Entity()
                let mesh = MeshResource.generateBox(size: 0.1, cornerRadius: 0.005)
                let material = SimpleMaterial(color: .gray, roughness: 0.15, isMetallic: true)
                model.components.set(ModelComponent(mesh: mesh, materials: [material]))
                model.position = [0, 0.05, 0]

                let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
                anchor.addChild(model)
                content.add(anchor)

                content.camera = .spatialTracking
            }
            .edgesIgnoringSafeArea(.all)

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

            if isMenuOpen {
                VStack(alignment: .leading, spacing: 20) {
                    Button("お世話") { selectedMode = .care; isMenuOpen = false} .foregroundColor(Color.green)
                    Button("お散歩") { selectedMode = .walk; isMenuOpen = false} .foregroundColor(Color.green)
                    Button("おやすみ") { selectedMode = .sleep; isMenuOpen = false} .foregroundColor(Color.green)
                    Button("お着替え") { selectedMode = .dressUp; isMenuOpen = false} .foregroundColor(Color.green)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 5)
                .padding(.top, 70)
                .padding(.leading, 10)
                .transition(.move(edge: .leading))
            }

            if let mode = selectedMode {
                switch mode {
                case .care: CareView()
                case .walk: WalkView()
                case .sleep: SleepView()
                case .dressUp: DressUpView()                }
            }
        }
    }
}
*/
import SwiftUI

struct ContentView: View {
    @State private var selectedMode: Mode? = nil
    @State private var isMenuOpen: Bool = false

    enum Mode {
        case content, care, walk, sleep, dressUp
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            PersistentRealityView() // RealityKit を固定
                .zIndex(0)
            VStack {
                HStack {
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

                    Spacer()
                }
                .padding(.top, 20)
                .padding(.leading, 20)

                Spacer()
            }
            .zIndex(1)

            // メニュー
            if isMenuOpen {
                VStack(alignment: .leading, spacing: 20) {
                    Button("お世話") { selectedMode = .care; isMenuOpen = false }.foregroundColor(Color.green)
                    Button("お散歩") { selectedMode = .walk; isMenuOpen = false }.foregroundColor(Color.green)
                    Button("おやすみ") { selectedMode = .sleep; isMenuOpen = false }.foregroundColor(Color.green)
                    Button("お着替え") { selectedMode = .dressUp; isMenuOpen = false }.foregroundColor(Color.green)
                    Button("ホーム") { selectedMode = .content; isMenuOpen = false }.foregroundColor(Color.green)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 5)
                .padding(.top, 70)
                .padding(.leading, 10)
                .transition(.move(edge: .leading))
                .zIndex(2)
            }

            // オーバーレイ表示（選択されたモードに応じて）
            if let mode = selectedMode {
                switch mode {
                case .care:
                    CareView()
                case .walk:
                    WalkView()
                case .sleep:
                    SleepView()
                case .dressUp:
                    DressUpView()
                case .content:
                    ContentView()
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

