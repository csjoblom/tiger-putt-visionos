import XCTest
@testable import xr_tiger_putt

final class xr_tiger_puttTests: XCTestCase {

    func test_reset_clears_session_and_stats() {
        let state = PuttingSessionState(
            phase: .reviewing,
            detectedHole: DetectedHole(position: .init(0, 0, 0)),
            detectedBalls: [DetectedBall(position: .init(1, 0, 0))],
            activeBallID: UUID(),
            tigerModeEnabled: true,
            puttHistory: [PuttShot(madePutt: true)],
            currentShot: PuttShot(),
            totalPutts: 3,
            madePutts: 2,
            showDebugOverlays: true
        )

        state.resetSession()

        XCTAssertEqual(state.phase, .idle)
        XCTAssertNil(state.detectedHole)
        XCTAssertTrue(state.detectedBalls.isEmpty)
        XCTAssertNil(state.activeBallID)
        XCTAssertTrue(state.puttHistory.isEmpty)
        XCTAssertNil(state.currentShot)
        XCTAssertEqual(state.totalPutts, 0)
        XCTAssertEqual(state.madePutts, 0)
        XCTAssertFalse(state.tigerModeEnabled)
        XCTAssertFalse(state.showDebugOverlays)
    }

    func test_update_detections_progresses_to_ready_and_sets_active_ball() {
        let hole = DetectedHole(position: .init(0, 0, 0))
        let ball = DetectedBall(position: .init(0.5, 0, 0))
        let state = PuttingSessionState()

        state.updateDetections(hole: hole, balls: [ball])

        XCTAssertEqual(state.detectedHole, hole)
        XCTAssertEqual(state.detectedBalls, [ball])
        XCTAssertEqual(state.phase, .ready)
        XCTAssertEqual(state.activeBall?.id, ball.id)
    }

    func test_begin_and_end_shot_records_history_and_stats() {
        let hole = DetectedHole(position: .init(0, 0, 0), radius: 0.06)
        let ball = DetectedBall(position: .init(0, 0, 0.5))
        let state = PuttingSessionState(
            phase: .ready,
            detectedHole: hole,
            detectedBalls: [ball],
            activeBallID: ball.id
        )

        state.beginShot()
        XCTAssertEqual(state.phase, .putting)
        XCTAssertEqual(state.currentShot?.startBallPosition, ball.position)

        state.endShot(finalBallPosition: .init(0, 0, 0.02))

        XCTAssertEqual(state.phase, .reviewing)
        XCTAssertEqual(state.puttHistory.count, 1)
        XCTAssertEqual(state.totalPutts, 1)
        XCTAssertEqual(state.madePutts, 1)
        XCTAssertEqual(state.puttHistory.first?.madePutt, true)
        XCTAssertNotNil(state.puttHistory.first?.distanceMeters)
    }

    func test_continue_practice_only_from_reviewing() {
        let state = PuttingSessionState(phase: .ready)
        state.continuePractice()
        XCTAssertEqual(state.phase, .ready)

        state.phase = .reviewing
        state.continuePractice()
        XCTAssertEqual(state.phase, .ready)
    }
}
