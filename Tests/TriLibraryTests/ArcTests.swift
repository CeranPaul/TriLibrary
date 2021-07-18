//
//  ArcTests.swift
//  SketchCurves
//
//  Created by Paul on 11/12/15.
//  Copyright © 2021 Ceran Digital Media. All rights reserved.  See LICENSE.md
//

import XCTest
@testable import TriLibrary

class ArcTests: XCTestCase {

    /// Tests the simple parts for one of the inits
    func testFidelityThreePoints() {

        let sun = Point3D(x: 3.5, y: 6.0, z: 0.0)
        let earth = Point3D(x: 5.5, y: 6.0, z: 0.0)
        let atlantis = Point3D(x: 3.5, y: 8.0, z: 0.0)
        
        
        var orbit = try! Arc(center: sun, end1: earth, end2: atlantis, useSmallAngle: false)
        
        XCTAssert(orbit.getCenter() == sun)
        XCTAssert(orbit.getOneEnd() == earth)
        XCTAssert(orbit.getOtherEnd() == atlantis)
        
        
        XCTAssertEqual(orbit.getSweepAngle(), 3.0 * Double.pi / -2.0, accuracy: 0.0001)
        
        var target = 2.0
        XCTAssertEqual(orbit.getRadius(), target, accuracy: 0.0001)
        
        orbit = try! Arc(center: sun, end1: earth, end2: atlantis, useSmallAngle: true)
        
        XCTAssertEqual(orbit.getSweepAngle(), Double.pi / 2.0, accuracy: 0.0001)

        
        
           // Detect an ArcPointsError from duplicate points by bad referencing
        do   {
            let ctr = Point3D(x: 2.0, y: 1.0, z: 5.0)
    //        let e1 = Point3D(x: 3.0, y: 1.0, z: 5.0)
            let e2 = Point3D(x: 2.0, y: 2.0, z: 5.0)
            
            // Bad referencing should cause an error to be thrown
            let _ = try Arc(center: ctr, end1: e2, end2: ctr, useSmallAngle: false)
            
        }   catch is ArcPointsError   {
            XCTAssert(true)
        }   catch   {   // This code will never get run
            XCTAssert(false)
        }
        
           // Detect non-equidistant points
        do   {
            let ctr = Point3D(x: 2.0, y: 1.0, z: 5.0)
            let e1 = Point3D(x: 3.0, y: 1.0, z: 5.0)
            let e2 = Point3D(x: 2.0, y: 2.5, z: 5.0)
            
            // Bad point separation should cause an error to be thrown
            let _ = try Arc(center: ctr, end1: e1, end2: e2, useSmallAngle: false)
            
        }   catch is ArcPointsError   {
            XCTAssert(true)
        }   catch   {   // This code will never get run
            XCTAssert(false)
        }
        
           // Detect collinear points
        do   {
            let ctr = Point3D(x: 2.0, y: 1.0, z: 5.0)
            let e1 = Point3D(x: 3.0, y: 1.0, z: 5.0)
            let e2 = Point3D(x: 1.0, y: 1.0, z: 5.0)
            
            // Points all on a line should cause an error to be thrown
            let _ = try Arc(center: ctr, end1: e1, end2: e2, useSmallAngle: false)
            
        }   catch is CoincidentPointsError   {
            XCTAssert(true)
        }   catch   {   // This code will never get run
            XCTAssert(false)
        }
        
        
            // Check that sweep angles get generated correctly
        
        /// Convenient values
        let sqrt22 = sqrt(2.0) / 2.0
        let sqrt32 = sqrt(3.0) / 2.0
        
        
        let earth44 = Point3D(x: 3.5 + 2.0 * sqrt32, y: 6.0 + 2.0 * 0.5, z: 0.0)
        
        // High to high
        let season = try! Arc(center: sun, end1: earth44, end2: atlantis, useSmallAngle: true)
        
        target = 1.0 * Double.pi / 3.0
        let theta = season.getSweepAngle()
        
        XCTAssertEqual(theta, target, accuracy: 0.001)
        
        
        // High to high complement
        let season3 = try! Arc(center: sun, end1: earth44, end2: atlantis, useSmallAngle: false)
        
        let target3 = -1.0 * (2.0 * Double.pi - target)
        let theta3 = season3.getSweepAngle()
        
        XCTAssertEqual(theta3, target3, accuracy: 0.001)
        
        // Low to high
        let earth2 = Point3D(x: 3.5 + 2.0 * sqrt32, y: 6.0 - 2.0 * 0.5, z: 0.0)
        
        let season2 = try! Arc(center: sun, end1: earth2, end2: atlantis, useSmallAngle: true)
        
        let target2 = 2.0 * Double.pi / 3.0
        let theta2 = season2.getSweepAngle()
        
        XCTAssertEqual(theta2, target2, accuracy: 0.001)
        
        // Low to high complement
        let season4 = try! Arc(center: sun, end1: earth2, end2: atlantis, useSmallAngle: false)
        
        let target4 = -1.0 * (2.0 * Double.pi - target2)
        let theta4 = season4.getSweepAngle()
        
        XCTAssertEqual(theta4, target4, accuracy: 0.001)
        
        
        // High to low
        let earth3 = Point3D(x: 3.5 + 2.0 * sqrt32, y: 6.0 + 2.0 * 0.5, z: 0.0)
        
        let atlantis5 = Point3D(x: 3.5 - 2.0 * sqrt22, y: 6.0 - 2.0 * sqrt22, z: 0.0)
        
        let season5 = try! Arc(center: sun, end1: earth3, end2: atlantis5, useSmallAngle: false)
        
        let target5 = -13.0 * Double.pi / 12.0
        let theta5 = season5.getSweepAngle()
        
        XCTAssertEqual(theta5, target5, accuracy: 0.001)
        
        // High to low complement
        let season6 = try! Arc(center: sun, end1: earth3, end2: atlantis5, useSmallAngle: true)
        
        let target6 = 11.0 * Double.pi / 12.0
        let theta6 = season6.getSweepAngle()
        
        XCTAssertEqual(theta6, target6, accuracy: 0.001)
        
        
        // Low to low
        let season7 = try! Arc(center: sun, end1: earth2, end2: atlantis5, useSmallAngle: false)
        
        let target7 = -17.0 * Double.pi / 12.0
        let theta7 = season7.getSweepAngle()
        
        XCTAssertEqual(theta7, target7, accuracy: 0.001)
        
        let season8 = try! Arc(center: sun, end1: earth2, end2: atlantis5, useSmallAngle: true)
        
        // Low to low complement
        let target8 = 7.0 * Double.pi / 12.0
        let theta8 = season8.getSweepAngle()
        
        XCTAssertEqual(theta8, target8, accuracy: 0.001)
        
        
           // Check generation of the axis
        let c1 = Point3D(x: 0.9, y: -1.21, z: 3.5)
        let s1 = Point3D(x: 0.9, y: -1.21 + sqrt32, z: 3.5 + 0.5)
        let f1 = Point3D(x: 0.9, y: -1.21, z: 3.5 + 1.0)
        
        let slice = try! Arc(center: c1, end1: s1, end2: f1, useSmallAngle: false)
        
        let target9 = Vector3D(i: 1.0, j: 0.0, k: 0.0)
        
        let trial = slice.getAxisDir()
        
        XCTAssertEqual(trial, target9)

    }

    
    /// Has some duplication with testFidelityThreePoints
    func testInitCEE()   {
        
        let ctr = Point3D(x: 1.5, y: 4.0, z: 3.5)
        let alpha = Point3D(x: 1.5, y: 6.0, z: 3.5)
        let omega = Point3D(x: 1.5, y: 4.0, z: 5.5)
        
        let fourth = try! Arc(center: ctr, end1: alpha, end2: omega, useSmallAngle: true)
        
        XCTAssertEqual(fourth.getRadius(), 2.0, accuracy: 0.00001)
        
        let spinX = Vector3D(i: 1.0, j: 0.0, k: 0.0)
        let spinY = Vector3D(i: 0.0, j: 1.0, k: 0.0)
        
        XCTAssertFalse(fourth.getAxisDir() == spinY)
        
        XCTAssert(fourth.getAxisDir() == spinX)
        
        XCTAssertEqual(Double.pi / 2.0, fourth.getSweepAngle(), accuracy: 0.0001)
        
        let htgnel = 2.0 * Double.pi * fourth.getRadius() / 4.0
        XCTAssertEqual(fourth.getLength(), htgnel, accuracy: 0.001)
        
    }
    

