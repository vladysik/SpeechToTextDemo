//
//  ViewController.swift
//  SpeechToTextDemo
//
//  Created by Maxim Vladysik on 12/2/16.
//  Copyright © 2016 Maxim Vladysik. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var speechButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private let colorForBorder = UIColor(red: 216 / 255, green: 64 / 255, blue: 60 / 255, alpha: 1)
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        speechButton.layer.borderColor = UIColor.clear.cgColor
        speechButton.layer.cornerRadius = speechButton.frame.size.height / 2
        speechButton.layer.borderWidth = 3
        
        speechButton.isEnabled = false
        speechRecognizer?.delegate = self
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
        
            var isButtonEnabled = false
            
            switch authStatus {
            
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                NSLog("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                NSLog("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                NSLog("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.speechButton.isEnabled = isButtonEnabled
            }
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startRecordong() {
    
        if recognitionTask != nil {
        
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
        
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
            
        } catch {
        
            NSLog("audioSession properties weren't set because of an error")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
        
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = recognitionRequest else {
        
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest,
                                                            resultHandler: {(result, error) in
        
            var isFinal = false
                                                                
            if result != nil {
                
                self.textView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
                                                                
            if error != nil || isFinal {
                
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.speechButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
        
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
        
            try audioEngine.start()
            
        } catch {
        
            NSLog("audioEngine couldn't start because of an error")
        }
        
        textView.text = "I'm listening..."
    }

    @IBAction func speechAction(_ sender: Any) {
        
        if audioEngine.isRunning {
        
            audioEngine.stop()
            recognitionRequest?.endAudio()
            speechButton.isEnabled = false
            NSLog("Stop recording")
            
            speechButton.layer.borderColor = UIColor.clear.cgColor
            
            resetButton.isEnabled = true
            
            if textView.text == "I'm listening..." {
                
                textView.text = "I'm sorry, I can't recognize your speech"
            }
            
        } else {
        
            startRecordong()
            NSLog("Start recording")
            
            speechButton.layer.borderColor = colorForBorder.cgColor
            
            resetButton.isEnabled = false
        }
    }
    
    @IBAction func resetAction(_ sender: Any) {
        
        textView.text = nil
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        
        if available {
        
            speechButton.isEnabled = true
            
        } else {
        
            speechButton.isEnabled = false
        }
    }

}

