//
//  ARViewController.swift
//  HelloAR
//
//  Created by Aleksy Krolczyk on 04/09/2022.
//

import Foundation
import RealityKit
import ARKit

let rickrollURL = Bundle.main.url(forResource: "rickroll", withExtension: "mp4")!
var alreadyAdded = false

extension ARView: ARSessionDelegate {
    func configure() {
        self.session.delegate = self
        
        let config = ARWorldTrackingConfiguration()
        
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        
        if let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) {
            config.detectionImages = referenceImages
        }
        
        self.session.run(config)
        
    }
    
    public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let imageAnchor = anchor as? ARImageAnchor {
                debugPrint("Found image anchor")
                if (alreadyAdded) {
                    debugPrint("Video already playing, skipping")
                    return
                }
                
                let width = Float(imageAnchor.referenceImage.physicalSize.width)
                let height = Float(imageAnchor.referenceImage.physicalSize.height)
                
                let player = AVPlayer(url: rickrollURL)
                let material = VideoMaterial(avPlayer: player)
                let entity = ModelEntity(mesh: MeshResource.generatePlane(width: width, height: height), materials: [material])
                entity.transform.rotation = simd_quatf(angle: -.pi/2, axis: SIMD3<Float>(1,0,0))
                
//                entity.transform = Transform(matrix: imageAnchor.transform)
                
                let coords = simd_make_float3(imageAnchor.transform.columns.3)
                let anchor = AnchorEntity(world: coords)
            
                anchor.addChild(entity)

                scene.addAnchor(anchor)
                
                try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
                player.play()
                alreadyAdded = true
                
            }
        }
    }
    
}

class ARViewController: ObservableObject {
    
    public static let shared = ARViewController()
    @Published public var arView: ARView
    
    private init() {
        self.arView = ARView(frame: .zero)
    }
    
    public func startSession() {
        arView.configure()
        startTapDetection()
    }
    

    private func startTapDetection() {
        arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:))))
    }
    
    @objc
    private func handleTap(recognizer: UITapGestureRecognizer) {
        
        let tapLocation = recognizer.location(in: arView)
        let res = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
        guard let firstHit = res.first else { return }
        
        let worldPos = simd_make_float3(firstHit.worldTransform.columns.3)
        
        let radius: Float = 0.5
        let sphere = createSphere(radius: radius)
        placeObject(sphere, at: worldPos + SIMD3<Float>(0, radius, 0))
        
    }
    
    func createSphere(radius: Float) -> ModelEntity {
        let sphere = MeshResource.generateSphere(radius: radius)
        let material = SimpleMaterial(color: .red, roughness: 0.5, isMetallic: true)
        
        let sphereEntity = ModelEntity(mesh: sphere, materials: [material])
        return sphereEntity
    }
    
    func placeObject(_ object: ModelEntity, at position: SIMD3<Float>) {
        let anchor = AnchorEntity(world: position)
        anchor.addChild(object)
        arView.scene.anchors.append(anchor)
    }
    
    func installGestures(on object: ModelEntity) {
        object.generateCollisionShapes(recursive: true)
        arView.installGestures([.rotation, .scale], for: object)
    }
    
}
