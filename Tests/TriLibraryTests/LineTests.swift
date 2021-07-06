//
//  LineTests.swift
//  SketchGen
//
//  Created by Paul on 12/10/15.
//  Copyright © 2018 Ceran Digital Media. All rights reserved.  See LICENSE.md
//

import XCTest
@testable import TriLibrary

class LineTests: XCTestCase {

    /// Verify the fidelity of recording the inputs
    func testFidelity()  {
        
        let nexus = Point3D(x: -2.5, y: 1.5, z: 0.015)
        var horn = Vector3D(i: 12.0, j: 3.0, k: 4.0)
        horn.normalize()
        
        XCTAssertNoThrow( try Line(spot: nexus, arrow: horn) )
        
        let contrail = try! Line(spot: nexus, arrow: horn)   // The previous test verified that this is safe
        
        XCTAssert(contrail.getOrigin().x == -2.5)
        XCTAssert(contrail.getOrigin().y == 1.5)
        XCTAssert(contrail.getOrigin().z == 0.015)
        
        XCTAssert(contrail.getDirection().i == 12.0 / 13.0)
        XCTAssert(contrail.getDirection().j == 3.0 / 13.0)
        XCTAssert(contrail.getDirection().k == 4.0 / 13.0)
        
        
           // Check that one of the guard statements works
        do {
            
            horn = Vector3D(i: 0.0, j: 0.0, k: 0.0)
            
            _ = try Line(spot: nexus, arrow: horn)
            
        }  catch is ZeroVectorError {
            
            XCTAssert(true)
            
        }  catch  {   // I don't see how you avoid writing this code, and having it be untested
        
            XCTAssert(false)
        }
        
        
            // Check that the other guard statements works
        do {
            
            horn = Vector3D(i: 3.0, j: 2.0, k: 1.0)
            
            _ = try Line(spot: nexus, arrow: horn)
            
        }  catch is NonUnitDirectionError {
            
            XCTAssert(true)
            
        }  catch  {   // I don't see how you avoid writing this code, and having it be untested
            
            XCTAssert(false)
        }
        
    }
    
    func testDropPoint()   {
        
        let trailhead = Point3D(x: 4.0, y: 2.0, z: 1.0)
        var compass = Vector3D(i: 1.0, j: 1.0, k: 1.0)
        compass.normalize()
        
        var rocket = try! Line(spot: trailhead, arrow: compass)
        
        var incoming = Point3D(x: 6.0, y: 4.0, z: 3.0)
        var splat = rocket.dropPoint(away: incoming)
        
        XCTAssert(splat == incoming)
        
        
        compass = Vector3D(i: 1.0, j: 1.0, k: 0.0)
        compass.normalize()
        
        rocket = try! Line(spot: trailhead, arrow: compass)
        
        incoming = Point3D(x: 5.0, y: 3.0, z: 0.0)
        let target = Point3D(x: 5.0, y: 3.0, z: 1.0)
        
        splat = rocket.dropPoint(away: incoming)
        
        XCTAssert(splat == target)
        
    }
    
    /// For a line and a point
    func testIsCoincidentPoint()   {
        
        let flatOrig = Point3D(x: 1.0, y: 2.0, z: 3.0)
        var flatDir = Vector3D(i: 1.0, j: 1.0, k: 1.0)
        flatDir.normalize()
        
        let contrail = try! Line(spot: flatOrig, arrow: flatDir)
        
        let trialOff = Point3D(x: 1.0, y: 2.0, z: 4.0)
        
        XCTAssertFalse(Line.isCoincident(straightA: contrail, pip: trialOff))
        
        
        let trialOn = Point3D(x: 3.5, y: 4.5, z: 5.5)
        
        XCTAssert(Line.isCoincident(straightA: contrail, pip: trialOn))
        
        
        let trialCoin = Point3D(x: 1.0, y: 2.0, z: 3.0)
        
        XCTAssert(Line.isCoincident(straightA: contrail, pip: trialCoin))
        
    }
    
    
    func testIsCoincidentLine()   {
        
        let gOrig = Point3D(x: 5.0, y: 8.5, z: -1.25)
        var gDir = Vector3D(i: -1.0, j: -1.0, k: -1.0)
        gDir.normalize()
        
        let redstone = try! Line(spot: gOrig, arrow: gDir)
        
        let pOrig = Point3D(x: 3.0, y: 6.5, z: -3.25)
        var pDir = Vector3D(i: -1.0, j: -1.0, k: -1.0)
        pDir.normalize()
        
        let titan = try! Line(spot: pOrig, arrow: pDir)
        
        XCTAssert(Line.isCoincident(straightA: redstone, straightB: titan))
        
        
           // Not parallel
        pDir = Vector3D(i: -1.0, j: 1.0, k: 1.0)
        pDir.normalize()
        
        let atlas = try! Line(spot: pOrig, arrow: pDir)
        XCTAssertFalse(Line.isCoincident(straightA: redstone, straightB: atlas))

        
           // Parallel, but not lying over one another
        let pOrig2 = Point3D(x: 3.0, y: 6.5, z: -2.25)
        let titan2 = try! Line(spot: pOrig2, arrow: pDir)
        
        XCTAssertFalse(Line.isCoincident(straightA: redstone, straightB: titan2))
        
    }
    
