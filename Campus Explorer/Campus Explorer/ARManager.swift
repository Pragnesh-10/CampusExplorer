//
//  ARManager.swift
//  Campus Explorer
//
//  Manages AR session and configuration
//

import Foundation
import ARKit
import RealityKit
import Combine
import CoreLocation
import Observation

@Observable
class ARManager: NSObject, ARSessionDelegate {
    var isARSupported: Bool {
        return ARWorldTrackingConfiguration.isSupported
    }
    
    var session = ARSession()
    var arView: ARView?
    var anchors: [ARAnchor] = []
    
    // Tracking status message
    var trackingStatus: String = "Initializing..."
    
    override init() {
        super.init()
        session.delegate = self
    }
    
    func startSession() {
        guard isARSupported else {
            trackingStatus = "AR not supported on this device/simulator"
            return
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        
        // If we want geo-anchors, we'd use ARGeoTrackingConfiguration
        // But for simulator/generic use, standard world tracking is safer.
        // We can simulate geo-anchors by placing relative to user start.
        
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func pauseSession() {
        session.pause()
    }
    
    // MARK: - ARSessionDelegate
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
            trackingStatus = "Tracking not available"
        case .limited(let reason):
            switch reason {
            case .initializing:
                trackingStatus = "Initializing..."
            case .excessiveMotion:
                trackingStatus = "Too much motion"
            case .insufficientFeatures:
                trackingStatus = "Not enough detail"
            case .relocalizing:
                trackingStatus = "Relocalizing..."
            @unknown default:
                trackingStatus = "Tracking limited"
            }
        case .normal:
            trackingStatus = "Tracking normal"
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        trackingStatus = "Error: \(error.localizedDescription)"
    }
    
    // MARK: - Placing Objects
    func addAnchor(at position: SIMD3<Float>) {
        let anchor = ARAnchor(transform: simd_float4x4(translation: position))
        session.add(anchor: anchor)
        anchors.append(anchor)
    }
    
    private func simd_float4x4(translation: SIMD3<Float>) -> simd_float4x4 {
        var matrix = matrix_identity_float4x4
        matrix.columns.3.x = translation.x
        matrix.columns.3.y = translation.y
        matrix.columns.3.z = translation.z
        return matrix
    }
}
