//
//  LineSeg.swift
//  CurvPack
//
//  Created by Paul on 10/28/15.
//  Copyright © 2021 Ceran Digital Media. All rights reserved.  See LICENSE.md
//

import Foundation
import CoreGraphics

/// A wire between two points.
public struct LineSeg: PenCurve, Equatable {
    
    
    // End points
    fileprivate var endAlpha: Point3D   // Private access to limit modification
    fileprivate var endOmega: Point3D
        
    /// The String that hints at the meaning of the curve
    public var usage: String
    
    public var trimParameters: ClosedRange<Double>
    
    
    /// Build a line segment from two points
    /// - Parameters:
    ///   - end1:  One point
    ///   - end2:  Other point
    /// - Throws: CoincidentPointsError
    /// - See: 'testFidelity' under LineSegTests
    public init(end1: Point3D, end2: Point3D) throws {
        
        guard end1 != end2 else { throw CoincidentPointsError(dupePt: end1)}
        
        self.endAlpha = end1
        self.endOmega = end2
        
        
        self.usage = "Ordinary"
        
        self.trimParameters = ClosedRange<Double>(uncheckedBounds: (lower: 0.0, upper: 1.0))
        
    }
    
    
    /// Fetch the location of an end
    /// - SeeAlso: 'getOtherEnd()'
    /// - See: 'testFidelity' under LineSegTests
    public func getOneEnd() -> Point3D   {
        return endAlpha
    }
    
    /// Fetch the location of the opposite end
    /// - SeeAlso: 'getOneEnd()'
    /// - See: 'testFidelity' under LineSegTests
    public func getOtherEnd() -> Point3D   {
        return endOmega
    }
    
    
    /// Attach new meaning to the curve
    /// - See: 'testSetIntent' under LineSegTests
    public mutating func setIntent(purpose: String)   {
        
        self.usage = purpose
    }
    
    /// Get the box that bounds the curve
    /// - Returns: Brick aligned to the CSYS
    public func getExtent() -> OrthoVol  {
        
        return try! OrthoVol(corner1: self.endAlpha, corner2: self.endOmega)
    }
    
    /// Flip the order of the end points  Used to align members of a Perimeter
    /// - See: 'testReverse' under LineSegTests
    public mutating func reverse() -> Void  {
        
        let bubble = self.endAlpha
        self.endAlpha = self.endOmega
        self.endOmega = bubble
    }
    
    
    /// Move, rotate, and scale by a matrix
    /// - Parameters:
    ///   - xirtam:  Transform to be applied
    /// - Throws: CoincidentPointsError if it was scaled to be very small
    /// - Returns:  Modified LineSeg
    public func transform(xirtam: Transform) throws -> PenCurve {
        
        let tAlpha = endAlpha.transform(xirtam: xirtam)
        let tOmega = endOmega.transform(xirtam: xirtam)
        
        var transformed = try LineSeg(end1: tAlpha, end2: tOmega)   // Will generate a new extent
        transformed.setIntent(purpose: self.usage)   // Copy setting instead of having the default
        
        return transformed
    }
    
    

    /// Flip line segment to the opposite side of the plane
    /// - Parameters:
    ///   - flat:  Mirroring plane
    ///   - wire:  LineSeg to be flipped
    /// - Returns: New LineSeg
    /// - See: 'testMirrorLineSeg' under PlaneTests
    public static func mirror(flat: Plane, wire: LineSeg) -> LineSeg   {
        
        /// Point to be worked on
        var pip: Point3D = wire.getOneEnd()
        
        ///New point from mirroring
        let fairest1 = Point3D.mirror(flat: flat, pip: pip)
        
        pip = wire.getOtherEnd()
        
        ///New point from mirroring
        let fairest2 = Point3D.mirror(flat: flat, pip: pip)
        
        let mirroredLineSeg = try! LineSeg(end1: fairest1, end2: fairest2)
        // The forced unwrapping should be no risk because it uses points from a LineSeg that has already checked out.
        
        return mirroredLineSeg
    }
    
