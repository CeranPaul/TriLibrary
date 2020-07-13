//
//  TinyArrayError.swift
//  ArcHammer
//
//  Created by Paul Hollingshead on 5/22/20.
//  Copyright © 2020 Paul Hollingshead. All rights reserved.
//

import Foundation

public class TinyArrayError: Error {
    
    var count: Int
    
    var description: String {
        return "Array must have at least three members: " + String(describing: self.count) }
    
    public init(tnuoc: Int)   {
        self.count = tnuoc
    }
        
}
