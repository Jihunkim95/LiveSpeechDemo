//
//  ViewController.swift
//  LiveSpeechDemo
//
//  Created by 김지훈 on 2023/12/04.
//

import UIKit
// speech 프레임워크 추가
import Speech
class ViewController: UIViewController {

    @IBOutlet var transcribeButton: UIButton!
    @IBOutlet var stopButton: UIButton!
    @IBOutlet var myTextView: UITextView!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))
    
    private var speechRecognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    //작업처리
    private var speechRecognitionTask: SFSpeechRecognitionTask?
    // 오디오
    private let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    
    @IBAction func startTranscribing(_ sender: Any) {
        transcribeButton.isEnabled = false
        stopButton.isEnabled = true
        do {
            try startSession()
        } catch { }
    }
    
    
    func authorizeSR() {
        SFSpeechRecognizer.requestAuthorization { authStatus in

            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.transcribeButton.isEnabled = true

                case .denied:
                    self.transcribeButton.isEnabled = false
                    self.transcribeButton.setTitle("Speech recognition access denied by user", for: .disabled)

                case .restricted:
                    self.transcribeButton.isEnabled = false
                    self.transcribeButton.setTitle(
                        "Speech recognition restricted on device", for: .disabled)

                case .notDetermined:
                    self.transcribeButton.isEnabled = false
                    self.transcribeButton.setTitle(
                        "Speech recognition not authorized", for: .disabled)
                @unknown default:
                    print("Unknown state")
                }
            }
        }
    }
    func startSession() throws {

        if let recognitionTask = speechRecognitionTask {
            recognitionTask.cancel()
            self.speechRecognitionTask = nil
        }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .default)

        speechRecognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = speechRecognitionRequest else {
            fatalError("SFSpeechAudioBufferRecognitionRequest create failed.")
        }

        let inputNode = audioEngine.inputNode
        recognitionRequest.shouldReportPartialResults = true

        speechRecognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in

            var finished = false

            if let result = result {
                self.myTextView.text = result.bestTranscription.formattedString
                finished = result.isFinal
            }

            if error != nil || finished {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.speechRecognitionRequest = nil
                self.speechRecognitionTask = nil

                self.transcribeButton.isEnabled = true
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
            (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.speechRecognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
    }
    @IBAction func stopTranscribing(_ sender: Any) {
        transcribeButton.isEnabled = false
        stopButton.isEnabled = true

        do {
            try startSession()
        } catch { }
    }
}

