//
//  InvoluteCurve.swift
//  SurfTooth
//
//  Created by Paul on 9/10/16.
//  Copyright © 2018 Ceran Digital Media. All rights reserved.
//

import Foundation

/// Curve generated from an Arc.  The basis for meshing teeth on a gear.
/// Assumes that the center is 0.0, 0.0, 0.0  and that construction is in the XY plane.
/// Unit tests would be good!
public struct Involute   {
    
    var baseRadius: Double   // Figure 11-10 in Shigley is helpful

    
    /// See a different class for generating the entire tooth.
    init(baseRadius: Double)   {
        
        self.baseRadius = baseRadius
        
    }
    
    
    /// Determines a point on an involute curve.
    /// See Figure 11.6 of Shigley
    /// - Parameters:
    ///   - angle: Direction of generating ray for this point on the involute (radians).
    /// - Returns: Single point
    /// - SeeAlso: 'angleForRadius()'
    public func pointAtAngle(angle: Double) -> Point3D   {
        
        /// Circle center.  Transform the result if necessary.
        let center = Point3D(x: 0.0, y: 0.0, z: 0.0)
        
        /// From the center towards the tangent point
        let rayVec = Vector3D(i: cos(angle), j: sin(angle), k: 0.0)
        
        /// Point on the base circle at the specified angle
        let tangentPt = Point3D.offset(pip: center, jump: rayVec * self.baseRadius)
        
        
        /// This uses the assumption that the curve is in the XY plane
        let Axis = Vector3D(i: 0.0, j: 0.0, k: 1.0)
        
        /// Direction perpendicular to the ray
        var cordVec = try! Vector3D.crossProduct(lhs: rayVec, rhs: Axis)
        cordVec.normalize()
        
        /// How much has been unwound
        let cordLength = angle * self.baseRadius
        
        /// The point on the involute curve and the return value
        let toothPoint = Point3D.offset(pip: tangentPt, jump: cordVec * cordLength)
        
        return toothPoint
    }
   
    
    
    /// Determine the location of a point for an input radius.
    /// Brute force convergence.
    /// - Parameters:
    ///   - targetR: Input radius.  Needs to be larger than the base radius.
    ///   - epsilon: Acceptable accuracy
    /// - Returns: Angle (radians) that generated the point
    /// - SeeAlso: 'pointAtAngle()'
    public func angleForRadius(targetR: Double, epsilon: Double) -> Double   {
        
        /// Circle center
        let center = Point3D(x: 0.0, y: 0.0, z: 0.0)
        
        
        let initialStepSize = 0.005
        
        var stepSize = initialStepSize
        
        var trialAngle = 0.0   // Gets changed at the top of the inner loop
        
        
        /// Boolean to indicate if delta is less than epsilon
        var closeEnough  = false
        
        /// Condition of previous error
        var lastDeltaPositive = false
        
        
           // Assumes that the starting point is less than the desired value
        
        repeat   {   // This has no backstop to keep it from running endlessly
            
            /// Qualitative condition of sequential errors
            var deltaIdentical: Bool
            
            repeat   {
                
                trialAngle += stepSize
                
                let jab = pointAtAngle(angle: trialAngle)   // This and the two following lines are the objective function
                let trialR = Point3D.dist(pt1: center, pt2: jab)
                let delta = trialR - targetR
                
                if abs(delta) < epsilon   {
                    closeEnough = true
                    break
                }
                
                let deltaPositive = delta > 0.0
                
                deltaIdentical = lastDeltaPositive && deltaPositive  || !lastDeltaPositive && !deltaPositive
                
                // Prepare for the next iteration
                lastDeltaPositive = deltaPositive
                
            } while deltaIdentical  && trialAngle < 1.0
            

            stepSize = stepSize / -2.0   // Reduce and reverse step
            
        } while !closeEnough
        
        return trialAngle
    }

    /// Generate a vector perpendicular to the curve at the input angle.
    /// Used for generating a fillet.
    /// Is there a more elegant way to do this?
    /// - Parameters:
    ///   - angle: Direction of generating ray for this point on the involute (radians).
    /// - Returns: Point at that angle, plus a unit perpendicular vector
    public func normalAtAngle(angle: Double) -> (loc: Point3D, dir: Vector3D)   {
        
        let anchorPoint = self.pointAtAngle(angle: angle)
        
        let tinyDelta = 0.005   // Too small of a value here will generate a zero vector for fauxTangent
        
        let beforePoint = self.pointAtAngle(angle: angle - tinyDelta)
        let afterPoint = self.pointAtAngle(angle: angle + tinyDelta)
        
        let fauxTangent = Vector3D.built(from: beforePoint, towards: afterPoint, unit: true)
        
        let positiveZ = Vector3D(i: 0.0, j: 0.0, k: 1.0)
        
        var perpAway = try! Vector3D.crossProduct(lhs: fauxTangent, rhs: positiveZ)
        perpAway.normalize()
        
        return (anchorPoint, perpAway)
    }
    
    
    /// Create only enough points to meet the crown limit
    /// - Parameters:
    ///   - startAngle: In radians
    ///   - finishAngle: In radians
    ///   - allowableCrown:  Maximum deviation from the true curve
    /// - Returns: Array of points approximating the curves
    public func approximate(startAngle: Double, finishAngle: Double, allowableCrown: Double) -> [Point3D]   {

        /// The accumulated points to be returned to represent the curve.
        var chain = [Point3D]()

        chain.append(self.pointAtAngle(angle: startAngle))
        

        /// Generating angle
        var genAngle = startAngle
        
        repeat   {   // Points will not be evenly spaced

            let middle = try! pointByCrown(lastAngle: genAngle, allowableCrown: allowableCrown)
            genAngle = middle.theta

            if genAngle < finishAngle   {
                chain.append(middle.pip)
            }

        } while genAngle < finishAngle

        let finalPt = pointAtAngle(angle: finishAngle)
        chain.append(finalPt)

        return chain
    }


    /// Find the next point on the curve that does not violate the allowable crown
    /// - Parameters:
    ///   - lastAngle: Generating angle (radians) for the last stepping stone
    ///   - allowableCrown: Acceptable deviation from the curve
    /// - Returns: Point and angle (radians) on the generating circle
    public func pointByCrown(lastAngle: Double, allowableCrown: Double) throws -> (pip: Point3D, theta: Double)   {

        guard allowableCrown > 0.0 else { throw NegativeAccuracyError(acc: allowableCrown) }
            
        let angleStep = 0.05   // Arbitrary value


        /// Set of points from the curve
        var ptSeq = [Point3D]()

        /// Anchor point for calculating crown
        let basePoint = pointAtAngle(angle: lastAngle)
        ptSeq.append(basePoint)


        /// Generating angle for another point
        var trialAngle = lastAngle + angleStep

        let secondPoint = pointAtAngle(angle: trialAngle)
        ptSeq.append(secondPoint)


        var curCrown: Double

        repeat   {

            trialAngle += angleStep

            let freshPoint = pointAtAngle(angle: trialAngle)
            ptSeq.append(freshPoint)

            curCrown = try! Cubic.crownCalcs(dots: ptSeq)

        }  while curCrown < allowableCrown

        let lastGoodAngle = trialAngle - angleStep

        /// A point where a line segment will not violate the crown parameter
        let nextStone = pointAtAngle(angle: lastGoodAngle)

        return (nextStone, lastGoodAngle)
    }
    
}
