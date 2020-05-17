//
//  Cubic.swift
//  SketchCurves
//
//  Created by Paul on 12/14/15.
//  Copyright © 2018 Ceran Digital Media. See LICENSE.md
//

import Foundation
import simd

// What's the right way to check for equivalence?  End points and control points?

// TODO: Will need a way to find what point, if any, has a particular slope
// TODO: Add a bisecting function for Vector3D

// TODO: Clip from either end and re-parameterize.  But what about 'undo'?  Careful with a lack of proportionality


/// Curve defined by polynomials for each coordinate direction.
/// Parameter must fall within the range of 0.0 to 1.0.
/// Bezier form is used to store the curve definition.
open class Cubic: PenCurve   {    
        
    var ax: Double
    var bx: Double
    var cx: Double
    var dx: Double
    
    var ay: Double
    var by: Double
    var cy: Double
    var dy: Double
    
    var az: Double   // For a curve in the XY plane, these can be ignored, or set to zero
    var bz: Double   // Sounds like a good check to run - in all three axes.
    var cz: Double
    var dz: Double
    
    /// The beginning point
    var ptAlpha: Point3D
    
    /// The end point
    var ptOmega: Point3D
    
    var controlA: Point3D?   // Since Bezier form is most useful for editing
    var controlB: Point3D?
    
    /// The enum that hints at the meaning of the curve
    open var usage: PenTypes
    
    /// Limited to be bettween 0.0 and 1.0
    public var parameterRange: ClosedRange<Double>
    
    
    
    
    /// Build from 12 individual parameters.
    public init(ax: Double, bx: Double, cx: Double, dx: Double, ay: Double, by: Double, cy: Double, dy: Double, az: Double, bz: Double, cz: Double, dz: Double)   {
        
        self.ax = ax
        self.bx = bx
        self.cx = cx
        self.dx = dx
        
        self.ay = ay
        self.by = by
        self.cy = cy
        self.dy = dy
        
        self.az = az
        self.bz = bz
        self.cz = cz
        self.dz = dz
        
        ptAlpha = Point3D(x: dx, y: dy, z: dz)   // Create the beginning point from parameters
        
        
        let sumX = self.ax + self.bx + self.cx + self.dx   // Create the end point from an assumed parameter value of 1.0
        let sumY = self.ay + self.by + self.cy + self.dy
        let sumZ = self.az + self.bz + self.cz + self.dz
        
        ptOmega = Point3D(x: sumX, y: sumY, z: sumZ)
        
        
        self.usage = PenTypes.Ordinary
        
        self.parameterRange = ClosedRange<Double>(uncheckedBounds: (lower: 0.0, upper: 1.0))
        
    }
    
    
    /// Build from two points and two slopes.
    /// This code always produces the Bezier form for ease of screen editing.
    /// The assignment statements come from an algebraic manipulation of the equations
    /// in the Wikipedia article on Cubic Hermite spline.
    /// - Parameters:
    ///   - ptA: First end point
    ///   - slopeA: Slope that goes with the first end point
    ///   - ptB: Other end point
    ///   - slopeB: Slope that goes with the second end point
    /// There are checks here for input points that should be added!
    /// - See: 'testHermite' and 'testSumsHermite' under CubicTests
    public init(ptA: Point3D, slopeA: Vector3D, ptB: Point3D, slopeB: Vector3D) throws   {
        
        guard !slopeA.isZero() else { throw ZeroVectorError(dir: slopeA) }
        guard !slopeB.isZero() else { throw ZeroVectorError(dir: slopeB) }
        
        guard !(ptA == ptB) else { throw CoincidentPointsError(dupePt: ptA) }

        ptAlpha = ptA
        ptOmega = ptB
        
        self.ax = 2.0 * ptA.x + slopeA.i - 2.0 * ptB.x + slopeB.i
        self.bx = -3.0 * ptA.x - 2.0 * slopeA.i + 3.0 * ptB.x - slopeB.i
        self.cx = slopeA.i
        self.dx = ptA.x
        
        self.ay = 2.0 * ptA.y + slopeA.j - 2.0 * ptB.y + slopeB.j
        self.by = -3.0 * ptA.y - 2.0 * slopeA.j + 3.0 * ptB.y - slopeB.j
        self.cy = slopeA.j
        self.dy = ptA.y
        
        self.az = 2.0 * ptA.z + slopeA.k - 2.0 * ptB.z + slopeB.k
        self.bz = -3.0 * ptA.z - 2.0 * slopeA.k + 3.0 * ptB.z - slopeB.k
        self.cz = slopeA.k
        self.dz = ptA.z
        
        self.usage = PenTypes.Ordinary
        
        self.parameterRange = ClosedRange<Double>(uncheckedBounds: (lower: 0.0, upper: 1.0))
        
    }
    
    
    /// Build from two end points and two control points.
    /// Assignment statements from an algebraic manipulation of the equations
    /// in the Wikipedia article on Bezier Curve.
    /// - Parameters:
    ///   - ptA: First end point
    ///   - controlA: Control point for first end
    ///   - ptB: Other end point
    ///   - controlB: Control point for second end
    /// There are checks here for input points that should be added!
    /// - See: 'testSumsBezier' under CubicTests
    public init(ptA: Point3D, controlA: Point3D, controlB: Point3D, ptB: Point3D) throws   {
        
        let pool = [ptA, controlA, controlB, ptB]
        guard Point3D.isUniquePool(flock: pool) else { throw CoincidentPointsError(dupePt: ptA)}
        
        // TODO: Then add tests to see that the guard statements are doing their job
        
        self.ptAlpha = ptA
        self.ptOmega = ptB
        
        self.controlA = controlA
        self.controlB = controlB
        
        
        self.ax = 3.0 * self.controlA!.x - self.ptAlpha.x - 3.0 * self.controlB!.x + self.ptOmega.x
        self.bx = 3.0 * self.ptAlpha.x - 6.0 * self.controlA!.x + 3.0 * self.controlB!.x
        self.cx = 3.0 * self.controlA!.x - 3.0 * self.ptAlpha.x
        self.dx = self.ptAlpha.x
        
        self.ay = 3.0 * self.controlA!.y - self.ptAlpha.y - 3.0 * self.controlB!.y + self.ptOmega.y
        self.by = 3.0 * self.ptAlpha.y - 6.0 * self.controlA!.y + 3.0 * self.controlB!.y
        self.cy = 3.0 * self.controlA!.y - 3.0 * self.ptAlpha.y
        self.dy = self.ptAlpha.y
        
        self.az = 3.0 * self.controlA!.z - self.ptAlpha.z - 3.0 * self.controlB!.z + self.ptOmega.z
        self.bz = 3.0 * self.ptAlpha.z - 6.0 * self.controlA!.z + 3.0 * self.controlB!.z
        self.cz = 3.0 * self.controlA!.z - 3.0 * self.ptAlpha.z
        self.dz = self.ptAlpha.z
        
        self.usage = PenTypes.Ordinary
        
        self.parameterRange = ClosedRange<Double>(uncheckedBounds: (lower: 0.0, upper: 1.0))
        
    }
    
