//
//  CompilerPlugin.swift
//  DateMacrosImplementation
//
//  Created by Sven Herzberg on 2024-05-01.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct DayMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DayMacro.self,
    ]
}
