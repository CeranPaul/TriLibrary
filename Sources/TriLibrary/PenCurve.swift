//
//  PenCurve.swift
//  SketchCurves
//
//  Created by Paul on 10/30/15.
//  Copyright © 2018 Ceran Digital Media. See LICENSE.md
//

import Foundation
import CoreGraphics

/// The general framework for a curve.  Not limited to 2D.
public protocol PenCurve   {
    
    /// A String that hints at the meaning of the curve
    var usage: String   { get set }
    
    /// Used for error checking
    var parameterRange: ClosedRange<Double>   { get set }
    
    /// Supply the point on the curve for the input parameter value
    func pointAt(t: Double) throws -> Point3D
    
    /// Retrieve the starting end
    func getOneEnd() -> Point3D
    
    /// Retrieve the finishing end
    func getOtherEnd() -> Point3D
    
    /// Figure the volume that encloses the curve
    /// Must have finite thickness in all three axes
    func getExtent() -> OrthoVol
    
    func getLength() -> Double
    
    func intersect(ray: Line, accuracy: Double) throws -> [Point3D]
        
    func isPerchFor(speck: Point3D) throws -> (flag: Bool, param: Double?) 

    /// Plot the curve.  Your classic example of polymorphism
    func draw(context: CGContext, tform: CGAffineTransform, allowableCrown: Double) throws
    
    mutating func reverse()
    
    func transform(xirtam: Transform) throws -> PenCurve
    
    
    
       // getLength, transform, and intersect with a line are near-term candidates for additional funcs
    
    /// Figure how far the point is off the curve, and how far along the curve it is.  Useful for picks  
//    func resolveRelative(speck: Point3D) -> (along: Double, away: Double)
    
}
