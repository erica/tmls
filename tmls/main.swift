//
//  tmls - perform a time machine ls
//
//  Created by Erica Sadun on 9/30/16.
//  Copyright © 2016 Erica Sadun. All rights reserved.


import Cocoa
public let manager = FileManager.default

// Fetch arguments and test for usage
var arguments = CommandLine.arguments
let appName = arguments.remove(at: 0).lastPathComponent
func usage() -> Never {
    print("Perform a time machine ls")
    print("Usage: \(appName) arguments")
    print("       \(appName) --offset count arguments")
    print("       \(appName) --list (count)")
    print("       \(appName) --help")
    exit(-1)
}

// Help message
if arguments.contains("--help") { usage() }

// Fetch time machine backup list in reverse order
let tmItems = tmlist()

// Perform Time Machine backup list
if arguments.contains("--list") {
    var max = tmItems.count
    if let argOffset = arguments.index(of: "--list"),
        arguments.index(after: argOffset) < arguments.endIndex
    {
        let countString = arguments[arguments.index(after: argOffset)]
        if let count = Int(countString), count < max { max = count }
    }
    tmItems.prefix(upTo: max).enumerated().forEach {
        print("\($0.0): \($0.1.ns.lastPathComponent)")
    }
    exit(0)
}

// Process offset
var offset = 1
if arguments.contains("--offset") {
    var max = tmItems.count
    if let argOffset = arguments.index(of: "--offset"),
        arguments.index(after: argOffset) < arguments.endIndex {
        let countOffset = arguments.index(after: argOffset)
        let countString = arguments[countOffset]
        if let count = Int(countString), count < max { offset = count }
        else { print("Offset invalid or too high (max is \(max - 1))"); exit(-1) }
        [countOffset, argOffset].forEach { arguments.remove(at: $0) }
    } else {
        print("Invalid use of --offset (must be followed by a number)"); exit(-1)
    }
}

// ls doesn't have any -- arguments but it does have dashed ones
arguments = arguments.filter({ !$0.hasPrefix("--") })
let dashedArgs = arguments.filter({ $0.hasPrefix("-") })
arguments = arguments.filter({ !$0.hasPrefix("-") })

// Test offset
guard tmItems.count > offset else {
    print("Invalid time machine offset (\(offset) > \(tmItems.count))")
    exit(-1)
}

let tmPath = tmItems[offset]
arguments = arguments.flatMap({ makeCanonical(tmPath: tmPath, sourcePath: $0) })

print("Time Machine: \(tmPath.lastPathComponent)\n")

/// Perform ls
let task = Process()
task.launchPath = "/bin/ls"
let defaultPath = makeCanonical(tmPath:tmPath, sourcePath: manager.currentDirectoryPath)
if arguments.isEmpty, let defaultPath = defaultPath {
    arguments = [defaultPath]
}
task.arguments = dashedArgs + arguments

let pipe = Pipe()
task.standardOutput = pipe
task.launch()
task.waitUntilExit()

let data = pipe
    .fileHandleForReading
    .readDataToEndOfFile()

print(String(data: data, encoding: String.Encoding.utf8) ?? "No result")
