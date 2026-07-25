import XCTest
@testable import PoseKit

final class BodyRegionTests: XCTestCase {
    let standing = Fixtures.standing

    // MARK: - Bone → region mapping

    func testEveryBoneMapsToARegion() {
        for bone in Bone.allCases {
            XCTAssertTrue(BodyRegion.allCases.contains(bone.region),
                          "\(bone) maps outside the region set")
        }
    }

    func testRegionCoversTheExpectedBones() {
        XCTAssertEqual(Bone.leftUpperArm.region, .leftArm)
        XCTAssertEqual(Bone.leftForearm.region, .leftArm)
        XCTAssertEqual(Bone.rightUpperArm.region, .rightArm)
        XCTAssertEqual(Bone.rightForearm.region, .rightArm)
        XCTAssertEqual(Bone.leftThigh.region, .leftLeg)
        XCTAssertEqual(Bone.leftShin.region, .leftLeg)
        XCTAssertEqual(Bone.rightThigh.region, .rightLeg)
        XCTAssertEqual(Bone.rightShin.region, .rightLeg)
        XCTAssertEqual(Bone.torso.region, .torso)
        XCTAssertEqual(Bone.neck.region, .head)
    }

    /// The hint string and the body map must name a limb identically — they are
    /// two renderings of one fact.
    func testCoachingNameComesFromTheRegion() {
        for bone in Bone.allCases {
            XCTAssertEqual(bone.coachingName, bone.region.label)
        }
    }

    // MARK: - Region scores

    func testIdenticalPoseScoresEveryRegionPerfect() {
        let regions = LimbSimilarity.regionScores(reference: standing, live: standing)
        XCTAssertEqual(regions.count, BodyRegion.allCases.count)
        for (_, s) in regions { XCTAssertEqual(s, 1.0, accuracy: 1e-5) }
    }

    /// A region takes its WORST bone, not its mean. A correct upper arm must not
    /// average away a forearm pointing the wrong way.
    func testRegionTakesWorstBoneNotMean() {
        var p = standing.points
        let elbow = p[.leftElbow]!
        let wrist = p[.leftWrist]!
        p[.leftWrist] = elbow - (wrist - elbow) // forearm reversed, upper arm intact
        let live = PoseVector(points: p)

        let bones = LimbSimilarity.boneScores(reference: standing, live: live)
        XCTAssertEqual(bones[.leftUpperArm]!, 1.0, accuracy: 1e-5)
        XCTAssertEqual(bones[.leftForearm]!, 0.0, accuracy: 1e-5)

        let regions = LimbSimilarity.regionScores(reference: standing, live: live)
        XCTAssertEqual(regions[.leftArm]!, 0.0, accuracy: 1e-5,
                       "region must report its worst bone; a mean would read 0.5")
    }

    func testRegionOmittedWhenAllItsBonesAreMissing() {
        var p = standing.points
        p[.leftWrist] = nil
        p[.leftElbow] = nil // kills both leftArm bones
        let regions = LimbSimilarity.regionScores(reference: standing, live: PoseVector(points: p))
        XCTAssertNil(regions[.leftArm])
        XCTAssertNotNil(regions[.rightArm])
    }

    func testRegionSurvivesWhenOnlyOneOfItsBonesIsMissing() {
        var p = standing.points
        p[.leftWrist] = nil // kills leftForearm only; leftUpperArm remains
        let regions = LimbSimilarity.regionScores(reference: standing, live: PoseVector(points: p))
        XCTAssertEqual(regions[.leftArm]!, 1.0, accuracy: 1e-5)
    }

    // MARK: - Off regions (what the body map marks)

    func testNothingIsMarkedWhenThePoseMatches() {
        let off = LimbSimilarity.offRegions(reference: standing, live: standing)
        XCTAssertTrue(off.isEmpty, "a matched pose must show no marks — silence means correct")
    }

    func testOnlyTheWrongRegionIsMarked() {
        var p = standing.points
        let elbow = p[.leftElbow]!
        let wrist = p[.leftWrist]!
        p[.leftWrist] = elbow - (wrist - elbow)
        let off = LimbSimilarity.offRegions(reference: standing, live: PoseVector(points: p))
        XCTAssertEqual(off, [.leftArm])
    }

    /// The threshold is not a new number: a region is "off" exactly when it is
    /// one of the limbs holding `hold` back. Rebuilding a second threshold here
    /// is how the chip and the map would drift apart.
    func testOffThresholdIsTheHoldWorstLimbThreshold() {
        XCTAssertEqual(LimbSimilarity.regionOffThreshold,
                       ReadinessThresholds.holdWorstLimb)
    }

    // MARK: - The invariant that ties the map to the chip

    /// If the chip says `hold`, every region passed the worst-limb gate, so the
    /// map must be empty. A marked limb under a `hold` chip is the Stage 0
    /// credibility bug rebuilt in a new place.
    func testHoldImpliesNoMarkedRegions() {
        let readiness = PoseReadiness.from(overall: 0.95, worstLimb: 0.85)
        XCTAssertEqual(readiness, .hold)

        let off = LimbSimilarity.offRegions(reference: standing, live: standing)
        XCTAssertTrue(off.isEmpty)
    }

    func testScoreExposesRegionsAndWorstLimbTogether() {
        var p = standing.points
        let elbow = p[.leftElbow]!
        let wrist = p[.leftWrist]!
        p[.leftWrist] = elbow - (wrist - elbow)
        let live = PoseVector(points: p)

        let score = PoseScorer.score(reference: standing, live: live)
        XCTAssertNotNil(score)
        XCTAssertEqual(score?.worstBone, .leftForearm)
        XCTAssertEqual(score?.worstLimb ?? 1, 0.0, accuracy: 1e-5)
        XCTAssertEqual(score?.offRegions, [.leftArm])
        XCTAssertEqual(score?.regions[.leftArm] ?? 1, 0.0, accuracy: 1e-5)
    }

    /// The view model previously recomputed the worst limb with a second full
    /// pass over every bone. `PoseScore.worstLimb` must agree with that pass
    /// exactly, so the duplicate work can be deleted without changing behaviour.
    func testWorstLimbMatchesASeparateWorstBonePass() {
        var p = standing.points
        let knee = p[.rightKnee]!
        let ankle = p[.rightAnkle]!
        p[.rightAnkle] = knee + SIMD2<Float>(-(ankle - knee).y, (ankle - knee).x)
        let live = PoseVector(points: p)

        let score = PoseScorer.score(reference: standing, live: live)
        let separate = LimbSimilarity.worstBone(reference: standing, live: live)
        XCTAssertEqual(score?.worstLimb ?? -1, separate?.score ?? -2, accuracy: 1e-6)
    }
}
