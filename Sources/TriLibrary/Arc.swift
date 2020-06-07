//
//  Arc.swift
//  ArcHammer
//
//  Created by Paul Hollingshead on 8/24/19.
//  Copyright © 2019 Paul Hollingshead. All rights reserved.
//

import Foundation

/// Can represent a portion, or a complete circle
public struct Arc: Equatable   {
    
    /// Anchor point for swinging
    var center: Point3D
    
    /// Direction perpendicular to resulting Arc
    var axis: Vector3D
    
    /// Where the Arc begins
    var startPt: Point3D
    
    /// Angle covered by the Arc - in radians.  -2pi to 2pi
    var sweepAngle: Double
    
    /// The enum that hints at the meaning of the curve
    public var usage: PenTypes
    
    
    /// Turn local points into global points
    var toGlobal: Transform
    
    /// Turn global points into local
    var fromGlobal: Transform
    
    
    /// Distance of all points from the center
    var radius: Double
        
    
    /// Create a new one. Use this intializer for a half or whole circle.
    /// - Parameters:
    ///   - ctr: Point to be used as origin
    ///   - axis: Pivot direction for rotating
    ///   - start: Beginning point
    ///   - sweep: Sweep angle in radians. Positive or negative.
    /// - Throws:
    ///   - NonUnitDirectionError for a bad set of inputs
    ///   - NonOrthogonalPointError
    ///   - ParameterRangeError
    /// - See: 'testFidelityCASS' under ArcTests
    init(ctr: Point3D, axis: Vector3D, start: Point3D, sweep: Double) throws   {
        
        guard axis.isUnit() else { throw NonUnitDirectionError(dir: axis) }
        
        /// What can be considered horizontal for this Arc
        let baseline = Vector3D.built(from: ctr, towards: start, unit: true)
        
        let myDot = Vector3D.dotProduct(lhs: axis, rhs: baseline)
        
        guard myDot < Vector3D.EpsilonV else { throw NonOrthogonalPointError(trats: start) }
        
        // TODO: Needs a more specific error type?
        let minSweep = Double.pi * -2.0
        guard sweep >= minSweep else { throw ParameterRangeError(parA: sweep) }
        
        let maxSweep = Double.pi * 2.0
        guard sweep <= maxSweep else { throw ParameterRangeError(parA: sweep) }

        
        self.center = ctr
        
        self.axis = axis
        
        self.startPt = start
        
        self.sweepAngle = sweep
        
        
        self.radius = Point3D.dist(pt1: ctr, pt2: start)
        
        self.usage = .Ordinary
        
        
        /// Coordinate system
        let csys = try CoordinateSystem(origin: self.center, refDirection: baseline, normal: self.axis)
        
        self.toGlobal = try! Transform.genToGlobal(csys: csys)
        
        self.fromGlobal = Transform.genFromGlobal(csys: csys)
        
    }
    