    /// Test the second initializer
    func testFidelityCASS()   {
        
        let sun = Point3D(x: 3.5, y: 6.0, z: 0.0)
        let earth = Point3D(x: 5.5, y: 6.0, z: 0.0)
        let solarSystemUp = Vector3D(i: 0.0, j: 0.0, k: 1.0)
        let fourMonths = 2.0 * Double.pi / 3.0
        
        
        var orbit = try! Arc(ctr: sun, axis: solarSystemUp, start: earth, sweep: fourMonths)
        
        var target = 2.0
        
        XCTAssertEqual(orbit.getRadius(), target, accuracy: 0.0001)
        
        
        /// A handy value when checking points at angles
        let sqrt32 = sqrt(3.0) / 2.0
        
        target = 3.5 - 2.0 * 0.5
        XCTAssertEqual(orbit.getOtherEnd().x, target, accuracy: Point3D.Epsilon)
        
        target = 6.0 + 2.0 * sqrt32
        XCTAssertEqual(orbit.getOtherEnd().y, target, accuracy: Point3D.Epsilon)
        
        
        orbit = try! Arc(ctr: sun, axis: solarSystemUp, start: earth, sweep: 2.0 * Double.pi)
        
        
        do   {
            let solarSystemUp2 = Vector3D(i: 0.0, j: 0.0, k: 0.0)

            orbit = try Arc(ctr: sun, axis: solarSystemUp2, start: earth, sweep: 2.0 * Double.pi)
            
        }   catch is NonUnitDirectionError   {
            
            XCTAssert(true)
            
        }   catch   {
            
            XCTAssert(false, "Code should never have gotten here")
        }

        do   {
            let solarSystemUp2 = Vector3D(i: 0.0, j: 0.0, k: 0.5)
            
            orbit = try Arc(ctr: sun, axis: solarSystemUp2, start: earth, sweep: 2.0 * Double.pi)
            
        }   catch is NonUnitDirectionError   {
            
            XCTAssert(true)
            
        }   catch   {
            
            XCTAssert(false, "Code should never have gotten here")
        }

        
        
        do   {
            
            orbit = try Arc(ctr: sun, axis: solarSystemUp, start: earth, sweep: 0.0)
            
        }   catch is ZeroSweepError   {
            
            XCTAssert(true)
            
        }   catch   {
            
            XCTAssert(false, "Code should never have gotten here")
        }
        
        do   {
            let earth2 = Point3D(x: 3.5, y: 6.0, z: 4.0)
            
            orbit = try Arc(ctr: sun, axis: solarSystemUp, start: earth2, sweep: 2.0 * Double.pi)
            
        }   catch is NonOrthogonalPointError   {
            
            XCTAssert(true)
            
        }   catch   {
            
            XCTAssert(false, "Code should never have gotten here")
        }
        
        

    }
    
    
    func testPointAt()   {
        
        let thumb = Point3D(x: 3.5, y: 6.0, z: 0.0)
        let knuckle = Point3D(x: 5.5, y: 6.0, z: 0.0)
        let tip = Point3D(x: 3.5, y: 8.0, z: 0.0)
        
        do   {
            let grip = try Arc(center: thumb, end1: knuckle, end2: tip, useSmallAngle: true)
            
            var spot = try! grip.pointAt(t: 0.5)
            
            XCTAssert(spot.z == 0.0)
            XCTAssert(spot.y == 6.0 + 2.squareRoot())   // This is bizarre notation, probably from a language level comparison.
            XCTAssert(spot.x == 3.5 + 2.squareRoot())
            
            spot = try! grip.pointAt(t: 0.0)
            
            XCTAssert(spot.z == 0.0)
            XCTAssert(spot.y == 6.0)
            XCTAssert(spot.x == 3.5 + 2.0)
            
        }  catch  {
            print("Screwed up while testing a circle 7")
        }
        
        
           // Another start-at-zero case with a different check method
        let ctr = Point3D(x: 10.5, y: 6.0, z: -1.2)
        
        /// On the horizon
        let green = Point3D(x: 11.8, y: 6.0, z: -1.2)
        
        /// Noon sun
        let checker = Point3D(x: 10.5, y: 7.3, z: -1.2)
        
        let shoulder = try! Arc(center: ctr, end1: green, end2: checker, useSmallAngle: true)
        
        
        var upRight = Vector3D(i: 1.0, j: 1.0, k: 0.0)
        upRight.normalize()
        
        /// Unit slope
        let ray = try! Line(spot: ctr, arrow: upRight)
        
        
        var plop = try! shoulder.pointAt(t: 0.5)
        
        let flag1 = Line.isCoincident(straightA: ray, pip: plop)
        
        XCTAssert(flag1)
        
        
        
           // Clockwise sweep
        let sunSetting = try! Arc(center: ctr, end1: checker, end2: green, useSmallAngle: true)
        
        var clock = Vector3D(i: 0.866, j: 0.5, k: 0.0)
        clock.normalize()
        
        let ray2 = try! Line(spot: ctr, arrow: clock)
        
        plop = try! sunSetting.pointAt(t: 0.666667)
        
        XCTAssert(Line.isCoincident(straightA: ray2, pip: plop))
        
        // TODO: Add tests in a non-XY plane

        
        
        let sunSetting2 = try! Arc(center: ctr, end1: checker, end2: green, useSmallAngle: false)
        
        
        var clock2 = Vector3D(i: 0.0, j: -1.0, k: 0.0)
        clock2.normalize()
        
        var ray3 = try! Line(spot: ctr, arrow: clock2)
        
        plop = try! sunSetting2.pointAt(t: 0.666667)
        XCTAssert(Line.isCoincident(straightA: ray3, pip: plop))
        
        
        let countdown = try! Arc(center: ctr, end1: checker, end2: green, useSmallAngle: false)
        
        clock = Vector3D(i: -1.0, j: 0.0, k: 0.0)
        ray3 = try! Line(spot: ctr, arrow: clock)
        
        plop = try! countdown.pointAt(t: 0.333333)
        XCTAssert(Line.isCoincident(straightA: ray3, pip: plop))
        
    }
    
