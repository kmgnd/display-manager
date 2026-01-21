#!/usr/bin/env swift

import Foundation
import CoreGraphics

struct DisplayInfo: Codable {
    let id: UInt32
    let width: Int
    let height: Int
    let x: Int
    let y: Int
}

struct Config: Codable {
    var layouts: [String: [DisplayInfo]] = [:]
}

class DisplayManager {
    private let configPath = FileManager.default.homeDirectoryForCurrentUser.path + "/.display-manager.json"
    
    func getDisplays() -> [DisplayInfo] {
        var count: UInt32 = 0
        var ids = [CGDirectDisplayID](repeating: 0, count: 10)
        CGGetActiveDisplayList(10, &ids, &count)
        
        return (0..<Int(count)).map { i in
            let bounds = CGDisplayBounds(ids[i])
            return DisplayInfo(
                id: ids[i],
                width: Int(bounds.width),
                height: Int(bounds.height),
                x: Int(bounds.origin.x),
                y: Int(bounds.origin.y)
            )
        }
    }
    
    func loadConfig() -> Config {
        guard let data = FileManager.default.contents(atPath: configPath),
              let config = try? JSONDecoder().decode(Config.self, from: data) else {
            return Config()
        }
        return config
    }
    
    func saveConfig(_ config: Config) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(config) {
            FileManager.default.createFile(atPath: configPath, contents: data)
        }
    }
    
    func list() {
        print("Current displays:")
        for d in getDisplays() {
            print("  Display \(d.id): \(d.width)x\(d.height) at (\(d.x), \(d.y))")
        }
    }
    
    func save(_ name: String) {
        var config = loadConfig()
        config.layouts[name] = getDisplays()
        saveConfig(config)
        print("Saved '\(name)'")
    }
    
    func apply(_ name: String) {
        let config = loadConfig()
        guard let saved = config.layouts[name] else {
            print("Layout '\(name)' not found. Available: \(config.layouts.keys.joined(separator: ", "))")
            return
        }
        
        let current = getDisplays()
        var configRef: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&configRef) == .success, let ref = configRef else {
            print("Failed to begin configuration")
            return
        }
        
        for s in saved {
            let targetID = current.first(where: { $0.id == s.id })?.id
                ?? current.first(where: { $0.width == s.width && $0.height == s.height })?.id
            
            if let id = targetID {
                CGConfigureDisplayOrigin(ref, id, Int32(s.x), Int32(s.y))
            }
        }
        
        if CGCompleteDisplayConfiguration(ref, .permanently) == .success {
            print("Applied '\(name)'")
        } else {
            print("Failed to apply")
        }
    }
    
    func layouts() {
        let config = loadConfig()
        if config.layouts.isEmpty {
            print("No layouts saved. Use: display-manager save <name>")
        } else {
            print("Saved layouts: \(config.layouts.keys.sorted().joined(separator: ", "))")
        }
    }
    
    func delete(_ name: String) {
        var config = loadConfig()
        if config.layouts.removeValue(forKey: name) != nil {
            saveConfig(config)
            print("Deleted '\(name)'")
        } else {
            print("Layout '\(name)' not found")
        }
    }
}

let dm = DisplayManager()
let args = CommandLine.arguments

if args.count < 2 {
    print("""
    Usage: display-manager <command> [name]
    
    Commands:
      list          Show current displays
      layouts       List saved layouts
      save <name>   Save current layout
      apply <name>  Apply saved layout
      delete <name> Delete a layout
    """)
    exit(0)
}

switch args[1] {
case "list": dm.list()
case "layouts": dm.layouts()
case "save": args.count >= 3 ? dm.save(args[2]) : print("Usage: save <name>")
case "apply": args.count >= 3 ? dm.apply(args[2]) : print("Usage: apply <name>")
case "delete": args.count >= 3 ? dm.delete(args[2]) : print("Usage: delete <name>")
default: print("Unknown command: \(args[1])")
}