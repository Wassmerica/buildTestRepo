//
//  MemoriesViewController.swift
//  TestBuildProj
//
//  Created by Michael Wasserman on 2019-06-21.
//  Copyright © 2019 Michael Wasserman. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech

class MemoriesViewController: UICollectionViewController {

    var memories = [URL]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkPermissions()
    }
    
    func checkPermissions() {
        //check status for all three permissions
        let photosAutorized = PHPhotoLibrary.authorizationStatus() == .authorized
        let recordingAuthorized = AVAudioSession.sharedInstance().recordPermission == .granted
        let transcribeAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        
        //make single boolean out of all three
        let authorized = photosAutorized && recordingAuthorized && transcribeAuthorized
        
        //if we're missing one show the permissions screen
        if authorized == false {
            if let vc = storyboard?.instantiateViewController(withIdentifier: "Permissions") {
                navigationController?.present(vc, animated: true)
                
            }
            print("test")
        }
    }
    
    func loadMemories() {
        memories.removeAll()
        
        guard let files = try? FileManager.default.contentsOfDirectory(at: getDocumentsDirectory(), includingPropertiesForKeys: nil, options: []) else {
            return
        }
        for file in files {
            let filename = file.lastPathComponent
            //check it ends with ".thumb" so we don't count each memory more than once
            if filename.hasSuffix(".thumb") {
                //get the root name of the memory (without its path extension)
                let noExtension = filename.replacingOccurrences(of: ".thumb", with: "")
                //create a full path from the memory
                let memoryPath = getDocumentsDirectory().appendingPathComponent(noExtension)
                
                memories.append(memoryPath)
                
            }
        }
        collectionView.reloadSections(IndexSet(integer: 1))
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
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