    func testApproximate()   {
        
        let up = Vector3D(i: 0.0, j: 0.0, k: 1.0)
        let pivot = Point3D(x: 2.0, y: 1.0, z: 0.0)
        let adam = Point3D(x: 3.5, y: 1.0, z: 0.0)
        
        let rainbow = try! Arc(ctr: pivot, axis: up, start: adam, sweep: Double.pi / 2.0)
        
        let hops = try! rainbow.approximate(allowableCrown: 0.001)
        XCTAssert(Point3D.isUniquePool(flock: hops))
        
        XCTAssertNoThrow(try rainbow.approximate(allowableCrown: 0.001))
        XCTAssertThrowsError(try rainbow.approximate(allowableCrown: -0.05))

    }
    
    func testGetExtent()   {
        
        let up = Vector3D(i: 0.0, j: 0.0, k: 1.0)
        let pivot = Point3D(x: 2.0, y: 1.0, z: 0.0)
        let adam = Point3D(x: 3.5, y: 1.0, z: 0.0)
        
        let rainbow = try! Arc(ctr: pivot, axis: up, start: adam, sweep: Double.pi * 2.0)
        
        let brick = rainbow.getExtent()
        print(brick.getOrigin())
        
        let minCorner = Point3D(x: 0.45, y: -0.55, z: -0.05)
        let maxCorner = Point3D(x: 3.55, y: 2.55, z: 0.05)
        let target = try! OrthoVol(corner1: minCorner, corner2: maxCorner)
        
        XCTAssert(OrthoVol.surrounds(big: target, little: rainbow.getExtent()))
    }
    
    
    func testIntersect()   {
        
        let up = Vector3D(i: 0.0, j: 0.0, k: 1.0)
        let pivot = Point3D(x: 2.0, y: 1.0, z: 0.0)
        let adam = Point3D(x: 3.5, y: 1.0, z: 0.0)
        
        let rainbow = try! Arc(ctr: pivot, axis: up, start: adam, sweep: Double.pi / -0.65)
        
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
        
        
        let whack2high = try! rainbow.intersect(ray: tooHigh, accuracy: 0.001)
        XCTAssertEqual(0, whack2high.count)
        
        let whackhigh = try! rainbow.intersect(ray: high, accuracy: 0.001)
        XCTAssertEqual(1, whackhigh.count)
        
        let whacklow = try! rainbow.intersect(ray: low, accuracy: 0.001)
        XCTAssertEqual(2, whacklow.count)
        
        let whack2low = try! rainbow.intersect(ray: tooLow, accuracy: 0.001)
        XCTAssertEqual(0, whack2low.count)
        
    }
    
//    func testReverse()   {
//
//        let ctr = Point3D(x: 10.5, y: 6.0, z: -1.2)
//
//        let green = Point3D(x: 11.8, y: 6.0, z: -1.2)
//        let checker = Point3D(x: 10.5, y: 7.3, z: -1.2)
//
//        /// One quarter of a full circle - in quadrant I
//        let shoulder = try! Arc(center: ctr, end1: green, end2: checker, useSmallAngle: true)
//
//        XCTAssertEqual(Double.pi / 2.0, shoulder.getSweepAngle())
//
//        var clock1 = Vector3D(i: 0.5, j: 0.866, k: 0.0)
//        clock1.normalize()
//
//        let ray1 = try! Line(spot: ctr, arrow: clock1)
//
//        var plop = try! shoulder.pointAt(t: 0.666667)
//
//        XCTAssert(Line.isCoincident(straightA: ray1, pip: plop))
//
//
//        shoulder.reverse()
//
//        var clock2 = Vector3D(i: 0.866, j: 0.5, k: 0.0)
//        clock2.normalize()
//
//        let ray2 = try! Line(spot: ctr, arrow: clock2)
//
//        plop = try! shoulder.pointAt(t: 0.666667)
//
//        XCTAssert(Line.isCoincident(straightA: ray2, pip: plop))
//    }
    
    
    func testConcentric()   {
        
        let ctr = Point3D(x: 1.0, y: 1.0, z: 2.0)
        let start = Point3D(x: 1.5, y: 1.0, z: 2.0)
        let zee = Vector3D(i: 0.0, j: 0.0, k: 1.0)
        
        let cup = try! Arc(ctr: ctr, axis: zee, start: start, sweep: Double.pi / 2.0)
        
        let jug = try! Arc.concentric(alpha: cup, delta: 0.3)
        
        XCTAssertEqual(jug.getRadius(), 0.80, accuracy: 0.00001)
        
        let straw = try! Arc.concentric(alpha: cup, delta: -0.3)
        
        XCTAssertEqual(straw.getRadius(), 0.20, accuracy: 0.00001)
        
        XCTAssertThrowsError( try Arc.concentric(alpha: cup, delta: -0.6) )
        
        XCTAssertThrowsError( try Arc.concentric(alpha: cup, delta: -0.5) )
        
    }
    