    /// Construct from four points that lie on the curve.  This is the way to build an offset curve.
    /// - Parameters:
    ///   - alpha: First point
    ///   - beta: Second point
    ///   - betaFraction: Portion along the curve for point beta
    ///   - gamma: Third point
    ///   - gammaFraction: Portion along the curve for point gamma
    ///   - delta: Last point
    public init(alpha: Point3D, beta: Point3D, betaFraction: Double, gamma: Point3D, gammaFraction: Double, delta: Point3D) throws  {
        
        self.parameterRange = ClosedRange<Double>(uncheckedBounds: (lower: 0.0, upper: 1.0))
        
        guard self.parameterRange.contains(betaFraction) else { throw ParameterRangeError(parA: betaFraction) }
        guard self.parameterRange.contains(gammaFraction) else { throw ParameterRangeError(parA: gammaFraction) }
        
        let pool = [alpha, beta, gamma, delta]
        guard Point3D.isUniquePool(flock: pool) else { throw CoincidentPointsError(dupePt: alpha)}
        
        // TODO: Then add tests to see that the guard statements are doing their job
        
        self.ptAlpha = alpha
        self.ptOmega = delta
        
        // Rearrange coordinates into an array
        let rowX = SIMD4<Double>(alpha.x, beta.x, gamma.x, delta.x)
        let rowY = SIMD4<Double>(alpha.y, beta.y, gamma.y, delta.y)
        let rowZ = SIMD4<Double>(alpha.z, beta.z, gamma.z, delta.z)
        
        // Build a 4x4 of parameter values to various powers
        let row1 = SIMD4<Double>(0.0, 0.0, 0.0, 1.0)
        
        let betaFraction2 = betaFraction * betaFraction
        let row2 = SIMD4<Double>(betaFraction * betaFraction2, betaFraction2, betaFraction, 1.0)
        
        let gammaFraction2 = gammaFraction * gammaFraction
        let row3 = SIMD4<Double>(gammaFraction * gammaFraction2, gammaFraction2, gammaFraction, 1.0)
        
        let row4 = SIMD4<Double>(1.0, 1.0, 1.0, 1.0)
        
        
        /// Intermediate collection for building the matrix
        var partial: [SIMD4<Double>]
        partial = [row1, row2, row3, row4]
        
        /// Matrix of t from several points raised to various powers
        let tPowers = double4x4(partial)
        
        let trans = tPowers.transpose   // simd representation is different than what I had in college
        
        
        /// Inverse of the above matrix
        let nvers = trans.inverse
        
        let coeffX = nvers * rowX
        let coeffY = nvers * rowY
        let coeffZ = nvers * rowZ
        
        
        // Set the curve coefficients
        self.ax = coeffX[0]
        self.bx = coeffX[1]
        self.cx = coeffX[2]
        self.dx = coeffX[3]
        self.ay = coeffY[0]
        self.by = coeffY[1]
        self.cy = coeffY[2]
        self.dy = coeffY[3]
        self.az = coeffZ[0]
        self.bz = coeffZ[1]
        self.cz = coeffZ[2]
        self.dz = coeffZ[3]
        
        
        self.usage = PenTypes.Ordinary
                
    }
    
    
    /// Attach new meaning to the curve.
    /// - See: 'testSetIntent' under CubicTests
    public func setIntent(purpose: PenTypes) -> Void  {
        self.usage = purpose
    }
    

    
    /// Fetch the location of an end.
    /// - See: 'getOtherEnd()'
    /// - See: 'testGetters' under CubicTests
    public func getOneEnd() -> Point3D   {
        return ptAlpha
    }
    
