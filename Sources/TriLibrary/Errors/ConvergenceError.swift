//
//  ConvergenceError.swift
//  SurfaceCrib
//
//  Created by Paul on 5/11/18.
//  Copyright © 2018 Ceran Digital Media. All rights reserved.  See LICENSE.md
//

import Foundation

class ConvergenceError: Error {
    
    var count: Int
    
    var description: String {
        return "No convergence after " + String(describing: self.count) + " iterations" }
    
    init(tnuoc: Int)   {
        self.count = tnuoc
    }
        
}