    func testGetLength()   {
        
        let ctr = Point3D(x: 1.0, y: 1.0, z: 2.0)
        let start = Point3D(x: 1.5, y: 1.0, z: 2.0)
        let zee = Vector3D(i: 0.0, j: 0.0, k: 1.0)
        
        let cup = try! Arc(ctr: ctr, axis: zee, start: start, sweep: Double.pi / 2.0)
        
        let target = Double.pi / 2.0 * 0.5
        XCTAssertEqual(cup.getLength(), target, accuracy: 0.00001)
    }
    
    func testReverse()   {
        
        let ctr = Point3D(x: 1.0, y: 1.0, z: 2.0)
        let start = Point3D(x: 1.5, y: 1.0, z: 2.0)
        let zee = Vector3D(i: 0.0, j: 0.0, k: 1.0)
        
        var cup = try! Arc(ctr: ctr, axis: zee, start: start, sweep: Double.pi / 2.0)
        
        let lengthA = cup.getLength()
        
        let alphaA = cup.getOneEnd()
        let omegaA = cup.getOtherEnd()
        
        cup.reverse()
        
        let lengthB = cup.getLength()
        
        XCTAssertEqual(lengthA, lengthB, accuracy: 0.00001)
        
        let alphaB = cup.getOneEnd()
        let omegaB = cup.getOtherEnd()
        
        XCTAssert(alphaB == omegaA)
        
        XCTAssert(omegaB == alphaA)
    }
    
    
    func testPerch()   {
        
        let sun = Point3D(x: 3.5, y: 6.0, z: 1.0)
        let earth = Point3D(x: 5.5, y: 6.0, z: 1.0)
        let atlantis = Point3D(x: 3.5, y: 6.0, z: 3.0)
        
        let solarSystem1 = try! Arc(center: sun, end1: earth, end2: atlantis, useSmallAngle: true)
        
           // Not on Arc
        let t1 = Point3D(x: 4.5, y: 6.0, z: 1.35)

        var sitRep = try! solarSystem1.isCoincident(speck: t1)
        XCTAssertFalse(sitRep.flag)

           // Far end
        let t2 = Point3D(x: 3.5, y: 6.0, z: 3.0)

        sitRep = try! solarSystem1.isCoincident(speck: t2)
        XCTAssert(sitRep.flag)

           // Right radius with good angle
        let t3 = Point3D(x: 3.5 + 2.0 * sqrt(2.0) / 2.0, y: 6.0, z: 1.0 + 2.0 * sqrt(2.0) / 2.0)
        
        sitRep = try! solarSystem1.isCoincident(speck: t3)
        XCTAssert(sitRep.flag)
        
           // Right radius with bad angle
        let solarSystem2 = try! Arc(center: sun, end1: earth, end2: atlantis, useSmallAngle: false)
        
        sitRep = try! solarSystem2.isCoincident(speck: t3)
        XCTAssertFalse(sitRep.flag)
        
           // Out of plane
        let t4 = Point3D(x: 3.5 + 2.0 * sqrt(2.0) / 2.0, y: 7.0, z: 1.0 + 2.0 * sqrt(2.0) / 2.0)
        
        sitRep = try! solarSystem1.isCoincident(speck: t4)
        XCTAssertFalse(sitRep.flag)
        
    }
    