    /// Fetch the location of the opposite end.
    /// - See: 'getOneEnd()'
    /// - See: 'testGetters' under CubicTests
    public func getOtherEnd() -> Point3D   {
        return ptOmega
    }
    
    /// Don't use this!
    /// Flip the order of the end points (and control points).  Used to align members of a Loop.
    public func reverse() -> Void  {
        
        var bubble = self.ptAlpha
        self.ptAlpha = self.ptOmega
        self.ptOmega = bubble
        
        bubble = self.controlA!
        self.controlA! = controlB!
        controlB! = bubble
        
//        parameterizeBezier()
    }
    
    
    /// Supply the point on the curve for the input parameter value.
    /// Some notations show "u" as the parameter, instead of "t"
    /// - Parameters:
    ///   - t:  Curve parameter value.  Assumed 0 < t < 1.
    /// - Returns: Point location at the parameter value
    public func pointAt(t: Double) -> Point3D   {
        
        let t2 = t * t
        let t3 = t2 * t
        
        // This notation came from "Fundamentals of Interactive Computer Graphics" by Foley and Van Dam
        // Warning!  The relationship of coefficients and powers of t might be unexpected, as notations vary
        let myX = ax * t3 + bx * t2 + cx * t + dx
        let myY = ay * t3 + by * t2 + cy * t + dy
        let myZ = az * t3 + bz * t2 + cz * t + dz
        
        return Point3D(x: myX, y: myY, z: myZ)
    }
    
    /// Differentiate to find the tangent vector for the input parameter.
    /// Some notations show "u" as the parameter, instead of "t".
    /// - Parameters:
    ///   - t:  Curve parameter value.  Assumed 0 < t < 1.
    /// - Returns:  Non-normalized vector
    func tangentAt(t: Double) -> Vector3D   {
        
        let t2 = t * t
        
        // This is the component matrix differentiated once
        let myI = 3.0 * ax * t2 + 2.0 * bx * t + cx
        let myJ = 3.0 * ay * t2 + 2.0 * by * t + cy
        let myK = 3.0 * az * t2 + 2.0 * bz * t + cz
        
        return Vector3D(i: myI, j: myJ, k: myK)    // Notice that this is not normalized!
    }
    
    /// Break into 20 pieces and sum up the distances
    /// - Parameters:
    ///   - t:  Optional curve parameter value.  Assumed 0 < t < 1.
    /// - Returns: Double that is an approximate length
    /// Should bail if t = 0.0
    public func findLength(t: Double = 1.0) -> Double   {
        
        let pieces = 20
        let step = t / Double(pieces)
        
        var prevPoint = self.pointAt(t: 0.0)
        
        /// Running total
        var length = 0.0
        
        for g in 1...pieces   {
            
            let pip = self.pointAt(t: Double(g) * step)
            let hop = Point3D.dist(pt1: prevPoint, pt2: pip)
            length += hop
            
            prevPoint = pip
        }
        
        return length
    }
    
    
    
