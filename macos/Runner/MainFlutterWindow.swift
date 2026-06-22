import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  // Required on macOS 26 (Tahoe) — without this the window never fully enters
  // key-window state and Flutter's text input responder chain is never armed.
  override var canBecomeKey: Bool { true }

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Ensure the window is tall enough for the settings form.
    // Clear autosave so a previously-saved small frame doesn't override this.
    self.setFrameAutosaveName("")
    let minSize = NSSize(width: 600, height: 720)
    self.minSize = minSize
    if self.frame.size.height < minSize.height {
      var f = self.frame
      f.size.height = minSize.height
      self.setFrame(f, display: false)
    }

    // On macOS 26, NSOpenPanel does not restore the Flutter view as first
    // responder when it closes. Without first-responder status the view's
    // hit-test chain is broken and pointer events never reach Flutter widgets.
    // Re-establishing it every time this window regains key status fixes that.
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(reclaimFirstResponder),
      name: NSWindow.didBecomeKeyNotification,
      object: self
    )

    super.awakeFromNib()
  }

  @objc private func reclaimFirstResponder() {
    makeFirstResponder(contentViewController?.view)
  }
}
