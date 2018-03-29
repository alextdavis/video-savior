//
//  ViewController.swift
//  Video Savior
//
//  Created by Alex Davis on 3/2/18.
//  Copyright © 2018 Alex T. Davis. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    let resolutionMap = [240, 480, 720, 1080, 1440, 2160]
    enum Format: Int {
        case Default, MPEG, WebM, Audio, Legacy
    }
    
    @IBOutlet weak var videoURLField: NSTextField!
    @IBOutlet weak var formatControl: NSSegmentedControl!
    @IBOutlet weak var resolutionControl: NSSegmentedControl!
    @IBOutlet weak var highFPSControl: NSButton!
    @IBOutlet weak var pathDisplay: NSPathControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        UserDefaults.standard.set(false, forKey: "isSetUp")

        if !UserDefaults.standard.bool(forKey: "isSetUp") {
            print("Resetting")
            UserDefaults.standard.set(0, forKey: "format")
            UserDefaults.standard.set(5, forKey: "quality")
            UserDefaults.standard.set(true, forKey: "highFPS")
            let homeURL: URL
            if #available(OSX 10.12, *) {
                homeURL = FileManager.default.homeDirectoryForCurrentUser
            } else {
                homeURL = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
            }
            UserDefaults.standard.set(homeURL.appendingPathComponent("Downloads", isDirectory: true), forKey: "directory")
        }
        
        formatControl.selectedSegment = UserDefaults.standard.integer(forKey: "format")
        resolutionControl.selectedSegment = UserDefaults.standard.integer(forKey: "quality")
        highFPSControl.state = UserDefaults.standard.bool(forKey: "highFPS") ? .on : .off
        pathDisplay.url = UserDefaults.standard.url(forKey: "directory")
    }
    
    override func viewDidAppear() {
        if !UserDefaults.standard.bool(forKey: "isSetUp") {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "Video Savior needs to install components"
            alert.addButton(withTitle: "Continue")
            alert.addButton(withTitle: "Quit")
            alert.informativeText = "Video Savior is a graphical facade for a command-line program. Video Savior will now open a Terminal window which will install those command-line programs. You may be required to enter your password. As you type, your password will be hidden. For more information, visit https://video-savior.alextdavis.me/#components"
            alert.showsHelp = false
            alert.beginSheetModal(for: self.view.window!, completionHandler: {response in
                if response == .alertFirstButtonReturn {
                    self.update(0) //The 0 is there because some argument needs to be passed. I know it's a kludge.
                    UserDefaults.standard.set(true, forKey: "isSetUp") //TODO: Be smarter about when this should be set
                } else {
                    exit(1)
                }
            })
        }
    }
    
    @IBAction func saveSettings(_ sender: Any) {
        UserDefaults.standard.set(formatControl.selectedSegment, forKey: "format")
        UserDefaults.standard.set(resolutionControl.selectedSegment, forKey: "quality")
        UserDefaults.standard.set(highFPSControl.state == .on, forKey: "highFPS")
        UserDefaults.standard.set(pathDisplay.url, forKey: "directory")
    }
    
    func checkAdmin() -> Bool {
        let pipe = Pipe()
        let p = Process()
        p.launchPath = "/usr/bin/dsmemberutil"
        p.arguments = ["checkmembership", "-U", NSUserName(), "-G", "admin"]
        p.standardOutput = pipe
        p.launch()
        p.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
        if !(output?.contains("user is a member") ?? false) {
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = "Video Savior cannot install/update components, because you are not an administrator"
            alert.addButton(withTitle: "Cancel")
            alert.informativeText = "Video Savior needs administrator permission to install or update components. Please run this application while logged in with an administrator account to install or update components. For more information, visit https://video-savior.alextdavis.me/#admin"
            alert.showsHelp = false
            alert.beginSheetModal(for: self.view.window!)
            return false
        } else {
            return true
        }
    }
    
    func commandString() -> String {
        var str = "cd '\(self.pathDisplay.url!.path)'; youtube-dl --no-playlist -f "
        let constr = "[height<=\(resolutionMap[resolutionControl.selectedSegment])]" +
            (highFPSControl.state == .on ? "" : "[fps<40]")

        switch Format.init(rawValue: formatControl.selectedSegment)! {
        case .Audio:
            str.append("'bestaudio[ext=m4a]/bestaudio'")
        case .Legacy:
            str.append("'best\(constr)'")
        case .Default:
            str.append("'" +
                "bestvideo\(constr)[ext=mp4][height>=2160]+bestaudio[ext=m4a]/" +
                "bestvideo\(constr)[ext=webm][height>=2160]+bestaudio[ext=webm]/" +
                "bestvideo\(constr)[ext=mp4][height>=1440][fps>40]+bestaudio[ext=m4a]/" +
                "bestvideo\(constr)[ext=webm][height>=1440][fps>40]+bestaudio[ext=webm]/" +
                "bestvideo\(constr)[ext=mp4]+bestaudio[ext=m4a]/" +
                "bestvideo\(constr)+bestaudio/" +
                "best\(constr)'")
        case .WebM:
            str.append("'bestvideo[ext=webm]\(constr)+bestaudio[ext=webm]'")
        default:
            str.append("'bestvideo[ext=mp4]\(constr)+bestaudio[ext=m4a]'")
        }
        
        str.append(" \"\(videoURLField.stringValue)\"")
        
        let termDefaults = UserDefaults(suiteName: "com.apple.Terminal")
        if let profile = termDefaults?.string(forKey: "Default Window Settings"),
            let dict = termDefaults?.dictionary(forKey: "Window Settings")?[profile] as? NSDictionary,
            dict["shellExitAction"] as? Int == 1 || dict["shellExitAction"] as? Int == 0 {
            str.append("; echo '\n\n\u{1b}[32mVideo Savior is done.\u{1b}[0m Press return to close.'; read;")
            return str
        }
        str.append("; echo '\n\n\u{1b}[32mVideo Savior is done.\u{1b}[0m Please close this window.\n\n '")
        return str
    }

    @IBAction func setDownloadLocation(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.title = "Set Download Location"
        panel.prompt = "Select"
        panel.directoryURL = pathDisplay.url
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        panel.beginSheetModal(for: self.view.window!, completionHandler: {num in
            if num == .OK, let url = panel.url {
                self.pathDisplay.url = url
            }
        })
    }
    
    func tempURL(for name: String) -> URL {
        let url: URL
        if #available(OSX 10.12, *) {
            url = FileManager.default.temporaryDirectory.appendingPathComponent(Bundle.main.bundleIdentifier ?? "me.alextdavis.video-savior", isDirectory: true)
        } else {
            url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(Bundle.main.bundleIdentifier ?? "me.alextdavis.video-savior")
        }
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        return url.appendingPathComponent(name)
    }
    
    @IBAction func download(_ sender: Any) {
        let url = tempURL(for: "download.command")
        FileManager.default.createFile(atPath: url.path, contents: commandString().data(using: .utf8), attributes: [.posixPermissions: 0o754])
        NSWorkspace.shared.open(url)
    }
    
    @IBAction func update(_ sender: Any) {
        guard checkAdmin() else {
            return
        }

        let bundleURL = Bundle.main.url(forResource: "update", withExtension: "command")!
        let url = tempURL(for: "update.command")
        try! FileManager.default.createFile(atPath: url.path, contents: Data(contentsOf: bundleURL), attributes: [.posixPermissions: 0o754])
        NSWorkspace.shared.open(url)
    }
    
    @IBAction func help(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://video-savior.alextdavis.me/")!)
    }
}