    /// Calculate the proper surrounding box
    /// Increase the number of intermediate points as necessary
    /// This same techniques could be used for other parametric curves
    public func getExtent() -> OrthoVol   {
        
        /// Number of check points along the curve
        let pieces = 15
        
        let step = 1.0 / Double(pieces)
        let limit = pieces - 1
        
        var bucketX = [Double]()
        var bucketY = [Double]()
        var bucketZ = [Double]()

        for u in 1...limit   {
            let pip = self.pointAt(t: Double(u) * step)
            bucketX.append(pip.x)
            bucketY.append(pip.y)
            bucketZ.append(pip.z)
        }
        
        bucketX.append(ptOmega.x)
        bucketY.append(ptOmega.y)
        bucketZ.append(ptOmega.z)

        var maxX = bucketX.reduce(ptAlpha.x, max)
        var minX = bucketX.reduce(ptAlpha.x, min)
                
        var maxY = bucketY.reduce(ptAlpha.y, max)
        var minY = bucketY.reduce(ptAlpha.y, min)
        
        var maxZ = bucketZ.reduce(ptAlpha.z, max)
        var minZ = bucketZ.reduce(ptAlpha.z, min)
        
        
        // Avoid the case of zero thickness
        let diffX = maxX - minX
        let diffY = maxY - minY
        let diffZ = maxZ - minZ
        
        let bigDiff = max(diffX, diffY, diffZ)
        
        /// Minimum thickness for the volume
        let minThick = 0.01 * bigDiff
        
        let skinny = min(diffX, diffY, diffZ)
        
           // Check if any direction is too thin
        if skinny < minThick   {
            
            switch skinny   {
                
            case diffX:
                maxX += 0.5 * minThick
                minX -= 0.5 * minThick
                
            case diffY:
                maxY += 0.5 * minThick
                minY -= 0.5 * minThick
                
            case diffZ:
                maxZ += 0.5 * minThick
                minZ -= 0.5 * minThick
                
            default:   // Never should get here
                maxZ += 0.5 * minThick
                minZ -= 0.5 * minThick
                
            }
            
        }
        
        
        let box = OrthoVol(minX: minX, maxX: maxX, minY: minY, maxY: maxY, minZ: minZ, maxZ: maxZ)
        
        return box
    }
    
    
//    /// Tweak the curve by changing one control point
//    /// - Parameters:
//    ///   - deltaX: Location change in X direction
//    ///   - deltaY: Location change in Y direction
//    ///   - deltaZ: Location change in Z direction
//    ///   - modA: Selector for which control point gets modified
//    public func modifyControlPoint(deltaX: Double, deltaY: Double, deltaZ: Double, modA: Bool) -> Void   {
//
//        if modA   {
//
//            self.controlA!.x += deltaX
//            self.controlA!.y += deltaY
//            self.controlA!.z += deltaZ
//
//        }  else  {
//
//            self.controlB!.x += deltaX
//            self.controlB!.y += deltaY
//            self.controlB!.z += deltaZ
//
//        }
//
//        parameterizeBezier()
//    }
//
//    /// Tweak a Bezier curve by changing an end point
//    /// - Parameters:
//    ///   - deltaX: Location change in X direction
//    ///   - deltaY: Location change in Y direction
//    ///   - deltaZ: Location change in Z direction
//    ///   - modAlpha: Selector for which control point gets modified
//    public func modifyEndPoint(deltaX: Double, deltaY: Double, deltaZ: Double, modAlpha: Bool) -> Void   {
//
//        if modAlpha   {
//
//            self.ptAlpha.x += deltaX
//            self.ptAlpha.y += deltaY
//            self.ptAlpha.z += deltaZ
//
//        }  else  {
//
//            self.ptOmega.x += deltaX
//            self.ptOmega.y += deltaY
//            self.ptOmega.z += deltaZ
//
//        }
//
//        parameterizeBezier()
//    }
    
    
    /// Find points spaced along the curve that do not exceed an allowable crown.
    /// Includes end points.
    /// Has not been copied to SketchGen.
    /// - Parameters:
    ///   - smallerT:  Lower limit on the curve
    ///   - largerT:  Upper limit on the curve
    ///   - allowableCrown:  Acceptable deviation from curve
    public func divide(smallerT: Double, largerT: Double, allowableCrown: Double) -> (param: [Double], spots: [Point3D])   {
        
        // Might want a guard statement to check relative values of inputs
        
        /// The array of parameters to be returned
        var tees = [Double]()
        
        /// The array of points to be returned
        var pips = [Point3D]()
        
        
        var upcomingTee = smallerT
        
        var hotTee: Double
        
        
        while upcomingTee < largerT  {
            
            hotTee = upcomingTee   // Update the independent variable
            
            tees.append(hotTee)
            pips.append(self.pointAt(t: hotTee))
            
            upcomingTee = findStep(allowableCrown: allowableCrown, currentT: hotTee, increasing: true)
        }
        
        tees.append(largerT)
        pips.append(self.pointAt(t: largerT))
        
        
        return (tees, pips)
    }
    
    
    /// Finds a higher parameter that meets the crown requirement.
    /// - Parameters:
    ///   - allowableCrown:  Acceptable deviation from curve
    ///   - currentT:  Present value of the driving parameter
    ///   - increasing:  Whether the change in parameter should be up or down
    /// - Returns: New value for driving parameter
    /// This needs testing for boundary conditions and the decreasing flag condition.
    public func findStep(allowableCrown: Double, currentT: Double, increasing: Bool) -> Double   {
        
        /// How quickly to refine the parameter guess
        let factor = 1.25
        
        /// Change in parameter - constantly refined.
        var step = 1.0 - currentT
        
        if !increasing   {
            step = -0.9999 * currentT   // I don't remember why that couldn't be -1.0
        }
        
        /// Working value of the parameter
        var trialT: Double
        
        /// Calculated crown
        var deviation: Double
        
        /// Counter to prevent loop runaway
        var safety = 0
        
        repeat   {
            
            if increasing   {
                trialT = currentT + step
                if currentT > (1.0 - step)   {   // Prevent parameter value > 1.0
                    trialT = 1.0
                }
            }  else {
                trialT = currentT - step
                if currentT < step   {   // Prevent parameter value < 0.0
                    trialT = 0.0
                }
            }
            
            deviation = self.findCrown(smallerT: currentT, largerT: trialT)

            step = step / factor     // Prepare for the next iteration
            safety += 1
            
        }  while deviation > allowableCrown  && safety < 12    // Fails ugly!
        // TODO: Throw a ConvergenceError here if safety > 11
        
        return trialT
    }
    
    
    /// Calculate the crown over a small segment.
    /// Works even with the smaller and larger values reversed.
    /// - Parameters:
    ///   - smallerT:  One location on the curve
    ///   - largerT:  One location on the curve.
    /// - Returns: Maximum distance away from line between ends
    public func findCrown(smallerT: Double, largerT: Double) -> Double   {
        
        /// Number of divisions to generate and check
        var count = 20
        
        /// Parameter difference
        let deltaTee = largerT - smallerT
        
        let cents = Int(round(abs(deltaTee) * 100.0))
        
        if cents > 20   {
            count = cents
        }
        
        
        let step = deltaTee / Double(count)
        
        /// Points along the curve
        var crownDots = [Point3D]()
        
        let anchorA = self.pointAt(t: smallerT)
        crownDots.append(anchorA)
        
        for g in 1...count - 1   {
            
            let pip = self.pointAt(t: smallerT + Double(g) * step)
            crownDots.append(pip)
        }
        
        let anchorB = self.pointAt(t: largerT)
        crownDots.append(anchorB)
        
        let deviation = Cubic.crownCalcs(dots: crownDots)
        return deviation
    }
    
    
    
    
    /// Find the position of a point relative to the curve and its origin.
    /// Useless result at the moment.
    /// - Parameters:
    ///   - speck:  Point near the curve.
    /// - Returns: Tuple of Vector components relative to the origin
    /// - SeeAlso:  resolveRelativeNum()
    public func resolveRelativeVec(speck: Point3D) -> (along: Vector3D, perp: Vector3D)   {
        
//        let otherSpeck = speck
        
        let alongVector = Vector3D(i: 1.0, j: 0.0, k: 0.0)
        
        let perpVector = Vector3D(i: 0.0, j: 1.0, k: 0.0)
        
        return (alongVector, perpVector)
    }
    