    func testIsCoPlanar()   {
        
        let orig1 = Point3D(x: 10.5, y: 5.5, z: 1.0)
        let dir1 = Vector3D(i: 0.0, j: 0.0, k: 1.0)
        
        let arrow1 = try! Line(spot: orig1, arrow: dir1)
        
        let orig2 = Point3D(x: 6.2, y: 5.5, z: 3.0)
        let dir2 = Vector3D(i: 1.0, j: 0.0, k: 0.0)
        
        let arrow2 = try! Line(spot: orig2, arrow: dir2)
        
            // They have an intersection
        XCTAssert(Line.isCoplanar(straightA: arrow1, straightB: arrow2))
        
        
           // Coincident origin case
        let dir3 = Vector3D(i: 1.0, j: 0.0, k: 0.0)
        
        let arrow3 = try! Line(spot: orig1, arrow: dir3)
        
        XCTAssert(Line.isCoplanar(straightA: arrow1, straightB: arrow3))
        

           // Coincident case
        let gOrig = Point3D(x: 5.0, y: 8.5, z: -1.25)
        var gDir = Vector3D(i: -1.0, j: -1.0, k: -1.0)
        gDir.normalize()
        
        let redstone = try! Line(spot: gOrig, arrow: gDir)
        
        let pOrig = Point3D(x: 3.0, y: 6.5, z: -3.25)
        var pDir = Vector3D(i: -1.0, j: -1.0, k: -1.0)
        pDir.normalize()
        
        let titan = try! Line(spot: pOrig, arrow: pDir)
        
        XCTAssert(Line.isCoplanar(straightA: redstone, straightB: titan))
        
           // No intersection case
        let orig4 = Point3D(x: 10.5, y: 5.5, z: 1.0)
        let dir4 = Vector3D(i: 0.0, j: 0.0, k: 1.0)

        let arrow4 = try! Line(spot: orig4, arrow: dir4)

        let orig5 = Point3D(x: 6.2, y: 6.5, z: 3.0)
        let dir5 = Vector3D(i: 1.0, j: 0.0, k: 0.0)

        let arrow5 = try! Line(spot: orig5, arrow: dir5)

        XCTAssertFalse(Line.isCoplanar(straightA: arrow4, straightB: arrow5))

        
        let cOrig = Point3D(x: 4.0, y: 7.5, z: -2.75)
        var cDir = Vector3D(i: -1.0, j: -1.0, k: -1.0)
        cDir.normalize()
        
        let atlas = try! Line(spot: cOrig, arrow: cDir)

             // Parallel
        XCTAssert(Line.isCoplanar(straightA: redstone, straightB: atlas))
        
    }
    
