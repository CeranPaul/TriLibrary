//
//  Point3D.swift
//  SurfaceCrib
//
//  Created by Paul on 8/11/15.
//  Copyright © 2018 Ceran Digital Media. All rights reserved.  See LICENSE.md
//

import Foundation

/// Simple representation of a position in space by the use of three orthogonal coordinates.
public struct Point3D: Hashable {
    
    var x: Double    // Eventually these should be set as private?
    var y: Double
    var z: Double

    
    /// Threshhold of separation for equality checks
    public static var Epsilon: Double = 0.0001
    
    
    /// The simplest and only initializer.  Needed because a default initializer has 'internal' access level.
    /// - See: 'testFidelity' under Point3DTests
    public init(x: Double, y: Double, z: Double)   {
        self.x = x
        self.y = y
        self.z = z
    }
    
    
    /// Generate the unique value using Swift 4.2 tools
    /// Is a required func for a subclass of Hashable
    /// - See: 'testHashValue' under Point3DTests
    public func hash(into hasher: inout Hasher)   {
        
        let divX = self.x / Point3D.Epsilon
        let myX = Int(round(divX))
        
        let divY = self.y / Point3D.Epsilon
        let myY = Int(round(divY))
        
        let divZ = self.z / Point3D.Epsilon
        let myZ = Int(round(divZ))
        
        hasher.combine(myX)
        hasher.combine(myY)
        hasher.combine(myZ)
        
    }

    
    /// Create a new point by offsetting
    /// - Parameters:
    ///   - jump:  Vector to be used as the offset
    /// - See: 'testOffset' under Point3DTests
    /// - SeeAlso:  transform
    public static func offset (pip: Point3D, jump: Vector3D) -> Point3D   {
        
        let totalX = pip.x + jump.i
        let totalY = pip.y + jump.j
        let totalZ = pip.z + jump.k
    
        return Point3D(x: totalX, y: totalY, z: totalZ)
    }
    
    /// Move, rotate, and/or scale by a matrix
    /// - Parameters:
    ///   - xirtam:  Matrix for the intended transformation
    /// - SeeAlso:  offset
    public func transform(xirtam: Transform) -> Point3D {
        
        let pip4 = RowMtx4(valOne: self.x, valTwo: self.y, valThree: self.z, valFour: 1.0)
        let tniop4 = pip4 * xirtam
        
        let transformed = tniop4.toPoint()
        return transformed
    }
    
    
    
    /// Flip point to the opposite side of the plane
    /// - Parameters:
    ///   - flat:  Mirroring plane
    ///   - pip:  Point to be flipped
    /// - Returns: New point
    /// - See: 'testMirrorPoint' under PlaneTests
    public static func mirror(flat: Plane, pip: Point3D) -> Point3D   {
        
        /// Vector components from the Plane origin
        let comps = Plane.resolveRelativeVec(flat: flat, pip: pip)
        
        /// Vector to apply to the original point
        let jump = comps.perp * -2.0
        
        ///New point from mirroring
        let fairest = Point3D.offset(pip: pip, jump: jump)
        
        return fairest
    }
    
    
    /// Calculate the distance between two of 'em
    /// - Parameters:
    ///   - pt1:  One point
    ///   - pt2:  Another point
    /// - See: 'testDist' under Point3DTests
    public static func dist(pt1: Point3D, pt2: Point3D) -> Double   {
        
        let deltaX = pt2.x - pt1.x
        let deltaY = pt2.y - pt1.y
        let deltaZ = pt2.z - pt1.z
        
        let sum = deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ
        
        return sqrt(sum)
    }
    
    /// Create a point midway between two others
    /// - Parameters:
    ///   - alpha:  One boundary
    ///   - beta:  The other boundary
    /// - See: 'testMidway' under Point3DTests
    public static func midway(alpha: Point3D, beta: Point3D) -> Point3D   {
        
        return Point3D(x: (alpha.x + beta.x) / 2.0, y: (alpha.y + beta.y) / 2.0, z: (alpha.z + beta.z) / 2.0)
    }
    
    /// Determine the angle (in radians) CCW from the positive X axis in the XY plane
    public static func angleAbout(ctr: Point3D, tniop: Point3D) -> Double  {
        
        let vec1 = Vector3D.built(from: ctr, towards: tniop)    // No need to normalize
        var ang = atan(vec1.j / vec1.i)
        
        if vec1.i < 0.0   {
            
            if vec1.j < 0.0   {
                ang = ang - Double.pi
            }  else  {
                ang = ang + Double.pi
            }
        }
        
        return ang
    }
    
    /// Check if three points are not duplicate.  Useful for building triangles, or defining arcs
    /// - Parameters:
    ///   - alpha:  A test point
    ///   - beta:  Another test point
    ///   - gamma:  The final test point
    /// - See: 'testIsThreeUnique' under Point3DTests
    public static func  isThreeUnique(alpha: Point3D, beta: Point3D, gamma: Point3D) -> Bool   {
        
        let flag1 = alpha != beta
        let flag2 = alpha != gamma
        let flag3 = beta != gamma
        
        return flag1 && flag2 && flag3
    }
    
    
    /// See if three points are all in a line
    /// 'isThreeUnique' should pass before running this
    /// - Parameters:
    ///   - alpha:  A test point
    ///   - beta:  Another test point
    ///   - gamma:  The final test point
    /// - See: 'testIsThreeLinear' under Point3DTests
    public static func isThreeLinear(alpha: Point3D, beta: Point3D, gamma: Point3D) -> Bool   {
        
        let thisWay = Vector3D.built(from: alpha, towards: beta)
        let thatWay = Vector3D.built(from: alpha, towards: gamma)

        let flag1 = try! Vector3D.isScaled(lhs: thisWay, rhs: thatWay)
        
        return flag1
    }
    
    
    /// Check if all contained points are unique.
    /// - Parameters:
    ///   - flock:  A collection of points
    /// - Returns: A simple flag
    /// - See: 'testUniquePool' under Point3DTests
    public static func isUniquePool(flock: [Point3D]) -> Bool   {
        
        /// A hash set
        let pool = Set<Point3D>(flock)
                
        /// All points have adequate separation
        let flag = (pool.count == flock.count)
        
        return flag
    }

    /// Throw away the Z value and convert
    /// Should this become a computed member variable?
    /// - See: 'testMakeCGPoint' under Point3DTests
    public static func makeCGPoint(pip: Point3D) -> CGPoint   {
        
        return CGPoint(x: pip.x, y: pip.y)
    }
    
    /// Check to see that the distance between the two is less than Point3D.Epsilon
    /// - See: 'testEqual' under Point3DTests
    public static func == (lhs: Point3D, rhs: Point3D) -> Bool   {
        
        let separation = Point3D.dist(pt1: lhs, pt2: rhs)   // Always positive
        
        return separation < Point3D.Epsilon
    }

}