    /// - Parameters:
    ///   - speck:  Point near the curve.
    /// - Returns: Tuple of distances relative to the start of the curve.
    /// - SeeAlso:  resolveRelative()
    public func resolveRelative(speck: Point3D) -> (along: Double, away: Double)   {
        
        let onCurve = findClosest(speck: speck)
        
        let distanceAlong = self.findLength(t: onCurve.param)
        let sep = Point3D.dist(pt1: onCurve.pip, pt2: speck)
        
        return (distanceAlong, sep)
    }
    
    
    /// Create a new curve translated, scaled, and rotated by the matrix.
    /// - Parameters:
    ///   - xirtam: Matrix containing translation, rotation, and scaling to be applied
    /// - See: 'testTransform' under CubicTests
    public func transform(xirtam: Transform) -> PenCurve   {
        
        let tAlpha = Point3D.transform(pip: self.ptAlpha, xirtam: xirtam)
        let tOmega = Point3D.transform(pip: self.ptOmega, xirtam: xirtam)
        
        let tControlA = Point3D.transform(pip: self.controlA!, xirtam: xirtam)
        let tControlB = Point3D.transform(pip: self.controlB!, xirtam: xirtam)
        
        let fresh = try! Cubic(ptA: tAlpha, controlA: tControlA, controlB: tControlB, ptB: tOmega)
        fresh.setIntent(purpose: self.usage)   // Copy setting instead of having the default
        
        return fresh
    }
    
    
    /// Find the range of the parameter where the point is closest to the curve.
    /// - Parameters:
    ///   - speck:  Target point
    ///   - span:  A range of the curve parameter t in which to hunt
    /// - Returns: A smaller ClosedRange<Double>.
    /// - See: 'testResolve' under CubicTests
    public func refineRangeDist(speck: Point3D, span: ClosedRange<Double>) -> ClosedRange<Double>?   {
        
        /// Number of pieces to divide range
        let chunks = 10
        
        /// The possible return value
        var tighter: ClosedRange<Double>
        
        
        /// Parameter step
        let parStep = (span.upperBound - span.lowerBound) / Double(chunks)
        
        /// Array of equally spaced parameter values within the range.
        var params = [Double]()
        
        for g in 0...chunks   {
            let freshT = span.lowerBound + Double(g) * parStep
            params.append(freshT)
        }
        
        /// Array of separations
        let seps = params.map{ Point3D.dist(pt1: self.pointAt(t: $0), pt2: speck) }
        
        /// Smallest distance
        let close = seps.min()!
        
        /// Index of smallest distance
        let thumb = seps.firstIndex(of: close)!
        
        switch thumb   {
            
        case 0:  tighter = ClosedRange<Double>(uncheckedBounds: (lower: params[0], upper: params[1]))
            
        case seps.count - 1:  tighter = ClosedRange<Double>(uncheckedBounds: (lower: params[seps.count - 2], upper: params[seps.count - 1]))
            
        default:  tighter = ClosedRange<Double>(uncheckedBounds: (lower: params[thumb - 1], upper: params[thumb + 1]))
            
        }
        
        return tighter
    }
    
    
    /// Find the closest point on the curve.
    /// Should be modified to pass back the parameter as well.
    /// - Parameters:
    ///   - speck:  Target point
    ///   - accuracy:  Optional - How close is close enough?
    /// - Returns: A nearby Point3D on the curve.
    /// - SeeAlso:  refineRangeDist()
    /// - See: 'testFindClosest' under CubicTests
    public func findClosest(speck: Point3D, accuracy: Double = Point3D.Epsilon) -> (pip: Point3D, param: Double)   {
        
        var priorPt = self.pointAt(t: 0.5)
        
        /// Separation between last and current iterations.
        var sep = Double.greatestFiniteMagnitude
        
        var curRange = ClosedRange<Double>(uncheckedBounds: (lower: 0.0, upper: 1.0))
        
        /// Working point through the iterations.
        var midRange: Double
        
        /// A counter to prevent a runaway loop
        var tally = 0
        
        repeat   {
            
            let refinedRange = self.refineRangeDist(speck: speck, span: curRange)
            
            midRange = ((refinedRange?.lowerBound)! + (refinedRange?.upperBound)!) / 2.0
            let midPt = self.pointAt(t: midRange)
            
            sep = Point3D.dist(pt1: priorPt, pt2: midPt)
            
            priorPt = midPt   // Set up for the next iteration
            curRange = refinedRange!
            tally += 1
            
        } while sep > accuracy  && tally < 7   // Fails ugly for the second clause!
        
        return (priorPt, midRange)
    }
    
    
    /// Find the average error for an Array of points
    public func rootSumSquares(dots: [Point3D]) -> Double   {
        
        /// Separations
        var deltas = [Double]()
        
        for spot in dots   {
            
            /// Nearest point on the curve
            let buddy = self.findClosest(speck: spot)
            
            /// Distance between this pair
            let sep = Point3D.dist(pt1: buddy.pip, pt2: spot)
            
            deltas.append(sep)
        }
        
        let totalErr = deltas.reduce(0.0, +)
        
        let avg = totalErr / Double(deltas.count)
        
        return avg
    }
    
    
    /// Find the range of the parameter where the curve crosses a line.
    /// This is part of finding the intersection.
    /// What should the access level be?
    /// Should the be rewritten as a static function to allow parallel processing?
    /// - Parameters:
    ///   - ray:  The Line to be used in testing for a crossing
    ///   - span:  A range of the curve parameter t in which to hunt
    /// - Returns: A smaller ClosedRange<Double>.
    func crossing(ray: Line, span: ClosedRange<Double>) -> ClosedRange<Double>?   {
        
        /// Number of pieces to divide range
        let chunks = 5
        
        /// The possible return value
        var tighter: ClosedRange<Double>
        
        /// Point at the beginning of the range
        let green = self.pointAt(t: span.lowerBound)
        
        /// Vector from start of Line to point at beginning of range
        let bridgeVec = Vector3D.built(from: ray.getOrigin(), towards: green)
        
        /// Components of bridge along and perpendicular to the Line
        let bridgeComps = ray.resolveRelativeVec(arrow: bridgeVec)
        
        /// Normalized vector in the direction from the Line origin to the curve start
        var ref = bridgeComps.perp
        
        if !ref.isZero()   {
            ref.normalize()
        }
        
        /// Parameter step
        let parStep = (span.upperBound - span.lowerBound) / Double(chunks)
        
        /// Recent value of parameter
        var previousT = span.lowerBound
        
        
        for g in 1...chunks   {
            
            let freshT = span.lowerBound + Double(g) * parStep
            
            let pip = self.pointAt(t: freshT)
            
            let bridge = Vector3D.built(from: ray.getOrigin(), towards: pip)
            
            let components = ray.resolveRelativeVec(arrow: bridge)
            
            /// Non-normalized vector in the direction from the Line origin to the current point
            let hotStuff = components.perp

            /// Length of "hotStuff" when projected to the reference vector
            let projection = Vector3D.dotProduct(lhs: hotStuff, rhs: ref)
            
            if projection < 0.0   {   // Opposite of the reference, so a crossing was just passed
                tighter = ClosedRange<Double>(uncheckedBounds: (lower: previousT, upper: freshT))
                return tighter   // Bails after the first crossing found, even if there happen to be more
            }  else  {
                previousT = freshT   // Prepare for checking the next interval
            }
        }
        
        return nil
    }
    
