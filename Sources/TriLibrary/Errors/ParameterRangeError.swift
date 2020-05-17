//
//  File.swift
//  
//
//  Created by Paul Hollingshead on 5/10/20.
//

import Foundation

/// Exception for when a parameter value is outside the allowed range
public class ParameterRangeError: Error {
    
    var paramA: Double
    
    var description: String {
        return "Parameter was outside valid range! " + String(describing: paramA)
    }
    
    init(parA: Double)   {
        
        self.paramA = parA
    }
    
}
