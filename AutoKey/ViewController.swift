//
//  ViewController.swift
//  AutoKey
//
//  Created by fnord on 6/30/17.
//  Copyright © 2017 twof. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    

    @IBAction func recordButtonPressed(_ sender: NSButton) {
        
        var clickLocations: [CGPoint] = []
        var actionStrings: [String] = []
        var lastActionTime = Date()
        
        var monitors: [Any?] = []
        
        monitors.append(NSEvent.addGlobalMonitorForEvents(matching: .keyDown) {
            if $0.keyCode == 53 {
                do {
                    // Write contents to file
                    let documentsUrl = FileManager.default.urls(for: .documentDirectory , in: .userDomainMask)[0] as NSURL
                    
                    // add a filename
                    let fileUrl = documentsUrl.appendingPathComponent("recording.txt")
                    
                    try! actionStrings.joined(separator: "\n").write(to: fileUrl!, atomically: true, encoding: String.Encoding.utf8)
                    
                    monitors.forEach({ (aMonitor) in
                        guard let monitor = aMonitor else {return}
                        NSEvent.removeMonitor(monitor)
                    })
                }
                catch let error as NSError {
                    print("Ooops! Something went wrong: \(error)")
                }
                
                return
            }

            actionStrings.append("wait*\(0 - lastActionTime.timeIntervalSinceNow)")
            actionStrings.append("type*\($0.keyCode)")
            lastActionTime = Date()
        })
        
        monitors.append(NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) {_ in
            actionStrings.append("wait*\(0 - lastActionTime.timeIntervalSinceNow)")
            actionStrings.append("click*\(NSEvent.mouseLocation().x),\((NSEvent.mouseLocation().y - 900) * -1)")
            clickLocations.append(NSEvent.mouseLocation())
            lastActionTime = Date()
        })
        
    }
    
    @IBAction func playButtonPressed(_ sender: NSButton) {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory , in: .userDomainMask)[0] as NSURL
        
        let fileUrl = documentsUrl.appendingPathComponent("recording.txt")

        
        //reading
        do {
            let recording = try String(contentsOf: fileUrl!, encoding: String.Encoding.utf8).components(separatedBy: "\n")
            for actionString in recording {
                let actionParts = actionString.components(separatedBy: "*")
                let action = (command: actionParts[0], value: actionParts[1])
                
                switch action.command {
                case "wait":
                    usleep(useconds_t(Int(Double(action.value)! * 1_000_000)))
                case "type":
                    pressKey(keyCode: UInt8(action.value)!)
                case "click":
                    let coords = action.value.components(separatedBy: ",")
                    leftClick(x: Double(coords[0])!, y: Double(coords[1])!)
                default:
                    print("wtf?")
                }
            }
        }
        catch {/* error handling here */}

    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func pressKey(keyCode: UInt8) {
        let kDelayUSec : useconds_t = 500_000
        
        let keyD = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: true)
        let keyU = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: false)
        
        keyD?.post(tap: .cghidEventTap)
//        usleep(kDelayUSec)
        keyU?.post(tap: .cghidEventTap)
    }
    
    func leftClick(x: Double, y: Double) {
        let kDelayUSec : useconds_t = 1_000_000
        
        
        let mouseDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: CGPoint(x: x, y: y), mouseButton: .left)
        
        let mouseUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: CGPoint(x: x, y: y), mouseButton: .left)
        
        mouseDown?.post(tap: .cghidEventTap)
        
        for var i in 0...5 {
            usleep(150_000)
            CGDisplayMoveCursorToPoint(0, CGPoint(x: x + Double(i), y: y - Double(i)))
        }
        
        usleep(kDelayUSec)
        mouseUp?.post(tap: .cghidEventTap)
    }
}