    func testEquals() {
        
        let sun = Point3D(x: 3.5, y: 6.0, z: 0.0)
        let earth = Point3D(x: 5.5, y: 6.0, z: 0.0)
        let atlantis = Point3D(x: 3.5, y: 8.0, z: 0.0)
        
        let betelgeuse = Point3D(x: 3.5, y: 6.0, z: 0.0)
        let planetX = Point3D(x: 5.5, y: 6.0, z: 0.0)
        let planetY = Point3D(x: 3.5, y: 8.0, z: 0.0)
        
        let solarSystem1 = try! Arc(center: sun, end1: earth, end2: atlantis, useSmallAngle: false)
        
        let solarSystem2 = try! Arc(center: betelgeuse, end1: planetX, end2: planetY, useSmallAngle: false)
        
        XCTAssert(solarSystem1 == solarSystem2)
        
    }
    
    //TODO: Add tests to compare results from the different types of initializers

    func testSetIntent()   {
        
        let sun = Point3D(x: 3.5, y: 6.0, z: 0.0)
        let earth = Point3D(x: 5.5, y: 6.0, z: 0.0)
        let atlantis = Point3D(x: 3.5, y: 8.0, z: 0.0)
        
        var solarSystem1 = try! Arc(center: sun, end1: earth, end2: atlantis, useSmallAngle: false)
        

        XCTAssert(solarSystem1.usage == "Ordinary")
        
        solarSystem1.setIntent(purpose: "Selected")
        
        XCTAssert(solarSystem1.usage == "Selected")
        
    }
        
}
