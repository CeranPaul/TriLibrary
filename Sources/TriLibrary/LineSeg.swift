//
//  LineSeg.swift
//  SurfaceCrib
//
//  Created by Paul on 10/28/15.
//  Copyright © 2018 Ceran Digital Media. All rights reserved.  See LICENSE.md
//

import Foundation

/// A wire between two points.
public struct LineSeg: Equatable {
    
    
    // Can this be a struct, instead?
    
    // End points
    fileprivate var endAlpha: Point3D   // Private access to limit modification
    fileprivate var endOmega: Point3D
        
    /// The enum that hints at the meaning of the curve
    public var usage: PenTypes
    
    public var parameterRange: ClosedRange<Double>
    
    /// Build a line segment from two points
    /// - Throws: CoincidentPointsError
    public init(end1: Point3D, end2: Point3D) throws {
        
        guard end1 != end2 else { throw CoincidentPointsError(dupePt: end1)}
        
        self.endAlpha = end1
        self.endOmega = end2
        
        
        self.usage = PenTypes.Ordinary
        
        self.parameterRange = ClosedRange<Double>(uncheckedBounds: (lower: 0.0, upper: 1.0))
        
    }
    
    
    /// Fetch the location of an end
    /// - See: 'getOtherEnd()'
    public func getOneEnd() -> Point3D   {
        return endAlpha
    }
    
    /// Fetch the location of the opposite end
    /// - See: 'getOneEnd()'
    public func getOtherEnd() -> Point3D   {
        return endOmega
    }
    
    
    /// Attach new meaning to the curve
    public mutating func setIntent(purpose: PenTypes)   {
        
        self.usage = purpose
    }
    
    /// Get the box that bounds the curve
    public func getExtent() -> OrthoVol  {
        
        return try! OrthoVol(corner1: self.endAlpha, corner2: self.endOmega)
    }
    
    /// Flip the order of the end points  Used to align members of a Perimeter
    public mutating func reverse() -> Void  {
        
        let bubble = self.endAlpha
        self.endAlpha = self.endOmega
        self.endOmega = bubble
    }
    
    
    /// Move, rotate, and scale by a matrix
    /// - Throws: CoincidentPointsError if it was scaled to be very small
    public static func transform(xirtam: Transform, wire: LineSeg) throws -> LineSeg {
        
        let tAlpha = Point3D.transform(pip: wire.endAlpha, xirtam: xirtam)
        let tOmega = Point3D.transform(pip: wire.endOmega, xirtam: xirtam)
        
        var transformed = try LineSeg(end1: tAlpha, end2: tOmega)   // Will generate a new extent
        transformed.setIntent(purpose: wire.usage)   // Copy setting instead of having the default
        
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
    /// Assumes 0 < t < 1
    /// - Throws: CoincidentPointsError
    public func pointAt(t: Double) -> Point3D  {
        
        //TODO: Range checking would be good
        let wholeVector = Vector3D.built(from: self.endAlpha, towards: self.endOmega, unit: false)
        
        let scaled = wholeVector * t
        
        let spot = Point3D.offset(pip: self.endAlpha, jump: scaled)
        
        return spot
    }
    
    
    /// Plot the line segment.  This will be called by the UIView 'drawRect' function
    /// - Parameters:
    ///   - context: In-use graphics framework
    ///   - tform:  Model-to-display transform
    public func draw(context: CGContext, tform: CGAffineTransform)  {
        
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
    
    
    /// Calculate length
    /// - Returns: Distance
    func getLength() -> Double   {
        return Point3D.dist(pt1: self.endAlpha, pt2: self.endOmega)
    }
    
    
    /// Create a unit vector showing direction
    /// - Returns: Unit vector to indicate direction
    public func getDirection() -> Vector3D   {
        
        return Vector3D.built(from: self.endAlpha, towards: self.endOmega, unit: true)
    }
    
    
    /// Return the tangent vector, which won't depend on the input parameter
    /// Some notations show "t" as the parameter, instead of "u"
    /// - Returns:
    ///   - tan:  Non-normalized vector
    public func tangentAt(t: Double) -> Vector3D   {
        
        let along = Vector3D.built(from: self.endAlpha, towards: self.endOmega)
        return along
    }
    
    

    /// Create a trimmed version
    /// - Parameters:
    ///   - stub:  New terminating point
    ///   - keepNear: Retain the near or far remnant?
    /// - Warning:  No checks are made to see that stub lies on the segment
    /// - Returns: A new LineSeg
    /// - Warning:  Does not have a Unit Test
    public func clipTo(stub: Point3D, keepNear: Bool) -> LineSeg   {
        
        var freshSeg: LineSeg
        
        if keepNear   {
            freshSeg = try! LineSeg(end1: self.getOneEnd(), end2: stub)
        }  else  {
            freshSeg = try! LineSeg(end1: stub, end2: self.getOtherEnd())
        }
        
        return freshSeg
    }
    
    
    /// Find possible intersection points with a line
    /// - Parameters:
    ///   - ray:  The Line to be used for intersecting
    ///   - accuracy:  How close is close enough?
    /// - Returns: Possibly empty Array of points common to both curves
    /// - See: 'testIntersectLine' under LineSegTests
    public func intersect(ray: Line, accuracy: Double = Point3D.Epsilon) -> [Point3D] {
        
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
            
            /// Vector from segment origin towards intersection
            let rescue = Vector3D.built(from: self.getOneEnd(), towards: collision, unit: true)
            
            let sameDir = Vector3D.dotProduct(lhs: self.getDirection(), rhs: rescue)
            
            if sameDir > 0.0   {
                
                let dist = Point3D.dist(pt1: self.getOneEnd(), pt2: collision)
                
                if dist <= self.getLength()   {
                    
                    crossings.append(collision)
                }
            }
        }
        
        return crossings
    }
    
    

    
    
    /// See if another segment crosses this one
    /// Used for seeing if a screen gesture cuts across the current seg
    /// - Warning:  Does not have a Unit Test
    public func isCrossing(chop: LineSeg) -> Bool   {
        
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
    
    
    /// Calculate the crown over a small segment
    public func findCrown(smallerT: Double, largerT: Double) -> Double   {
        return 0.0
    }
    
    
    /// Find the change in parameter that meets the crown requirement
    /// - Parameters:
    ///   - allowableCrown:  Acceptable deviation from curve
    ///   - currentT:  Present value of the driving parameter
    ///   - increasing:  Whether the change in parameter should be up or down
    /// - Returns: New value for driving parameter
    public func findStep(allowableCrown: Double, currentT: Double, increasing: Bool) -> Double   {
        
        var trialT : Double
        
        if increasing   {
            trialT = 1.0
        }  else  {
            trialT = 0.0
        }
        
        return trialT
    }
    
    // TODO: This leads one to think that an "isReversed" test would be good.
    
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
