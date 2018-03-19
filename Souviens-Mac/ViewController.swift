//
//  ViewController.swift
//  Souviens-Mac
//
//  Created by Alex Davis on 3/2/18.
//  Copyright © 2018 Alex T. Davis. All rights reserved.
//

// TODO: Make computed variables for all the IBOutlets.

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
    
//    var videoURL: String {
//        get { return videoURLField.stringValue }
//    }
//
//    var format: Format {
//        get { return Format.init(rawValue: formatControl.selectedSegment)! }
//    }
//
//    var resolution: Int {
//        get { return resolutionMap[resolutionControl.selectedSegment] }
//    }
//
//    var highFPS: Bool {
//        get { return highFPSControl.state == .on }
//        set(new) { highFPSControl.state = new ? .on : .off }
//    }
//
//    var downloadPath: URL {
//        get { return pathDisplay.url }
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        UserDefaults.standard.set(false, forKey: "isSetUp")

        if !UserDefaults.standard.bool(forKey: "isSetUp") {
            print("Resetting")
            UserDefaults.standard.set(0, forKey: "format")
            UserDefaults.standard.set(5, forKey: "quality")
            UserDefaults.standard.set(true, forKey: "highFPS")
        UserDefaults.standard.set(FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads", isDirectory: true), forKey: "directory")
        }
        
        formatControl.selectedSegment = UserDefaults.standard.integer(forKey: "format")
        resolutionControl.selectedSegment = UserDefaults.standard.integer(forKey: "quality")
        highFPSControl.state = UserDefaults.standard.bool(forKey: "highFPS") ? .on : .off
        pathDisplay.url = UserDefaults.standard.url(forKey: "directory")
    }
    
    override func viewDidAppear() {
        if !UserDefaults.standard.bool(forKey: "isSetUp") {
            // TODO: Check that current user is admin.
            //
            checkAdmin()

            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "Souviens needs to install components"
            alert.addButton(withTitle: "Continue")
            alert.addButton(withTitle: "Quit")
            alert.informativeText = "Souviens is a graphical facade for a command-line program. Souviens will now open a Terminal window which will install those command-line programs. For more information, visit http://souviens.alextdavis.me/help#install"
            alert.showsHelp = true
            // TODO: Set up NSHelpManager
//            alert.helpAnchor = NSHelpManager.AnchorName(rawValue: "http://example.com")
            alert.beginSheetModal(for: self.view.window!, completionHandler: {response in
                if response == .alertFirstButtonReturn {
                    self.upgrade(0) //The 0 is there because some argument needs to be passed. I know it's a kludge.
                    UserDefaults.standard.set(true, forKey: "isSetUp")
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
    
    func checkAdmin() {
        let pipe = Pipe()
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/dsmemberutil")
        p.arguments = ["checkmembership", "-U", NSUserName(), "-G", "admin"]
        p.standardOutput = pipe
        guard let _ = try? p.run() else { return }
        p.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
        if !(output?.contains("user is a member") ?? false) {
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = "Souviens needs to install components, and you are not an administrator"
            alert.addButton(withTitle: "Continue anyway")
            alert.addButton(withTitle: "Quit")
            alert.informativeText = "Souviens needs administrator permission to install components. Please run this application while logged in with an administrator account to install components. After that is done, press \"Continue Anyway\" to verify. For more information, visit http://souviens.alextdavis.me/help#admin"
            //TODO: Be smarter about when these messages are shown.
            alert.showsHelp = false
            alert.beginSheetModal(for: self.view.window!, completionHandler: {response in
                if response == .alertFirstButtonReturn {
                    return
                } else {
                    exit(1)
                }
            })
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
            let dict = termDefaults!.dictionary(forKey: "Window Settings")?[profile] as? NSDictionary,
            dict["shellExitAction"] as! Int == 1 || dict["shellExitAction"] as! Int == 0 {
            str.append("; echo '\n\n\u{1b}[32mSouviens is done.\u{1b}[0m Press return to close.'; read;")
            return str
        }
        str.append("; echo '\n\n\u{1b}[32mSouviens is done.\u{1b}[0m Please close this window.\n\n '")
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
    
    @IBAction func download(_ sender: Any) {
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("download.command")
//        print(commandString())
        try! commandString().write(to: tmpURL, atomically: false, encoding: .utf8)
        try! Process.run(URL(fileURLWithPath: "/bin/chmod"), arguments: ["754", tmpURL.path])
        try! Process.run(URL(fileURLWithPath: "/usr/bin/open"), arguments: ["-a", "Terminal", tmpURL.path])
    }
    
    @IBAction func upgrade(_ sender: Any) {
        let installPath = Bundle.main.path(forResource: "install", ofType: "sh")
        try! Process.run(URL(fileURLWithPath: "/bin/chmod"), arguments: ["754", installPath!])
        try! Process.run(URL(fileURLWithPath: "/usr/bin/open"), arguments: ["-a", "Terminal", installPath!])
    }
}

