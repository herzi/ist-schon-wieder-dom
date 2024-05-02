//
//  DateMacroTests.swift
//  UnitTests
//
//  Created by Sven Herzberg on 2024-05-01.
//

import XCTest

import SwiftSyntaxMacrosTestSupport

@testable import DateMacrosImplementation

final class DateMacroTests: XCTestCase {
    
    func testSample() throws {
        assertMacroExpansion(
            """
            #day("2024-01-26")
            """,
            expandedSource: """
            Date(timeIntervalSinceReferenceDate: 727920000.0)
            """,
            macros: [
                "day": DayMacro.self,
            ]
        )
    }
    
    func testEmptyString () {
        assertMacroExpansion(
            """
            #day("")
            """,
            expandedSource: """
            #day("")
            """,
            diagnostics: [
                DiagnosticSpec(message: "String Literal is empty", line: 1, column: 7, fixIts: [
                    FixItSpec(message: "Insert “<\u{23}YYYY#>-<\u{23}MM#>-<\u{23}DD#>”"),
                ]),
            ],
            macros: [
                "day": DayMacro.self,
            ]
        )
    }
    
    func testFixableDate () {
        // ICU will convert 2024-02-30 to 2024-03-01
        #if os(Linux)
        let expandedSource = """
        #day("2024-02-30")
        """
        let expectedDiagnostic = DiagnosticSpec(message: "Invalid day expression: 2024-02-30", line: 1, column: 7)
        #else
        let expandedSource = """
        Date(timeIntervalSinceReferenceDate: 730944000.0)
        """
        let expectedDiagnostic = DiagnosticSpec(
            message: "Invalid day expression: 2024-02-30", line: 1, column: 7, severity: .warning, fixIts: [
                FixItSpec(message: "Replace “2024-02-30” with “2024-03-01”"),
            ]
        )
        #endif
        assertMacroExpansion(
            """
            #day("2024-02-30")
            """,
            expandedSource: expandedSource,
            diagnostics: [expectedDiagnostic],
            macros: [
                "day": DayMacro.self,
            ]
        )
    }
    
    func testIllegalDate () {
        assertMacroExpansion(
            """
            #day("2024-13-31")
            """,
            expandedSource: """
            #day("2024-13-31")
            """,
            diagnostics: [
                DiagnosticSpec(message: "Invalid day expression: 2024-13-31", line: 1, column: 7),
            ],
            macros: [
                "day": DayMacro.self,
            ]
        )
    }
    
    func testInvalidArgumentType () {
        assertMacroExpansion(
            """
            #day(20240201)
            """,
            expandedSource: """
            #day(20240201)
            """,
            diagnostics: [
                DiagnosticSpec(message: "Invalid type of argument: Integer", line: 1, column: 6),
            ],
            macros: [
                "day": DayMacro.self,
            ]
        )
    }
    
    func testStringInterpolationArgument () {
        assertMacroExpansion(
            """
            #day("\\(2024)-02-01")
            """,
            expandedSource: """
            #day("\\(2024)-02-01")
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "#day() does not support string interpolation, use a `StaticString` instead.",
                    line: 1, column: 1
                ),
            ],
            macros: [
                "day": DayMacro.self,
            ]
        )
    }
    
    func testMacroWithoutArguments () {
        assertMacroExpansion(
            "#day()",
            expandedSource: "#day()",
            diagnostics: [
                DiagnosticSpec(message: "Missing argument for parameter in macro expansion", line: 1, column: 1, fixIts: [
                    FixItSpec(message: "Insert “\"<\u{23}YYYY#>-<\u{23}MM#>-<\u{23}DD#>\"”")
                ]),
            ],
            macros: [
                "day": DayMacro.self,
            ]
        )
    }
}
