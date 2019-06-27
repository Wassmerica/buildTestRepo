//
//  HappyDays.swift
//  TestBuildProj
//
//  Created by Michael Wasserman on 2019-06-21.
//  Copyright © 2019 Michael Wasserman. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech

class HappyDays: UIViewController {
    @IBOutlet weak var helpLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func requestPermissions(_ sender: UIButton) {
        requestPhotosPermissions()
    }
    
    func requestPhotosPermissions() {
        PHPhotoLibrary.requestAuthorization { [unowned self] authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.requestRecordPermissions()
                } else {
                    self.helpLabel.text = "Photos permission was declined; please enable it in Settings and tap Continue again"
                }
            }
        }
    }
    
    
    func requestRecordPermissions() {
        AVAudioSession.sharedInstance().requestRecordPermission { [unowned self] allowed in
            DispatchQueue.main.async {
                if allowed {
                    self.requestTranscribePermissions()
                } else {
                    self.helpLabel.text = "Recording permission was declined; please enable it in settings then tap Continue again."
                }
            }
        }
    }
    
    func requestTranscribePermissions() {
        SFSpeechRecognizer.requestAuthorization { [unowned self] authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.authorizationComplete()
                } else {
                    self.helpLabel.text = "Transcription was declined; please enable it in settings then tap Continue again."
                }
            }
        }
    }
    
    func authorizationComplete() {
        dismiss(animated: true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
