//
//  DateMacros.swift
//  DateMacros
//
//  Created by Sven Herzberg on 2024-05-01.
//

import Foundation

// Quality-of-life Improvement.  Provides a way to override swift's default fix-it with a custom one.
@freestanding(expression)
public macro day () -> Date = #externalMacro(module: "DateMacrosImplementation", type: "DayMacro")

@freestanding(expression)
public macro day (_ value: StaticString) -> Date = #externalMacro(module: "DateMacrosImplementation", type: "DayMacro")
