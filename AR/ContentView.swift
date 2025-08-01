//
//  ContentView.swift
//  AR
//
//  Created by owner on 2025/07/29.
//
import SwiftUI
import RealityKit

struct ContentView: View {
    @State private var isMenuOpen = false

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

            // ハンバーガーボタン
            Button(action: {
                withAnimation {
                    isMenuOpen.toggle()
                }
            }) {
                Image(systemName: "line.3.horizontal")
                    .resizable()
                    .frame(width: 30, height: 20)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding()

            // メニュー本体
            if isMenuOpen {
                VStack(alignment: .leading, spacing: 20) {
                    Button("設定") {
                        print("設定 tapped")
                    }
                    Button("ヘルプ") {
                        print("ヘルプ tapped")
                    }
                    Button("閉じる") {
                        withAnimation {
                            isMenuOpen = false
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 5)
                .padding(.top, 70)
                .padding(.leading, 10)
                .transition(.move(edge: .leading))
            }
        }
    }
}
