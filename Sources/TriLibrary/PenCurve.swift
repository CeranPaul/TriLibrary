//
//  PenCurve.swift
//  SketchCurves
//
//  Created by Paul on 10/30/15.
//  Copyright © 2018 Ceran Digital Media. See LICENSE.md
//

import Foundation

/// The general framework for a curve.  Not limited to 2D.
public protocol PenCurve   {
    
    /// The enum that hints at the meaning of the curve
    var usage: PenTypes   { get set }
    
    /// I can't think of anywhere that this is used
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
    
    /// Plot the curve.  Your classic example of polymorphism
    /// - SeeAlso:  drawControls() for a Cubic
    func draw(context: CGContext, tform: CGAffineTransform)
    
       // getLength and intersect are near-term candidates for additional funcs
    
    /// Figure how far the point is off the curve, and how far along the curve it is.  Useful for picks  
//    func resolveRelative(speck: Point3D) -> (along: Double, away: Double)
    
}