    /// Create from center and two endpoints.
    /// Use the other initializer for a half or whole circle.
    /// - Parameters:
    ///   - ctr: Point to be used as origin
    ///   - end1: Starting point
    ///   - end2: Final point
    ///   - useSmallAngle: Flag to indicate which of the two possible Arcs to use
    /// - Throws:
    ///   - ArcPointsError for a bad set of inputs
    ///   - CoincidentPointsError for identical endpoints
    ///   - CoincidentPointsError for collinear points
    /// - See: 'testFidelityThreePoints' under ArcTests
    init(center: Point3D, end1: Point3D, end2: Point3D, useSmallAngle: Bool) throws   {
        
        let rad1 = Point3D.dist(pt1: center, pt2: end1)
        let rad2 = Point3D.dist(pt1: center, pt2: end2)
        
        guard abs(rad1 - rad2) < Point3D.Epsilon else { throw ArcPointsError(badPtA: center, badPtB: end1, badPtC: end2) }

        guard end1 != end2 else { throw CoincidentPointsError(dupePt: end1) }
        
        //TODO: Needs a better error type
        guard !Point3D.isThreeLinear(alpha: center, beta: end1, gamma: end2) else { throw CoincidentPointsError(dupePt: end1) }
        
        
        self.center = center
        
        self.startPt = end1
        
        self.radius = rad1
        
        /// What can be considered horizontal for this Arc
        let baseline = Vector3D.built(from: center, towards: end1, unit: true)
        
        let buttress = Vector3D.built(from: center, towards: end2, unit: true)
        
        var up = try Vector3D.crossProduct(lhs: baseline, rhs: buttress)
        up.normalize()
        
        self.axis = up
        
        var vert = try Vector3D.crossProduct(lhs: up, rhs: baseline)
        vert.normalize()
        
        let vComponent = Vector3D.dotProduct(lhs: vert, rhs: buttress)
        let hComponent = Vector3D.dotProduct(lhs: baseline, rhs: buttress)
        
        let endAngle = atan2(vComponent, hComponent)
        
        if useSmallAngle   {
            self.sweepAngle = endAngle
        }  else  {
            self.sweepAngle = endAngle - Double.pi * 2.0
        }
        
        self.usage = .Ordinary
        
        /// Coordinate system
        let csys = try CoordinateSystem(origin: self.center, refDirection: baseline, normal: self.axis)
        
        self.toGlobal = try! Transform.genToGlobal(csys: csys)
        
        self.fromGlobal = Transform.genFromGlobal(csys: csys)
        
    }
    
    /// Attach new meaning to the curve
    /// - Parameter: purpose:PenTypes
    public mutating func setIntent(purpose: PenTypes)   {
        
        self.usage = purpose
    }
    
    /// Fetch the location of the pivot point
    public func getCenter() -> Point3D   {
        return self.center
    }
    
    /// Fetch the location of an end
    /// - See: 'getOtherEnd()'
    public func getOneEnd() -> Point3D   {
        return self.startPt
    }
    
    /// Fetch the location of the opposite end
    /// - See: 'getOneEnd()'
    public func getOtherEnd() -> Point3D   {
        
        let localPt = self.pointAtAngle(theta: self.sweepAngle)
        let globalEnd = Point3D.transform(pip: localPt, xirtam: self.toGlobal)
        return globalEnd
    }
    
    public func getRadius() -> Double   {
        return self.radius
    }
    
    public func getAxisDir() -> Vector3D   {
        return self.axis
    }
    
    public func getSweepAngle() -> Double   {
        return self.sweepAngle
    }
    
    /// Generate a point at the given angle
    /// - Returns: A point in the local CSYS
    public func pointAtAngle(theta: Double) -> Point3D   {
        
        //TODO: Range checking would be good
        let horiz = cos(theta) * self.radius
        let vert = sin(theta) * self.radius
        
        let local = Point3D(x: horiz, y: vert, z: 0.0)
        
        return local
    }
    
    
    /// - Returns: A point in the global CSYS
    public func pointAt(t: Double) throws -> Point3D   {
        
        guard t >= 0.0 else { throw ParameterRangeError(parA: t) }
        guard t <= 1.0 else { throw ParameterRangeError(parA: t) }
        
        let ratioedAngle = self.sweepAngle * t
        let localPt = self.pointAtAngle(theta: ratioedAngle)
        let globalPt = Point3D.transform(pip: localPt, xirtam: self.toGlobal)
        
        return globalPt
    }
    
    /// Figure the global brick that contains the curve
    public func getExtent() -> OrthoVol   {
        
        let divs = 20.0
        
        let sweepInc = self.sweepAngle / divs
        
        /// Global points on the curve
        var droplets = [Point3D]()
        
        for g in 0...Int(divs)   {
            let theta = Double(g) * sweepInc
            let localPip = self.pointAtAngle(theta: theta)
            let globalPip = Point3D.transform(pip: localPip, xirtam: self.toGlobal)
            droplets.append(globalPip)
        }
        
        /// The end result and return value
        var brick = try! OrthoVol(corner1: droplets[0], corner2: droplets[1])   // Might fail for a really small Arc
        
        for g in 2..<droplets.count   {
            let smallBrick = try! OrthoVol(corner1: droplets[g - 1], corner2: droplets[g])
            brick = brick + smallBrick
        }

        return brick
    }
    
