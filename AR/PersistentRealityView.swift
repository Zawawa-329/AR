//
//  PersistentRealityView.swift
//  AR
//
//  Created by owner on 2025/08/01.
//

import SwiftUI
import RealityKit

struct PersistentRealityView: View {
    var body: some View {
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
    }
}
