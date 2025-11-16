import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(simd)
import simd
#endif

/// Represents the lifecycle stage of a putting session.
enum PuttingPhase: String, Codable, CaseIterable {
    /// No green detected yet.
    case idle
    /// We’re locking in the green & hole.
    case calibrating
    /// Ready for user to putt.
    case ready
    /// Ball is in motion.
    case putting
    /// Show last putt path / stats.
    case reviewing
}

/// A detected hole in the green coordinate space.
struct DetectedHole: Identifiable, Codable, Equatable {
    /// Unique identifier for the detected hole.
    let id: UUID
    /// Center of the hole in world coordinates (meters).
    var position: SIMD3<Float>
    /// Estimated radius of the cup in meters.
    var radius: Float

    init(id: UUID = UUID(), position: SIMD3<Float>, radius: Float = 0.054) {
        self.id = id
        self.position = position
        self.radius = radius
    }
}

/// A detected golf ball in the green coordinate space.
struct DetectedBall: Identifiable, Codable, Equatable {
    /// Unique identifier for the detected ball.
    let id: UUID
    /// Current center position of the ball in world coordinates (meters).
    var position: SIMD3<Float>

    init(id: UUID = UUID(), position: SIMD3<Float>) {
        self.id = id
        self.position = position
    }
}

/// Describes a single putt attempt.
struct PuttShot: Identifiable, Codable {
    /// Unique identifier for the shot.
    let id: UUID
    /// Timestamp when the shot began.
    let timestamp: Date
    /// Starting position of the ball when the putt began.
    var startBallPosition: SIMD3<Float>?
    /// Final resting position of the ball after the putt.
    var endBallPosition: SIMD3<Float>?
    /// Distance traveled by the ball in meters, if known.
    var distanceMeters: Float?
    /// Whether the ball ended near the hole.
    var madePutt: Bool
    /// Estimated scalar speed of the shot in meters per second.
    var estimatedSpeed: Float?

    init(
        id: UUID = UUID(),
        timestamp: Date = .init(),
        startBallPosition: SIMD3<Float>? = nil,
        endBallPosition: SIMD3<Float>? = nil,
        distanceMeters: Float? = nil,
        madePutt: Bool = false,
        estimatedSpeed: Float? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.startBallPosition = startBallPosition
        self.endBallPosition = endBallPosition
        self.distanceMeters = distanceMeters
        self.madePutt = madePutt
        self.estimatedSpeed = estimatedSpeed
    }
}

/// Central source of truth for a putting session’s state and stats.
final class PuttingSessionState: ObservableObject {
    /// Current lifecycle stage of the session.
    @Published var phase: PuttingPhase
    /// Currently detected hole, if any.
    @Published var detectedHole: DetectedHole?
    /// Currently detected balls.
    @Published var detectedBalls: [DetectedBall]
    /// Which ball the user is currently hitting.
    @Published var activeBallID: UUID?
    /// Whether Tiger Mode visuals are enabled.
    @Published var tigerModeEnabled: Bool
    /// History of putt attempts.
    @Published var puttHistory: [PuttShot]
    /// The shot currently being recorded.
    @Published var currentShot: PuttShot?
    /// Total number of putts taken.
    @Published var totalPutts: Int
    /// Number of made putts.
    @Published var madePutts: Int
    /// Whether to display debugging overlays for detection.
    @Published var showDebugOverlays: Bool

    /// Percentage of made putts in the session.
    var conversionRate: Double {
        Double(madePutts) / Double(max(totalPutts, 1))
    }

    /// The currently active ball derived from `activeBallID`.
    var activeBall: DetectedBall? {
        detectedBalls.first { $0.id == activeBallID }
    }

    /// Creates a session with default values.
    init(
        phase: PuttingPhase = .idle,
        detectedHole: DetectedHole? = nil,
        detectedBalls: [DetectedBall] = [],
        activeBallID: UUID? = nil,
        tigerModeEnabled: Bool = false,
        puttHistory: [PuttShot] = [],
        currentShot: PuttShot? = nil,
        totalPutts: Int = 0,
        madePutts: Int = 0,
        showDebugOverlays: Bool = false
    ) {
        self.phase = phase
        self.detectedHole = detectedHole
        self.detectedBalls = detectedBalls
        self.activeBallID = activeBallID
        self.tigerModeEnabled = tigerModeEnabled
        self.puttHistory = puttHistory
        self.currentShot = currentShot
        self.totalPutts = totalPutts
        self.madePutts = madePutts
        self.showDebugOverlays = showDebugOverlays
    }

    /// Resets session stats, detections, and history.
    func resetSession() {
        phase = .idle
        detectedHole = nil
        detectedBalls = []
        activeBallID = nil
        puttHistory = []
        currentShot = nil
        totalPutts = 0
        madePutts = 0
        tigerModeEnabled = false
        showDebugOverlays = false
    }

    /// Begins calibration by clearing detections while preserving stats.
    func startCalibration() {
        phase = .calibrating
        detectedHole = nil
        detectedBalls = []
        activeBallID = nil
        currentShot = nil
    }

    /// Completes calibration if both a hole and at least one ball are detected.
    func completeCalibrationIfPossible() {
        guard detectedHole != nil, !detectedBalls.isEmpty else { return }
        phase = .ready
        if activeBallID == nil {
            activeBallID = detectedBalls.first?.id
        }
    }

    /// Applies the latest detection results from the vision system.
    /// - Parameters:
    ///   - hole: The newly detected hole, if any.
    ///   - balls: The currently detected balls.
    func updateDetections(hole: DetectedHole?, balls: [DetectedBall]) {
        detectedHole = hole
        detectedBalls = balls

        if activeBallID == nil {
            activeBallID = balls.first?.id
        } else if !balls.contains(where: { $0.id == activeBallID }) {
            activeBallID = balls.first?.id
        }

        if phase == .idle, hole != nil, !balls.isEmpty {
            phase = .ready
        }
    }

    /// Begins tracking a shot when the player initiates a putt.
    func beginShot() {
        guard phase == .ready else { return }
        phase = .putting
        let shot = PuttShot(
            startBallPosition: activeBall?.position,
            madePutt: false
        )
        currentShot = shot
    }

    /// Ends the current shot, records stats, and transitions to reviewing.
    /// - Parameter finalBallPosition: The ball’s resting position after the putt.
    func endShot(finalBallPosition: SIMD3<Float>?) {
        guard phase == .putting, var shot = currentShot else { return }

        shot.endBallPosition = finalBallPosition

        if let start = shot.startBallPosition, let end = finalBallPosition {
            shot.distanceMeters = simd_distance(start, end)
        }

        if let hole = detectedHole, let final = finalBallPosition {
            let distanceToHole = simd_distance(hole.position, final)
            let makeThreshold = max(hole.radius, 0.05) + 0.05
            shot.madePutt = distanceToHole <= makeThreshold
        } else {
            shot.madePutt = false
        }

        totalPutts += 1
        if shot.madePutt {
            madePutts += 1
        }

        puttHistory.append(shot)
        currentShot = shot
        phase = .reviewing
    }

    /// Returns to the ready state to continue practice after reviewing a shot.
    func continuePractice() {
        guard phase == .reviewing else { return }
        phase = .ready
    }

    /// Toggles Tiger Mode visualizations.
    func toggleTigerMode() {
        tigerModeEnabled.toggle()
    }

    /// Toggles debug overlays for detection visualization.
    func toggleDebugOverlays() {
        showDebugOverlays.toggle()
    }
}
