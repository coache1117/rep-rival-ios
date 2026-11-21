// REP RIVAL · RR30 (same file as Club Rival CR038) · loads the coach's ears (CoachSpeechPlugin) into the app. Main.storyboard points here.
import UIKit
import Capacitor

class RivalViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        bridge?.registerPluginInstance(CoachSpeechPlugin())
    }
}