    /// Find the point along this line segment specified by the parameter 't'
    /// Checks that  0 < t < 1
    /// - Throws:
    ///     - ParameterRangeError if the input is lame
    /// - Returns: New Point3D
    /// - See: 'testPointAt' under LineSegTests
    public func pointAt(t: Double) throws -> Point3D  {
        
        guard self.trimParameters.contains(t) else { throw ParameterRangeError(parA: t) }
        

        let wholeVector = Vector3D.built(from: self.endAlpha, towards: self.endOmega, unit: false)
        
        let scaled = wholeVector * t
        
        let spot = Point3D.offset(pip: self.endAlpha, jump: scaled)
        
        return spot
    }
    
    
    /// Check whether a point is or isn't perched on the curve.
    /// - Parameters:
    ///   - speck:  Point near the curve.
    /// - Returns: Flag, and optional parameter value
    /// - See: 'testPerch' under LineSegTests
    public func isPerchFor(speck: Point3D) throws -> (flag: Bool, param: Double?)   {
        
           // Shortcuts!
        if speck == self.endAlpha   { return (true, self.trimParameters.lowerBound) }
        if speck == self.endOmega   { return (true, self.trimParameters.upperBound) }
        
        /// True length along the curve
        let curveLength = self.getLength()
        
        let relPos = self.resolveRelativeVec(speck: speck)
        
        if relPos.perp.length() > Point3D.Epsilon   { return (false, nil) }
        else {
            if relPos.along.length() < curveLength   {
                
                let lsDir = Vector3D.built(from: self.endAlpha, towards: endOmega, unit: true)
                var dupe = relPos.along
                dupe.normalize()
                
                if Vector3D.dotProduct(lhs: lsDir, rhs: dupe) != 1.0   { return (false, nil) }
                let proportion = relPos.along.length() / curveLength
                return (true, proportion)
            }
        }
        
        return (false, nil)
    }
    
    /// Plot the line segment.  This will be called by the UIView 'drawRect' function.
    /// Part of PenCurve protocol.
    /// - Parameters:
    ///   - context: In-use graphics framework
    ///   - tform:  Model-to-display transform
    ///   - allowableCrown: Maximum deviation from the actual curve. Ignored for this struct.
    public func draw(context: CGContext, tform: CGAffineTransform, allowableCrown: Double) throws   {
        
        context.beginPath()
        
        var spot = Point3D.makeCGPoint(pip: self.endAlpha)    // Throw out Z coordinate
        let screenSpotAlpha = spot.applying(tform)
        context.move(to: screenSpotAlpha)
        
        spot = Point3D.makeCGPoint(pip: self.endOmega)    // Throw out Z coordinate
        let screenSpotOmega = spot.applying(tform)
        context.addLine(to: screenSpotOmega)
        
        context.strokePath()
    }
    
    
    /// Find the position of a point relative to the LineSeg
    /// - Returns: Tuple of vectors - one along the seg, other perp to it
    /// - See: 'testResolveRelative' under LineSegTests
    public func resolveRelativeVec(speck: Point3D) -> (along: Vector3D, perp: Vector3D)   {
        
        /// Direction of the segment.  Is a unit vector.
        let thisWay = self.getDirection()
        
        let bridge = Vector3D.built(from: self.endAlpha, towards: speck)
        
        let along = Vector3D.dotProduct(lhs: bridge, rhs: thisWay)
        let alongVector = thisWay * along
        let perpVector = bridge - alongVector
        
        return (alongVector, perpVector)
    }
    
    
    /// Find two distances describing the position of a point relative to the LineSeg.
    /// - Parameters:
    ///   - speck:  Point of interest
    /// - Returns: Tuple of distances - one along the seg, other away from it
    public func resolveRelative(speck: Point3D) -> (along: Double, away: Double)   {
        
        let components = resolveRelativeVec(speck: speck)
        
        let a = components.along.length()
        let b = components.perp.length()
        
        return (a, b)
    }
    // TODO: Write tests for the above inside LineSegTests
    
    
    /// Calculate length.
    /// Part of PenCurve protocol.
    /// - Returns: Distance between the endpoints
    /// - See: 'testLength' under LineSegTests
    public func getLength() -> Double   {
        return Point3D.dist(pt1: self.endAlpha, pt2: self.endOmega)
    }
    
    
    /// Create a unit vector showing direction.
    /// - Returns: Unit vector
    public func getDirection() -> Vector3D   {
        
        return Vector3D.built(from: self.endAlpha, towards: self.endOmega, unit: true)
    }
    
    
    /// Return the tangent vector, which won't depend on the input parameter.
    /// Part of PenCurve protocol.
    /// Some notations show "u" as the parameter, instead of "t"
    /// - Parameters:
    ///   - t:  Parameter value
    /// - Throws:
    ///     - ParameterRangeError if the input is lame
    /// - Returns:
    ///   - tan:  Non-normalized vector
    /// - See: 'testTangent' under LineSegTests
    public func tangentAt(t: Double) throws -> Vector3D   {
        
        guard self.trimParameters.contains(t) else { throw ParameterRangeError(parA: t) }
        
        let along = Vector3D.built(from: self.endAlpha, towards: self.endOmega)
        return along
    }
    
    

