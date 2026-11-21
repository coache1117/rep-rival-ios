// CLUB RIVAL · CR038 · the coach's ears on iPhone.
// Safari stops listening after every answer. This is Apple's own speech engine, so inside the app the coach keeps listening.
// Nothing is recorded or uploaded by this file: the words are turned into text on the phone and handed to the page.
import Foundation
import Capacitor
import Speech
import AVFoundation

@objc(CoachSpeechPlugin)
public class CoachSpeechPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "CoachSpeechPlugin"
    public let jsName = "CoachSpeech"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "available", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "askPermission", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "start", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stop", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "takeSiri", returnType: CAPPluginReturnPromise)
    ]

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var tapOn = false

    @objc func available(_ call: CAPPluginCall) {
        call.resolve(["available": recognizer?.isAvailable ?? false])
    }

    @objc func askPermission(_ call: CAPPluginCall) {
        SFSpeechRecognizer.requestAuthorization { status in
            AVAudioSession.sharedInstance().requestRecordPermission { mic in
                call.resolve(["speech": status == .authorized ? "granted" : "denied", "mic": mic ? "granted" : "denied"])
            }
        }
    }

    @objc func start(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.stopAll()
            guard SFSpeechRecognizer.authorizationStatus() == .authorized else { call.reject("speech-not-allowed"); return }
            guard let rec = self.recognizer, rec.isAvailable else { call.reject("speech-not-available"); return }
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP, .mixWithOthers])
                try session.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                call.reject("audio-session: \(error.localizedDescription)"); return
            }
            let req = SFSpeechAudioBufferRecognitionRequest()
            req.shouldReportPartialResults = true
            self.request = req
            let input = self.engine.inputNode
            let format = input.outputFormat(forBus: 0)
            if format.sampleRate == 0 { call.reject("no-microphone"); return }
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.request?.append(buffer)
            }
            self.tapOn = true
            self.engine.prepare()
            do { try self.engine.start() } catch {
                self.stopAll(); call.reject("mic: \(error.localizedDescription)"); return
            }
            self.task = rec.recognitionTask(with: req) { [weak self] result, err in
                guard let self = self else { return }
                if let r = result {
                    self.notifyListeners("partial", data: ["text": r.bestTranscription.formattedString, "final": r.isFinal])
                }
                if err != nil || (result?.isFinal ?? false) {
                    DispatchQueue.main.async {
                        self.stopAll()
                        self.notifyListeners("state", data: ["status": "stopped"])
                    }
                }
            }
            self.notifyListeners("state", data: ["status": "started"])
            call.resolve()
        }
    }

    @objc func stop(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.stopAll()
            self.notifyListeners("state", data: ["status": "stopped"])
            call.resolve()
        }
    }

    // Siri hands the request to the app (see RivalSiri.swift); the page picks it up here, once.
    @objc func takeSiri(_ call: CAPPluginCall) {
        let d = UserDefaults.standard
        let v = d.string(forKey: "rival_siri_do") ?? ""
        d.removeObject(forKey: "rival_siri_do")
        call.resolve(["do": v])
    }

    private func stopAll() {
        if engine.isRunning { engine.stop() }
        if tapOn { engine.inputNode.removeTap(onBus: 0); tapOn = false }
        request?.endAudio()
        request = nil
        task?.cancel()
        task = nil
    }
}
