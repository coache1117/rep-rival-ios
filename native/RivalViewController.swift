// RIVAL · R2 · the main screen of every Rival iPhone app. Main.storyboard points here.
// 1. Attaches the coach's ears (CoachSpeechPlugin) - unless Capacitor already attached them from capacitor.config.json.
// 2. Tells the page which iPhone build it is in (window.RIVAL_NATIVE), so the page can show it when something is off.
// 3. App links: when Club Rival opens this app with a link like rivalstride://open?do=walk, the page opens on that spot.
import UIKit
import WebKit
import Capacitor

class RivalViewController: CAPBridgeViewController {
    private var linkWatch: NSObjectProtocol?

    override open func capacitorDidLoad() {
        if bridge?.plugin(withName: "CoachSpeech") == nil {
            bridge?.registerPluginInstance(CoachSpeechPlugin())
        }
        let info = Bundle.main.infoDictionary ?? [:]
        let build = (info["CFBundleVersion"] as? String) ?? "?"
        let ver = (info["CFBundleShortVersionString"] as? String) ?? "?"
        let ears = bridge?.plugin(withName: "CoachSpeech") != nil
        let js = "window.RIVAL_NATIVE={kit:'R2',ears:\(ears ? "true" : "false"),build:'\(build)',version:'\(ver)'};"
        webView?.configuration.userContentController.addUserScript(
            WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        linkWatch = NotificationCenter.default.addObserver(forName: .capacitorOpenURL, object: nil, queue: .main) { [weak self] note in
            if let d = note.object as? [String: Any], let u = d["url"] as? URL { self?.openLink(u) }
        }
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        if let u = ApplicationDelegateProxy.shared.lastURL, u.scheme?.hasPrefix("rival") == true { openLink(u) }
    }

    deinit { if let w = linkWatch { NotificationCenter.default.removeObserver(w) } }

    // rivalX://open?do=walk&from=club  ->  https://<this app's site>/?do=walk&from=club  (only when there is something to do)
    private func openLink(_ u: URL) {
        guard u.scheme?.hasPrefix("rival") == true,
              let q = URLComponents(url: u, resolvingAgainstBaseURL: false)?.queryItems,
              q.contains(where: { $0.name == "do" }),
              let base = bridge?.config.serverURL,
              var c = URLComponents(url: base, resolvingAgainstBaseURL: false) else { return }
        c.queryItems = q.filter { ["do", "go", "from"].contains($0.name) }
        if let to = c.url { webView?.load(URLRequest(url: to)) }
    }
}