    /// Intersection points with a line.
    /// Needs to become a thread safe function.
    /// - Parameters:
    ///   - ray:  The Line to be used for intersecting
    ///   - accuracy:  Optional - How close is close enough?
    /// - Returns: Array of points common to both curves - though for now it will return only the first one
    /// - SeeAlso:  crossing()
    /// - See: 'testIntLine1' and 'testIntLine2' under CubicTests
    public func intersect(ray: Line, accuracy: Double = Point3D.Epsilon) -> [Point3D] {
        
        /// The return array
        var crossings = [Point3D]()
        
        /// Whether or not a crossing has been found
        var crossed = false
        
        /// Separation in points for the given range of parameter t
        var sep = self.findLength()
        
        var middle = Point3D(x: -1.0, y: -1.0, z: -1.0)   // Dummy value
        
        
        /// Interval in parameter space for hunting
        var shebang = ClosedRange<Double>(uncheckedBounds: (lower: 0.0, upper: 1.0))
        
        repeat   {
            
            if let refined = self.crossing(ray: ray, span: shebang)   {
                
                let low = self.pointAt(t: refined.lowerBound)
                let high = self.pointAt(t: refined.upperBound)
                sep = Point3D.dist(pt1: low, pt2: high)
                
                middle = Point3D.midway(alpha: low, beta: high)
                crossed = true
                shebang = refined    // Make the checked range narrower
                
            }
            
        } while crossed  &&  sep > accuracy
        
        if sep <= accuracy   {
            crossings.append(middle)
        }
        
        return crossings
    }
    

    
    /// Generate even parameter values.
    /// Needs to be copied to SketchCurves
    /// - Parameters:
    ///   - divs: Number of intervals
    /// - Returns: divs + 1 parameter values
    public static func splitParam(divs: Int) -> [Double]   {
        
        let paramStep = 1.0 / Double(divs)
        
        /// Evenly split parameter values
        var pins = [Double]()
        
        pins.append(0.0)
        
        for g in 1..<divs   {
            let pad = Double(g) * paramStep
            pins.append(pad)
        }
        
        pins.append(1.0)
        
        return pins
    }
    
    
    /// Caluclate deviation from a LineSeg
    /// - Parameters:
    ///   - dots:  Array of Point3D.  Order is assumed.
    /// - Returns: Maximum separation.
    /// Does not check for an Array length < 3
    public static func crownCalcs(dots: [Point3D]) -> Double   {
        
        let bar = try! LineSeg(end1: dots.first!, end2: dots.last!)
        
        let seps = dots.map( { bar.resolveRelative(speck: $0).away } )
        let curCrown = seps.max()!
        
        return curCrown
    }
    
    