    /// Create a trimmed version
    /// - Parameters:
    ///   - stub:  New terminating point
    ///   - keepNear: Retain the near or far remnant?
    /// - Warning:  No checks are made to see that stub lies on the segment
    /// - Returns: A new LineSeg
    /// - See: 'testClipTo' under LineSegTests
    public func clipTo(stub: Point3D, keepNear: Bool) -> LineSeg   {
        
        var freshSeg: LineSeg
        
        if keepNear   {
            freshSeg = try! LineSeg(end1: self.getOneEnd(), end2: stub)
        }  else  {
            freshSeg = try! LineSeg(end1: stub, end2: self.getOtherEnd())
        }
        
        return freshSeg
    }
    
    
    /// Find possible intersection points with a line.
    /// Part of PenCurve protocol.
    /// - Parameters:
    ///   - ray:  The Line to be used for intersecting
    ///   - accuracy:  How close is close enough?
    /// - Returns: Possibly empty Array of points common to both curves
    /// - See: 'testIntersectLine' under LineSegTests
    public func intersect(ray: Line, accuracy: Double = Point3D.Epsilon) -> [Point3D]   {
        
        /// The return array
        var crossings = [Point3D]()
        
        /// Line built from this segment
        let unbounded = try! Line(spot: self.getOneEnd(), arrow: self.getDirection())
        
        if Line.isParallel(straightA: unbounded, straightB: ray)   {   // Deal with parallel lines
            
            if Line.isCoincident(straightA: unbounded, straightB: ray)   {   // Coincident lines
                
                crossings.append(self.getOneEnd())
                crossings.append(self.getOtherEnd())
                
            }
            
        }  else  {   // Not parallel lines
            
            /// Intersection of the two lines
            let collision = try! Line.intersectTwo(straightA: unbounded, straightB: ray)
            
            /// Vector from segment origin towards intersection. Possible to be zero length.
            let rescue = Vector3D.built(from: self.getOneEnd(), towards: collision, unit: true)
            
            if rescue.isZero()   {   // Intersection at first end.
                crossings.append(collision)
                return crossings                
            }
            
            let sameDir = Vector3D.dotProduct(lhs: self.getDirection(), rhs: rescue)
            
            if sameDir > 0.0   {
                
                let dist = Point3D.dist(pt1: self.getOneEnd(), pt2: collision)
                
                if (self.getLength() - dist) > -1.0 * Point3D.Epsilon   {
                    
                    crossings.append(collision)
                }
            }
        }
        
        return crossings
    }
    
    
    /// See if another segment crosses this one.
    /// Used for seeing if a screen gesture cuts across the current seg.
    /// - Parameters:
    ///   - chop:  LineSeg of interest
    /// - Returns: Simple flag
    /// - See: 'testIsCrossing' under LineSegTests
    public func isCrossing(chop: LineSeg) -> Bool   {
        
        /// Vector components of each endpoint
        let compsA = self.resolveRelativeVec(speck: chop.endAlpha)
        let compsB = self.resolveRelativeVec(speck: chop.endOmega)
        
           // Should be negative if ends are on opposite sides
        let compliance = Vector3D.dotProduct(lhs: compsA.perp, rhs: compsB.perp)
        
        let flag1 = compliance < 0.0
        
        let farthest = self.getLength()
        
        let flag2A = compsA.along.length() <= farthest
        let flag2B = compsB.along.length() <= farthest
        
        return flag1 && flag2A && flag2B
    }
    
    
    /// Generate array points suitable for drawing.
    /// Part of PenCurve protocol.
    /// - Parameter allowableCrown: Acceptable deviation from the curve
    /// - Throws: NegativeAccuracyError even though allowableCrown is ignored.
    /// - Returns: Array of two Point3D's
    public func approximate(allowableCrown: Double) throws -> [Point3D]   {
        
        guard allowableCrown > 0.0 else { throw NegativeAccuracyError(acc: allowableCrown) }
            
        /// Collection of points to be returned
        var chain = [Point3D]()
        
        chain.append(getOneEnd())
        chain.append(getOtherEnd())
        
        return chain
    }
    
    /// Calculate the crown over a small segment
    /// - See: 'testCrown' under LineSegTests
    public func findCrown(smallerT: Double, largerT: Double) -> Double   {
        return 0.0
    }
    
    
    /// Find the change in parameter that meets the crown requirement
    /// - Parameters:
    ///   - allowableCrown:  Acceptable deviation from curve
    ///   - currentT:  Present value of the driving parameter
    ///   - increasing:  Whether the change in parameter should be up or down
    /// - Returns: New value for driving parameter
    /// - See: 'testFindStep' under LineSegTests
    public func findStep(allowableCrown: Double, currentT: Double, increasing: Bool) -> Double   {
        
        var trialT : Double
        
        if increasing   {
            trialT = 1.0
        }  else  {
            trialT = 0.0
        }
        
        return trialT
    }
    
    // TODO: An "isReversed" test would be good.
    
    /// Compare each endpoint of the segment.
    /// - Parameters:
    ///   - lhs:  One LineSeg for comparison
    ///   - rhs:  Another LineSeg for comparison
    /// - See: 'testEquals' under LineSegTests.
    public static func == (lhs: LineSeg, rhs: LineSeg) -> Bool   {
        
        let flagOne = lhs.endAlpha == rhs.endAlpha
        let flagOther = lhs.endOmega == rhs.endOmega
        
        return flagOne && flagOther
    }
    
}