    func testIsParallel()   {
        
        // Coincident case
        let gOrig = Point3D(x: 5.0, y: 8.5, z: -1.25)
        var gDir = Vector3D(i: 1.0, j: 1.0, k: 1.0)
        gDir.normalize()
        
        let redstone = try! Line(spot: gOrig, arrow: gDir)
        
        var pOrig = Point3D(x: 3.0, y: 6.5, z: -3.25)
        var pDir = Vector3D(i: 1.0, j: 1.0, k: 1.0)
        pDir.normalize()
        
        let titan = try! Line(spot: pOrig, arrow: pDir)
        
        XCTAssert(Line.isParallel(straightA: redstone, straightB: titan))    // They happen to be coincident
        
        
        pOrig = Point3D(x: 5.0, y: 6.5, z: -3.25)

        let titan2 = try! Line(spot: pOrig, arrow: pDir)
        
        XCTAssert(Line.isParallel(straightA: redstone, straightB: titan2))
        
        
           // Not parallel
        pOrig = Point3D(x: 3.0, y: 6.5, z: -3.25)
        pDir = Vector3D(i: 1.0, j: -1.0, k: 1.0)
        pDir.normalize()
        
        let titan3 = try! Line(spot: pOrig, arrow: pDir)
        
        XCTAssertFalse(Line.isParallel(straightA: redstone, straightB: titan3))    // Shouldn't show as parallel
        
    }
    
    
    func testIntersectTwo()   {
        
        let flatOrig = Point3D(x: 1.0, y: 0.0, z: 0.0)
        let flatDir = Vector3D(i: 0.0, j: 1.0, k: 0.0)
        
        let flat = try! Line(spot: flatOrig, arrow: flatDir)

        let P51Orig = Point3D(x: 3.0, y: 1.0, z: 0.0)
        var P51Dir = Vector3D(i: -0.707, j: 0.707, k: 0.0)
        P51Dir.normalize()
        
        let target = Point3D(x: 1.0, y: 3.0, z: 0.0)
        
        do   {
            
            let pursuit = try Line(spot: P51Orig, arrow: P51Dir)
            
            let crossroads = try Line.intersectTwo(straightA: flat, straightB: pursuit)
            
            XCTAssert(crossroads == target)
            
        }   catch   {
            XCTFail()   // Generated some kind of Error
        }
        
        let roofOrig = Point3D(x: 0.0, y: 0.0, z: 3.85)
        let roofDir = Vector3D(i: 1.0, j: 0.0, k: 0.0)
        
        let evelOrig = Point3D(x: -1.5, y: 0.0, z: 1.5)
        var evelDir = Vector3D(i: -0.707, j: 0.0, k: 0.707)
        evelDir.normalize()
        
        let target2 = Point3D(x: -3.85, y: 0.0, z: 3.85)
        
        do   {
            
            let flat = try Line(spot: roofOrig, arrow: roofDir)
            let pursuit = try Line(spot: evelOrig, arrow: evelDir)
            
            let crossroads = try Line.intersectTwo(straightA: flat, straightB: pursuit)
            
            XCTAssert(crossroads == target2)
            
        }   catch   {
            XCTFail()   // Generated some kind of Error
        }
        
        do   {
            
            let A36dir = Vector3D(i: 0.0, j: 1.0, k: 0.0)
            let merlin = try! Line(spot: P51Orig, arrow: A36dir)
            
            let crossroads = try Line.intersectTwo(straightA: flat, straightB: merlin)
            
            XCTAssert(crossroads == target2)
            
        } catch is ParallelLinesError  {
            XCTAssert(true)
        } catch {
            XCTFail()   // Generated a different kind of Error
        }

        do   {
            
            let crossroads = try Line.intersectTwo(straightA: flat, straightB: flat)
                        
            XCTAssert(crossroads == target2)
            
        } catch is CoincidentLinesError  {
            XCTAssert(true)
        } catch {
            XCTFail()   // Generated a different kind of Error
        }

        
        do   {
            
            let A36dir = Vector3D(i: 0.0, j: 0.0, k: 1.0)
            let merlin = try! Line(spot: P51Orig, arrow: A36dir)
            
            let crossroads = try Line.intersectTwo(straightA: flat, straightB: merlin)
            
            XCTAssert(crossroads == target2)
            
        } catch is NonCoPlanarLinesError  {
            XCTAssert(true)
        } catch {
            XCTFail()   // Generated a different kind of Error
        }


        do {
            let anchor = Point3D(x: -1.5, y: -1.5, z: -1.5)
            var thataway = Vector3D(i: -0.6, j: -0.6, k: -0.6)
            thataway.normalize()
            
            let rocket1 = try! Line(spot: anchor, arrow: thataway)
            
            let  anchor2 = Point3D(x: 3.5, y: 3.5, z: 3.5)
            let rocket2 = try! Line(spot: anchor2, arrow: thataway)
            
            let _ = try Line.intersectTwo(straightA: rocket1, straightB: rocket2)
            
        } catch is CoincidentLinesError  {
            XCTAssert(true)
        } catch {
            XCTFail()   // Generated a different kind of Error
        }

    }

