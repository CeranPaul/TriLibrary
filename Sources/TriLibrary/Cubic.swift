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
    /// The assignment statements come from an algebraic manipulation of the equations
    /// in the Wikipedia article on Cubic Hermite spline.
    /// - Parameters:
    ///   - ptA: First end point
    ///   - slopeA: Slope that goes with the first end point
    ///   - ptB: Other end point
    ///   - slopeB: Slope that goes with the second end point
    /// There are checks here for input points that should be added!
    /// - Throws:
    ///     - ZeroVectorError if either of the slopes aren't good
    ///     - CoincidentPointsError for problems with ptA and ptB
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
    /// - Throws:
    ///     - CoincidentPointsError if the inputs are lame
    /// - See: 'testSumsBezier' under CubicTests
    public init(ptA: Point3D, controlA: Point3D, controlB: Point3D, ptB: Point3D) throws   {
        
        let pool = [ptA, controlA, controlB, ptB]
        guard Point3D.isUniquePool(flock: pool) else { throw CoincidentPointsError(dupePt: ptA)}
        
        // TODO: Then add tests to see that the guard statements are doing their job
        
        self.ptAlpha = ptA
        self.ptOmega = ptB
                
        
        self.ax = 3.0 * controlA.x - self.ptAlpha.x - 3.0 * controlB.x + self.ptOmega.x
        self.bx = 3.0 * self.ptAlpha.x - 6.0 * controlA.x + 3.0 * controlB.x
        self.cx = 3.0 * controlA.x - 3.0 * self.ptAlpha.x
        self.dx = self.ptAlpha.x
        
        self.ay = 3.0 * controlA.y - self.ptAlpha.y - 3.0 * controlB.y + self.ptOmega.y
        self.by = 3.0 * self.ptAlpha.y - 6.0 * controlA.y + 3.0 * controlB.y
        self.cy = 3.0 * controlA.y - 3.0 * self.ptAlpha.y
        self.dy = self.ptAlpha.y
        
        self.az = 3.0 * controlA.z - self.ptAlpha.z - 3.0 * controlB.z + self.ptOmega.z
        self.bz = 3.0 * self.ptAlpha.z - 6.0 * controlA.z + 3.0 * controlB.z
        self.cz = 3.0 * controlA.z - 3.0 * self.ptAlpha.z
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
    /// - Throws:
    ///     - ParameterRangeError if one of the fractions is lame
    ///     - CoincidentPointsError if they are not unique
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
    
    /// Supply the point on the curve for the input parameter value.
    /// Some notations show "u" as the parameter, instead of "t"
    /// - Parameters:
    ///   - t:  Curve parameter value.  Assumed 0 < t < 1.
    /// - Returns: Point location at the parameter value
    /// - Throws:
    ///     - ParameterRangeError if the input is lame
    /// - See: 'testPointAt' under CubicTests
    public func pointAt(t: Double) throws -> Point3D   {
        
        guard self.parameterRange.contains(t) else { throw ParameterRangeError(parA: t) }
        
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
    /// - Throws:
    ///     - ParameterRangeError if the input is lame
    /// - See: 'testTangentAt' under CubicTests
    func tangentAt(t: Double) throws -> Vector3D   {
        
        guard self.parameterRange.contains(t) else { throw ParameterRangeError(parA: t) }
        
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
        
        var prevPoint = try! self.pointAt(t: 0.0)
        
        /// Running total
        var length = 0.0
        
        for g in 1...pieces   {
            
            let pip = try! self.pointAt(t: Double(g) * step)
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
            let pip = try! self.pointAt(t: Double(u) * step)
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
    
    
    /// Find the curve's closest point.
    /// - Parameters:
    ///   - nearby:  Target point
    ///   - accuracy:  Optional - What iteration change is close enough?
    /// - Returns: A nearby Point3D on the curve, and its parameter.
    /// - SeeAlso:  refineRangeDist()
    /// - Throws:
    ///     - CovergenceError if iterations fail
    ///     - NegativeAccuracyError for a bad input
    /// - See: 'testFindClosest' under CubicTests
    public func findClosest(nearby: Point3D, accuracy: Double = Point3D.Epsilon) throws -> (pip: Point3D, param: Double)   {
        
        guard accuracy > 0.0 else { throw NegativeAccuracyError(acc: accuracy) }
            
        /// Working value for nearest point
        var priorPt = try! self.pointAt(t: 0.5)
        
        /// Separation between current iteration and previous iteration.
        var successiveSep = Double.greatestFiniteMagnitude   // Starting value
        
        /// Working value for interval on the curve being checked
        var curRange = self.parameterRange
        
        /// Working parameter through the iterations, and part of the return tuple.
        var midRangeParameter: Double = 0.5
        
        /// A counter to prevent a runaway loop
        var tally = 0
        
        repeat   {
            
            if let refinedRange = try self.refineRangeDist(nearby: nearby, span: curRange)  {
                
                midRangeParameter = (refinedRange.lowerBound + refinedRange.upperBound) / 2.0
                let midPt = try! self.pointAt(t: midRangeParameter)
                
                successiveSep = Point3D.dist(pt1: priorPt, pt2: midPt)
                
                priorPt = midPt   // Set up for the next iteration
                curRange = refinedRange
            }
            
            tally += 1
            
            if tally > 6 { throw ConvergenceError(tnuoc: tally) }
            
        } while successiveSep > accuracy  && tally < 7   // Fails ugly for the second clause!
        
        return (priorPt, midRangeParameter)
    }
    
    
    /// Find the range of the parameter where the point is closest to the curve.
    /// - Parameters:
    ///   - nearby:  Target point
    ///   - span:  A range of the curve parameter t in which to hunt
    /// - Returns: A smaller ClosedRange<Double>.
    /// - Throws:
    ///     - ParameterRangeError if either end of  the span input is lame
    /// - See: 'testResolve' under CubicTests
    public func refineRangeDist(nearby: Point3D, span: ClosedRange<Double>) throws -> ClosedRange<Double>?   {
        
        // Would be good to check that 'span' is a valid range.
        guard self.parameterRange.contains(span.lowerBound) else { throw ParameterRangeError(parA: span.lowerBound)}
        
        guard self.parameterRange.contains(span.upperBound) else { throw ParameterRangeError(parA: span.upperBound)}
        
        /// Number of pieces to divide range
        let chunks = 10
        
        /// The return value
        var tighter: ClosedRange<Double>? = nil
        
        
        /// Parameter step
        let parStep = (span.upperBound - span.lowerBound) / Double(chunks)
        
        /// Array of equally spaced parameter values within the range.
        var params = [Double]()
        
        for g in 0...chunks   {
            let freshT = span.lowerBound + Double(g) * parStep
            params.append(freshT)
        }
        
        /// Array of separations
        let seps = params.map{ Point3D.dist(pt1: nearby, pt2: try! self.pointAt(t: $0)) }
        
        /// Smallest distance
        if let closest = seps.min()   {
            
            /// Index of smallest distance
            if let thumb = seps.firstIndex(of: closest)   {
                
                switch thumb   {
                    
                    // First subrange
                case 0:  tighter = ClosedRange<Double>(uncheckedBounds: (lower: params[0], upper: params[1]))
                    
                    // Last subrange
                case seps.count - 1:  tighter = ClosedRange<Double>(uncheckedBounds: (lower: params[seps.count - 2], upper: params[seps.count - 1]))
                    
                    // General case
                default:  tighter = ClosedRange<Double>(uncheckedBounds: (lower: params[thumb - 1], upper: params[thumb + 1]))
                    
                }
                
            }
            
        }
        
        return tighter
    }
    
    
    /// Caluclate deviation from a LineSeg
    /// - Parameters:
    ///   - dots:  Array of Point3D.  Order is assumed.
    /// - Returns: Maximum separation.
    /// Does not check for an Array length < 3
    public static func crownCalcs(dots: [Point3D]) throws -> Double   {
        
        guard dots.count > 2 else { throw TinyArrayError(tnuoc: dots.count)}
        
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
        
        let xCG: CGFloat = CGFloat(self.dx)    // Build the starting point from the raw parameters
        let yCG: CGFloat = CGFloat(self.dy)
        
        let startModel = CGPoint(x: xCG, y: yCG)
        let screenStart = startModel.applying(tform)
        
        context.move(to: screenStart)
        
        
        let pieces = 20   // This really should depend on the curvature
        let step = 1.0 / Double(pieces)
        
        for g in 1...pieces   {
            
            let stepU = Double(g) * step
            let mid = try! pointAt(t: stepU)
            
            let midPoint = Point3D.makeCGPoint(pip: mid)    // Throw out Z coordinate
            let screenMid = midPoint.applying(tform)
            
            context.addLine(to: screenMid)
        }
        
        context.strokePath()
        
    }
    
}
