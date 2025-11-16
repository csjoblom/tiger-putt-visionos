//
//  PuttVisionManager.swift
//  xr-tiger-putt
//
//  Created by Chris Sjoblom on 11/16/25.
//

import Foundation
import ARKit
import Vision
import Combine

@MainActor
final class PuttVisionManager: NSObject, ObservableObject {
    @Published var isSessionRunning: Bool = false
    // Later: setup ARSession, process frames, detect green/hole/balls
}