    func testLineTransform()   {
        
        let lineX = try! Line(spot: Point3D(x: 0.5, y: 1.0, z: 2.0), arrow: Vector3D(i: 1.0, j: 0.0, k: 0.0))
        
        let lineY = try! Line(spot: Point3D(x: 0.5, y: 1.0, z: 2.0), arrow: Vector3D(i: 0.0, j: 1.0, k: 0.0))
        
        let lineZ = try! Line(spot: Point3D(x: 0.5, y: 1.0, z: 2.0), arrow: Vector3D(i: 0.0, j: 0.0, k: 1.0))
        
        let testCSYS = try! CoordinateSystem(spot: Point3D(x: 0.5, y: 1.0, z: 2.0), alpha: Vector3D(i: 1.0, j: 0.0, k: 0.0), beta: Vector3D(i: 0.0, j: 1.0, k: 0.0), gamma: Vector3D(i: 0.0, j: 0.0, k: 1.0))
        
        
        let fred = Transform.genFromGlobal(csys: testCSYS)
        let wilma = try! Transform.genToGlobal(csys: testCSYS)
        
        let spinY = Transform(rotationAxis: Axis.y, angleRad: Double.pi / 2.0)
        
        var localVersion = lineX.transform(xirtam: fred)
        var rotatedLocal = localVersion.transform(xirtam: spinY)
        var globalVersion = rotatedLocal.transform(xirtam: wilma)
        
        
        XCTAssert(Line.isCoincident(straightA: globalVersion, straightB: lineZ))

        
        let spinX = Transform(rotationAxis: Axis.x, angleRad: Double.pi / 2.0)
        
        localVersion = lineZ.transform(xirtam: fred)
        rotatedLocal = localVersion.transform(xirtam: spinX)
        globalVersion = rotatedLocal.transform(xirtam: wilma)
        
        
        XCTAssert(Line.isCoincident(straightA: globalVersion, straightB: lineY))

        
        let spinZ = Transform(rotationAxis: Axis.z, angleRad: Double.pi / 2.0)
        
        localVersion = lineY.transform(xirtam: fred)
        rotatedLocal = localVersion.transform(xirtam: spinZ)
        globalVersion = rotatedLocal.transform(xirtam: wilma)
        
        
        XCTAssert(Line.isCoincident(straightA: globalVersion, straightB: lineX))
        
    }
    
    func testResolveRelativePoint()   {
        
        let orig = Point3D(x: 2.0, y: 1.5, z: 0.0)
        let thataway = Vector3D(i: 1.0, j: 0.0, k: 0.0)
        let refLine = try! Line(spot: orig, arrow: thataway)
        
        let targetA = -2.0
        let targetP = 1.0
        
        let target = (targetA, targetP)
        
        let trial = Point3D(x: 0.0, y: 0.5, z: 0.0)
        let comps = refLine.resolveRelative(yonder: trial)
        
        XCTAssert(comps == target)
    }
    
    func testGenBisect()   {
        
        let pipA = Point3D(x: 1.0, y: 5.0, z: 2.0)
        let pipB = Point3D(x: 4.6, y: 5.0, z: 2.0)
        
        let dir1 = Vector3D(i: 0.0, j: 0.0, k: 1.0)
        
        let targetLoc = Point3D(x: 2.8, y: 5.0, z: 2.0)
        let targetDir = Vector3D(i: 0.0, j: 1.0, k: 0.0)
        
        let targetLine = try! Line(spot: targetLoc, arrow: targetDir)
        
        let chop = try! Line.genBisect(ptA: pipA, ptB: pipB, up: dir1)
        
        print(chop.getOrigin())
        print(chop.getDirection())
        
        XCTAssert(chop == targetLine)
        
        let dir2 = Vector3D(i: 1.0, j: 1.0, k: 0.0)
        
        do   {
            _ = try Line.genBisect(ptA: pipA, ptB: pipB, up: dir2)
        } catch is NonUnitDirectionError {
            XCTAssert(true)
        } catch {
            XCTFail()
        }

        
        let dir3 = Vector3D(i: 0.0, j: 0.0, k: 0.0)
        
        do   {
            _ = try Line.genBisect(ptA: pipA, ptB: pipB, up: dir3)
        } catch is ZeroVectorError {
            XCTAssert(true)
        } catch {
            XCTFail()
        }

        do   {
            _ = try Line.genBisect(ptA: pipA, ptB: pipA, up: dir1)
        } catch is CoincidentPointsError {
            XCTAssert(true)
        } catch {
            XCTFail()
        }

    }
    
    func testEquals()   {
        
        let knob = Point3D(x: 2.5, y: 1.6, z: -1.35)
        let dir = Vector3D(i: 1.0, j: 0.0, k: 0.0)
        
        let ray = try! Line(spot: knob, arrow: dir)
        
        let pip = Point3D(x: 2.5, y: 1.7, z: -1.35)
        let beam = try! Line(spot: pip, arrow: dir)
        
           // Parallel
        XCTAssertNotEqual(ray, beam)
        
        let pebble = Point3D(x: 1.5, y: 1.6, z: -1.35)
        let beam2 = try! Line(spot: pebble, arrow: dir)
        
           // Coincident
        XCTAssertNotEqual(ray, beam2)
        
        let dir2 = Vector3D(i: -1.0, j: 0.0, k: 0.0)
        let beam3 = try! Line(spot: knob, arrow: dir2)
        
           // Coincident but opposite
        XCTAssertNotEqual(ray, beam3)
        
        let bump = Point3D(x: 2.5, y: 1.6, z: -1.35)
        let thataway = Vector3D(i: 1.0, j: 0.0, k: 0.0)
        
        let beam4 = try! Line(spot: bump, arrow: thataway)
        XCTAssertEqual(ray, beam4)
    }
}