    /// Create only enough points to meet the crown limit
    /// - Parameter: allowableCrown: Maximum deviation from the actual curve
    /// - Returns: Array of evenly spaced points in the local coordinate system
    public func approximate(allowableCrown: Double) -> [Point3D]   {
        
        //TODO: Add a guard statement to verify that allowable crown is positive
        
        let ratio = 1.0 - allowableCrown / self.radius
        let maxSwing =  2.0 * acos(ratio)
        
        let count = ceil(abs(self.sweepAngle / maxSwing))
        
        let angleStep = self.sweepAngle / count
        
        
        /// Collection of points to be returned
        var chain = [Point3D]()
        
        let firstPt = pointAtAngle(theta: 0.0)
        chain.append(firstPt)
        
        for index in 1...Int(count)   {
            let theta = Double(index) * angleStep
            let freshPt = pointAtAngle(theta: theta)
            chain.append(freshPt)
        }
        
        return chain
    }
    

    /// Untested version
    public func transform(xirtam: Transform) throws -> Arc {
        
        let freshCtr = Point3D.transform(pip: self.center, xirtam: xirtam)
        
        let freshDir = Vector3D.transform(thataway: self.axis, xirtam: xirtam)
        
        let freshStart = Point3D.transform(pip: self.startPt, xirtam: xirtam)
        
        
        let fresh = try Arc(ctr: freshCtr, axis: freshDir, start: freshStart, sweep: self.sweepAngle)
        
        return fresh
    }
    
        
    /// Plot the circle segment.  This will be called by the UIView 'drawRect' function
    /// - Parameters:
    ///   - context: In-use graphics framework
    ///   - tform:  Model-to-display transform
    public func draw(context: CGContext, tform: CGAffineTransform) -> Void  {
        
        /// Closure to generate a point for display
//        let toScreen:(Point3D) ->CGPoint  = { pip in
//            let global = self.toGlobal.alter(pip: pip)   // Transform from local to global CSYS
//            let asCG = CGPoint(x: global.x, y: global.y)   // Make a CGPoint
//            let onScreen = asCG.applying(tform)   // Shift and scale for screen
//            return onScreen
//        }
        
        /// Array of points in the local coordinate system
        let dots = self.approximate(allowableCrown: 0.001)   //TODO: Make this a variable
        
        let toScreen = { (spot: Point3D) -> CGPoint in
            let global = Point3D.transform(pip: spot, xirtam: self.toGlobal)   // Transform from local to global CSYS
            let asCG = CGPoint(x: global.x, y: global.y)   // Make a CGPoint
            let onScreen = asCG.applying(tform)   // Shift and scale for screen
            return onScreen
        }
        
        let screenDots = dots.map( { toScreen($0) } )
        
        context.move(to: screenDots.first!)
                
        for index in 1..<screenDots.count   {
            context.addLine(to: screenDots[index])
        }
        
        context.strokePath()
        
    }
        
    /// Compare each component of the Arc for equality
    /// - See: 'testEquals' under ArcTests
    public static func == (lhs: Arc, rhs: Arc) -> Bool   {
        
        let ctrFlag = lhs.center == rhs.center
        let axisFlag = lhs.getAxisDir() == rhs.getAxisDir()
        let startFlag = lhs.getOneEnd() == rhs.getOneEnd()
        let sweepFlag = lhs.getSweepAngle() == rhs.getSweepAngle()
        
        return ctrFlag && axisFlag && startFlag && sweepFlag
    }
        
}
