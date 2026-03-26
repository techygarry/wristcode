import Foundation
import WebKit
import AppKit

class Screenshotter: NSObject, WKNavigationDelegate {
    let webView: WKWebView
    let outputPath: String
    let semaphore = DispatchSemaphore(value: 0)

    init(htmlPath: String, outputPath: String, width: Int = 390, height: Int = 844) {
        self.outputPath = outputPath
        let config = WKWebViewConfiguration()
        self.webView = WKWebView(frame: NSRect(x: 0, y: 0, width: width, height: height), configuration: config)
        super.init()
        self.webView.navigationDelegate = self
        let url = URL(fileURLWithPath: htmlPath)
        self.webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.takeScreenshot()
        }
    }

    func takeScreenshot() {
        let config = WKSnapshotConfiguration()
        config.rect = webView.bounds
        webView.takeSnapshot(with: config) { image, error in
            if let image = image {
                let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
                let png = rep.representation(using: .png, properties: [:])!
                try! png.write(to: URL(fileURLWithPath: self.outputPath))
            }
            self.semaphore.signal()
        }
    }

    func run() {
        semaphore.wait()
    }
}

guard CommandLine.arguments.count >= 3 else {
    print("Usage: screenshot <html-file> <output-png>")
    exit(1)
}

let app = NSApplication.shared
let htmlPath = CommandLine.arguments[1]
let outputPath = CommandLine.arguments[2]

let screenshotter = Screenshotter(htmlPath: htmlPath, outputPath: outputPath)
// Run the event loop briefly
RunLoop.main.run(until: Date(timeIntervalSinceNow: 3))
screenshotter.run()