    /// Plot the curve segment.  This will be called by the UIView 'drawRect' function
    /// - Parameters:
    ///   - context: In-use graphics framework
    ///   - tform:  Model-to-display transform
    public func draw(context: CGContext, tform: CGAffineTransform) -> Void  {
        
        var xCG: CGFloat = CGFloat(self.dx)    // Convert to "CGFloat", and throw out Z coordinate
        var yCG: CGFloat = CGFloat(self.dy)
        
        let startModel = CGPoint(x: xCG, y: yCG)
        let screenStart = startModel.applying(tform)
        
        context.move(to: screenStart)
        
        
        let pieces = 20   // This really should depend on the curvature
        let step = 1.0 / Double(pieces)
        
        for g in 1...pieces   {
            
            let stepU = Double(g) * step
            let mid = pointAt(t: stepU)
            xCG = CGFloat(mid.x)
            yCG = CGFloat(mid.y)
            
            let midPoint = CGPoint(x: xCG, y: yCG)
            let midScreen = midPoint.applying(tform)
            
            context.addLine(to: midScreen)
        }
        
        context.strokePath()
        
    }
    
    
    /// Draw symbols to be used in manipulating the curve.
    /// - Parameters:
    ///   - context: In-use graphics framework
    ///   - tform:  Model-to-display transform
    public func drawControls(context: CGContext, tform: CGAffineTransform) -> Void  {
        
        let boxDim = 8.0
        let boxSize = CGSize(width: boxDim, height: boxDim)
        
        if controlA != nil   {
            
            var xCG = CGFloat(controlA!.x)
            var yCG = CGFloat(controlA!.y)
            var leader1 = CGPoint(x: xCG, y: yCG).applying(tform)
            
            context.move(to: leader1)
            
            xCG = CGFloat(ptAlpha.x)
            yCG = CGFloat(ptAlpha.y)
            var leader2 = CGPoint(x: xCG, y: yCG).applying(tform)
            
            context.addLine(to: leader2)
            
            
            xCG = CGFloat(controlB!.x)
            yCG = CGFloat(controlB!.y)
            leader1 = CGPoint(x: xCG, y: yCG).applying(tform)
            
            context.move(to: leader1)
            
            xCG = CGFloat(ptOmega.x)
            yCG = CGFloat(ptOmega.y)
            leader2 = CGPoint(x: xCG, y: yCG).applying(tform)
            context.addLine(to: leader2)
            
            context.strokePath()
            
            // Do these last, so that the box will obscure the leader end
            xCG = CGFloat(controlA!.x)
            yCG = CGFloat(controlA!.y)
            var boxCenter = CGPoint(x: xCG, y: yCG).applying(tform)
            var boxOrigin = CGPoint(x: boxCenter.x - CGFloat(boxDim / 2.0), y: boxCenter.y - CGFloat(boxDim / 2.0))
            var controlBox = CGRect(origin: boxOrigin, size: boxSize)
            context.fill(controlBox)
            
            xCG = CGFloat(controlB!.x)
            yCG = CGFloat(controlB!.y)
            boxCenter = CGPoint(x: xCG, y: yCG).applying(tform)
            boxOrigin = CGPoint(x: boxCenter.x - CGFloat(boxDim / 2.0), y: boxCenter.y - CGFloat(boxDim / 2.0))
            controlBox = CGRect(origin: boxOrigin, size: boxSize)
            context.fill(controlBox)
            
            xCG = CGFloat(ptAlpha.x)
            yCG = CGFloat(ptAlpha.y)
            boxCenter = CGPoint(x: xCG, y: yCG).applying(tform)
            boxOrigin = CGPoint(x: boxCenter.x - CGFloat(boxDim / 2.0), y: boxCenter.y - CGFloat(boxDim / 2.0))
            controlBox = CGRect(origin: boxOrigin, size: boxSize)
            context.fill(controlBox)
            
            xCG = CGFloat(ptOmega.x)
            yCG = CGFloat(ptOmega.y)
            boxCenter = CGPoint(x: xCG, y: yCG).applying(tform)
            boxOrigin = CGPoint(x: boxCenter.x - CGFloat(boxDim / 2.0), y: boxCenter.y - CGFloat(boxDim / 2.0))
            controlBox = CGRect(origin: boxOrigin, size: boxSize)
            context.fill(controlBox)
            
        }
        
    }
        
    
}
