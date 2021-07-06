//
//  ParallelError.swift
//  Tesstest
//
//  Created by Paul on 9/19/15.
//
//

import Foundation

public class ParallelError: Error {
    
    var enil: Line
    var enalp: Plane
    
    var description: String {
        return " Line and plane were parallel  " + String(describing: enil.getDirection())
    }
    
    public init(enil: Line, enalp: Plane)   {
        
        self.enil = enil
        self.enalp = enalp
    }
    
    
}
