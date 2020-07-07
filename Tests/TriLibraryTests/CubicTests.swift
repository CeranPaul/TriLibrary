//
//  CubicTests.swift
//  SketchCurves
//
//  Created by Paul on 7/16/16.
//  Copyright © 2018 Ceran Digital Media. All rights reserved.  See LICENSE.md
//

import XCTest
@testable import TriLibrary

class CubicTests: XCTestCase {

    var cup: Cubic?
    
    override func setUp() {
        super.setUp()
        
        let alpha = Point3D(x: 2.3, y: 1.5, z: 0.7)
        let alSlope = Vector3D(i: 0.866, j: 0.5, k: 0.0)
        
        let beta = Point3D(x: 3.1, y: 1.6, z: 0.7)
        let betSlope = Vector3D(i: 0.866, j: -0.5, k: 0.0)
        
        cup = try! Cubic(ptA: alpha, slopeA: alSlope, ptB: beta, slopeB: betSlope)
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testHermite() {
        
        let alpha = Point3D(x: 2.3, y: 1.5, z: 0.7)
        let alSlope = Vector3D(i: 0.866, j: 0.5, k: 0.0)
        
        let beta = Point3D(x: 3.1, y: 1.6, z: 0.7)
        let betSlope = Vector3D(i: 0.866, j: -0.5, k: 0.0)
        
        let bump = try! Cubic(ptA: alpha, slopeA: alSlope, ptB: beta, slopeB: betSlope)
        
        let oneTrial = try! bump.pointAt(t: 0.0)
        
           // Gee, this would be a grand place for an extension of XCTAssert that compares points
        let flag1 = Point3D.dist(pt1: oneTrial, pt2: alpha) < (Point3D.Epsilon / 3.0)
        
        XCTAssert(flag1)
        
        let otherTrial = try! bump.pointAt(t: 1.0)
        let flag2 = Point3D.dist(pt1: otherTrial, pt2: beta) < (Point3D.Epsilon / 3.0)
        
        XCTAssert(flag2)
        
        let badSlope = Vector3D(i: 0.0, j: 0.0, k: 0.0)
        
        XCTAssertThrowsError(try Cubic(ptA: alpha, slopeA: badSlope, ptB: beta, slopeB: betSlope))
        XCTAssertThrowsError(try Cubic(ptA: alpha, slopeA: alSlope, ptB: beta, slopeB: badSlope))

    }

    func testBezier()   {
        
        let alpha = Point3D(x: 2.3, y: 1.5, z: 0.7)
        let alSlope = Vector3D(i: 0.866, j: 0.5, k: 0.0)
        
        let control1 = Point3D.offset(pip: alpha, jump: alSlope)
        
        let beta = Point3D(x: 3.1, y: 1.6, z: 0.7)
        let betSlope = Vector3D(i: 0.866, j: -0.5, k: 0.0)
        let bReverse = betSlope.reverse()
        let control2 = Point3D.offset(pip: beta, jump: bReverse)
        
        let bump = try! Cubic(ptA: alpha, controlA: control1, controlB: control2, ptB: beta)
        
        let oneTrial = try! bump.pointAt(t: 0.0)
        
        // Gee, this would be a grand place for an extension of XCTAssert that compares points
        let flag1 = Point3D.dist(pt1: oneTrial, pt2: alpha) < (Point3D.Epsilon / 3.0)
        
        XCTAssert(flag1)
        
        let otherTrial = try! bump.pointAt(t: 1.0)
        let flag2 = Point3D.dist(pt1: otherTrial, pt2: beta) < (Point3D.Epsilon / 3.0)
        
        XCTAssert(flag2)
        
    }
    
    func testGetters()   {
        
        let alpha = Point3D(x: 2.3, y: 1.5, z: 0.7)
        let alSlope = Vector3D(i: 0.866, j: 0.5, k: 0.0)
        
        let control1 = Point3D.offset(pip: alpha, jump: alSlope)
        
        let beta = Point3D(x: 3.1, y: 1.6, z: 0.7)
        let betSlope = Vector3D(i: 0.866, j: -0.5, k: 0.0)
        let bReverse = betSlope.reverse()
        let control2 = Point3D.offset(pip: beta, jump: bReverse)
        
        let bump = try! Cubic(ptA: alpha, controlA: control1, controlB: control2, ptB: beta)
        
        
        let retAlpha = bump.getOneEnd()
        XCTAssertEqual(alpha, retAlpha)
        
        let retBeta = bump.getOtherEnd()
        XCTAssertEqual(beta, retBeta)
        
    }
    
    func testPointAt()   {
        
        let spot = try! cup?.pointAt(t: 0.5)
        
        let targetPt = Point3D(x: 2.7, y: 1.675, z: 0.7)
        
        XCTAssert(spot == targetPt)
                
        do   {
            _ = try cup?.pointAt(t: 1.7)
        } catch let screwup as ParameterRangeError {   // A contrived way to exercise the computed property
            _ = screwup.description
            XCTAssert(true)
        } catch {
            XCTFail()
        }
        
    }

    func testTangentAt()   {
        
        let dir = try! cup?.tangentAt(t: 0.4)
        
        let targetDir = Vector3D(i: 0.7709, j: 0.2440, k: 0.0)
        
        XCTAssert(dir == targetDir)
        
        do   {
            _ = try cup?.tangentAt(t: -2.7)
        } catch is ParameterRangeError   {
            
            XCTAssert(true)
        } catch   {
            XCTFail()
        }
        
    }
    
    func testSetIntent()   {
        
        XCTAssert(cup!.usage == "Ordinary")
        
        cup!.setIntent(purpose: "Selected")
        XCTAssert(cup!.usage == "Selected")
        
    }
    

    func testSumsHermite()   {
        
        let alpha = Point3D(x: 2.3, y: 1.5, z: 0.7)
        let alSlope = Vector3D(i: 0.866, j: 0.5, k: 0.0)
        
        let beta = Point3D(x: 3.1, y: 1.6, z: 0.7)
        let betSlope = Vector3D(i: 0.866, j: -0.5, k: 0.0)
        
        let bump = try! Cubic(ptA: alpha, slopeA: alSlope, ptB: beta, slopeB: betSlope)
        
        let sumX = bump.ax + bump.bx + bump.cx + bump.dx
        let sumY = bump.ay + bump.by + bump.cy + bump.dy
        let sumZ = bump.az + bump.bz + bump.cz + bump.dz
        
        XCTAssertEqual(beta.x, sumX, accuracy: 0.0001)
        XCTAssertEqual(beta.y, sumY, accuracy: 0.0001)
        XCTAssertEqual(beta.z, sumZ, accuracy: 0.0001)
    }
    
    func testSumsBezier()   {
        
        let alpha = Point3D(x: 2.3, y: 1.5, z: 0.7)
        let alSlope = Vector3D(i: 0.866, j: 0.5, k: 0.0)
        
        let control1 = Point3D.offset(pip: alpha, jump: alSlope)
        
        let beta = Point3D(x: 3.1, y: 1.6, z: 0.7)
        let betSlope = Vector3D(i: 0.866, j: -0.5, k: 0.0)
        let bReverse = betSlope.reverse()
        let control2 = Point3D.offset(pip: beta, jump: bReverse)
        
        let bump = try! Cubic(ptA: alpha, controlA: control1, controlB: control2, ptB: beta)
        
        let sumX = bump.ax + bump.bx + bump.cx + bump.dx
        let sumY = bump.ay + bump.by + bump.cy + bump.dy
        let sumZ = bump.az + bump.bz + bump.cz + bump.dz
        
        XCTAssertEqual(beta.x, sumX, accuracy: 0.0001)
        XCTAssertEqual(beta.y, sumY, accuracy: 0.0001)
        XCTAssertEqual(beta.z, sumZ, accuracy: 0.0001)
    }
    
    func testTransform100()   {
        
        let pt1 = Point3D(x: 2.0, y: 0.5, z: 4.0)
        let pt2 = Point3D(x: 2.0, y: 1.0, z: 2.0)
        let pt2Fraction = 0.38
        let pt3 = Point3D(x: 2.0, y: 2.0, z: 0.75)
        let pt3Fraction = 0.72
        let pt4 = Point3D(x: 2.0, y: 3.5, z: 0.5)
        
        let waist = try! Cubic(alpha: pt1, beta: pt2, betaFraction: pt2Fraction, gamma: pt3, gammaFraction: pt3Fraction, delta: pt4)

        let nose = waist.dice()
        
           // Try out the transform function of a Cubic
        let swing = Transform(rotationAxis: Axis.z, angleRad: Double.pi / 3.0)

        let hokie = waist.transform(xirtam: swing) as! Cubic

        let pokie = hokie.dice()
        
        var diff = [Double]()
        
        for g in 0..<pokie.count   {
            let erocks = nose[g].transform(xirtam: swing)
            let delta = Point3D.dist(pt1: pokie[g], pt2: erocks)
            diff.append(delta)
        }

        let whitney = diff.max()!
        XCTAssert(whitney < Point3D.Epsilon)
        
    }
    
    func testReverse()   {
        
        let pt1 = Point3D(x: 2.0, y: 0.5, z: 4.0)
        let pt2 = Point3D(x: 2.0, y: 1.0, z: 2.0)
        let pt2Fraction = 0.38
        let pt3 = Point3D(x: 2.0, y: 2.0, z: 0.75)
        let pt3Fraction = 0.72
        let pt4 = Point3D(x: 2.0, y: 3.5, z: 0.5)
        
        var waist = try! Cubic(alpha: pt1, beta: pt2, betaFraction: pt2Fraction, gamma: pt3, gammaFraction: pt3Fraction, delta: pt4)

        let nose = waist.dice()
        
        waist.reverse()
        
        let tail = waist.dice()
        let backwards = [Point3D](tail.reversed())
        
        var diff = [Double]()
        
        for g in 0..<backwards.count   {
            let delta = Point3D.dist(pt1: nose[g], pt2: backwards[g])   // Will always be positive
            diff.append(delta)
        }
        
        let acme = diff.max()!
        
        XCTAssert(acme < Point3D.Epsilon)
        
    }
    
    func testExtent()   {
        
        let alpha = Point3D(x: -2.3, y: 1.5, z: 0.7)
        
        let control1 = Point3D(x: -3.1, y: 0.0, z: 0.7)
        
        let control2 = Point3D(x: -3.1, y: -1.6, z: 0.7)
        
        let beta = Point3D(x: -2.7, y: -3.4, z: 0.7)
        
        let bump = try! Cubic(ptA: alpha, controlA: control1, controlB: control2, ptB: beta)
        
        
        let box = bump.getExtent()
        
        XCTAssertEqual(box.getOrigin().x, -2.9624, accuracy: 0.0001)
    }
    
    func testFindCrown()   {
        
        let hump =  try! cup!.findCrown(smallerT: 0.20, largerT: 0.85)
        
        XCTAssertEqual(hump, 0.0543, accuracy: 0.0001)
    }
    
    func testCrossing()   {
        
        let pt1 = Point3D(x: -1.2, y: 0.39, z: 0.0)
        let pt2 = Point3D(x: 1.1, y: 1.05, z: 0.0)
        let pt3 = Point3D(x: 1.95, y: -0.5, z: 0.0)
        let pt4 = Point3D(x: 3.64, y: 0.04, z: 0.0)

        let rolling = try! Cubic(alpha: pt1, beta: pt2, betaFraction: 0.45, gamma: pt3, gammaFraction: 0.65, delta: pt4)
        
        let kansas = Vector3D(i: 1.0, j: 0.0, k: 0.0)

        /// Origin for a high line that misses.
        let mama = Point3D(x: -2.2, y: 3.0, z: 0.0)
        let tooHigh = try! Line(spot: mama, arrow: kansas)
        
        let chubby = Point3D(x: -1.8, y: 1.75, z: 0.0)
        let high = try! Line(spot: chubby, arrow: kansas)
        
        let everett = Point3D(x: -1.9, y: 0.25, z: 0.0)
        let low = try! Line(spot: everett, arrow: kansas)
        
        let cody = Point3D(x: -1.45, y: -1.78, z: 0.0)
        let tooLow = try! Line(spot: cody, arrow: kansas)
        
        let wholeCurve = ClosedRange<Double>(uncheckedBounds: (lower: 0.0, upper: 1.0))
        
        let collide2High = rolling.crossing(ray: tooHigh, span: wholeCurve, chunks: 100)
        XCTAssertEqual(0, collide2High.count)

        let collideHigh = rolling.crossing(ray: high, span: wholeCurve, chunks: 100)
        XCTAssertEqual(2, collideHigh.count)

        let collideLow = rolling.crossing(ray: low, span: wholeCurve, chunks: 100)
        XCTAssertEqual(1,  collideLow.count)
        
        let collide2Low = rolling.crossing(ray: tooLow, span: wholeCurve, chunks: 100)
        XCTAssertEqual(0, collide2Low.count)

    }
    
    func testIntersect()   {
        
        let pt1 = Point3D(x: -1.2, y: 0.39, z: 0.0)
        let pt2 = Point3D(x: 1.1, y: 1.05, z: 0.0)
        let pt3 = Point3D(x: 1.95, y: -0.5, z: 0.0)
        let pt4 = Point3D(x: 3.64, y: 0.04, z: 0.0)

        let rolling = try! Cubic(alpha: pt1, beta: pt2, betaFraction: 0.45, gamma: pt3, gammaFraction: 0.65, delta: pt4)
        
        let kansas = Vector3D(i: 1.0, j: 0.0, k: 0.0)

        let chubby = Point3D(x: -1.8, y: 1.75, z: 0.0)
        let high = try! Line(spot: chubby, arrow: kansas)
        
        let whacks = try! rolling.intersect(ray: high, accuracy: 0.001)
        XCTAssertEqual(2, whacks.count)

    }
    
    func testRefine()   {
        
        let near = Point3D(x: 2.9, y: 1.4, z: 0.7)
        
        let startRange = ClosedRange<Double>(uncheckedBounds: (lower: 0.0, upper: 1.0))
        
        let narrower = try! cup!.refineRangeDist(nearby: near, span: startRange)
        
        XCTAssert(narrower?.lowerBound == 0.8)
        XCTAssert(narrower?.upperBound == 1.0)
        
        let narrower3 = try! cup!.refineRangeDist(nearby: near, span: narrower!)
        
        XCTAssert(narrower3?.lowerBound == 0.86)
        XCTAssert(narrower3?.upperBound == 0.90)
        

        let near2 = Point3D(x: 2.65, y: 1.45, z: 0.7)
        
        let narrower2 = try! cup!.refineRangeDist(nearby: near2, span: startRange)
        
        XCTAssert(narrower2?.lowerBound == 0.2)
        XCTAssert(narrower2?.upperBound == 0.4)
        

        let near3 = Point3D(x: 2.40, y: 1.45, z: 0.7)
        
        let narrower4 = try! cup!.refineRangeDist(nearby: near3, span: startRange)
        
        XCTAssert(narrower4?.lowerBound == 0.0)
        XCTAssert(narrower4?.upperBound == 0.2)
                
    }
    
    
    func testFindClosest()   {
        
        let near = Point3D(x: 2.9, y: 1.4, z: 0.7)
        
        let buddy = try! cup!.findClosest(nearby: near).pip
        
        let target = Point3D(x: 2.99392, y: 1.65063, z: 0.70000)
        
        XCTAssertEqual(buddy, target)
        
        do   {
            _ = try cup!.findClosest(nearby: near, accuracy: -0.001)
        } catch let screwup as NegativeAccuracyError {
            _ = screwup.description
            XCTAssert(true)
        } catch {
            XCTFail()
        }
    }
        
}
