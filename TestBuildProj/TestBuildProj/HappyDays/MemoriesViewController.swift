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
import CoreSpotlight
import MobileCoreServices

class MemoriesViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVAudioRecorderDelegate {

    var memories = [URL]()
    var activeMemory: URL!
    var audioRecorder: AVAudioRecorder?
    var recordingURL: URL!
    var audioPlayer: AVAudioPlayer?
    
    //MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        loadMemories()
        recordingURL = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkPermissions()
    }
    
    //MARK: - UICollectionViewDelegateFlowLayout Methods
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 1 {
            return CGSize.zero
        } else {
            return CGSize(width: 0, height: 50)
        }
    }
    
    //MARK: - UICollectionViewController Methods
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 0
        } else {
            return memories.count
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Memory", for: indexPath) as? MemoryCell {
            let memory = memories[indexPath.row]
            let imageName = thumbnailURL(for: memory).path
            let image = UIImage(contentsOfFile: imageName)
            cell.imageView.image = image
            
            //set up gesture recognizers
            if cell.gestureRecognizers == nil {
                let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(memoryLongPress))
                recognizer.minimumPressDuration = 0.25
                cell.addGestureRecognizer(recognizer)
                
                cell.layer.borderColor = UIColor.white.cgColor
                cell.layer.borderWidth = 3
                cell.layer.cornerRadius = 10
            }
            
            return cell
        }
    
        return UICollectionViewCell()
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let memory = memories[indexPath.row]
        let fm = FileManager.default
        
        do {
            let audioName = audioURL(for: memory)
            let transcriptionName = transcriptionURL(for: memory)
            if fm.fileExists(atPath: audioName.path) {
                audioPlayer = try AVAudioPlayer(contentsOf: audioName)
                audioPlayer?.play()
            }
            if fm.fileExists(atPath: transcriptionName.path) {
                let contents = try String(contentsOf: transcriptionName)
                print(contents)
            }
        } catch {
            print("Error loading audio")
        }
    }
    
    //MARK: - ImagePicker Methods
    @objc func addTapped() {
        let vc = UIImagePickerController()
        vc.modalPresentationStyle = .formSheet
        vc.delegate = self
        navigationController?.present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true)
        
        if let possibleImage = info[.originalImage] as? UIImage {
            saveNewMemory(image: possibleImage)
            loadMemories()
        }
    }
    
    //MARK: - Data Methods
    func saveNewMemory(image: UIImage) {
        //create a unique name for this memory
        let memoryName = "memory-\(Date().timeIntervalSince1970)"
        //use unique name to create filenames for the full size image and the thumbnail
        let imageName = memoryName + ".jpg"
        let thumbnailName = memoryName + ".thumb"
        do {
            //create a URL where we can write the JPEG to
            let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
            //convert the UIImage into a JPEG data object
            if let jpegData = image.jpegData(compressionQuality: 0.8) {
                //write data to the URL
                try jpegData.write(to: imagePath, options: [.atomicWrite])
            }
            if let thumbnail = resize(image: image, to: 200) {
                let thumbPath = getDocumentsDirectory().appendingPathComponent(thumbnailName)
                if let jpegData = thumbnail.jpegData(compressionQuality: 0.8) {
                    try jpegData.write(to: thumbPath, options: [.atomicWrite])
                }
            }
            
            
        } catch {
            print("faild to write to disk")
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
    
    //MARK: - AVAudioRecorderDelegate Methods
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
    
    //MARK: - Helper Methods
    @objc func memoryLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            if let cell = sender.view as? MemoryCell, let index = collectionView?.indexPath(for: cell) {
                activeMemory = memories[index.row]
                recordMemory()
            }
        } else if sender.state == .ended {
            finishRecording(success: true)
        }
    }
    
    func recordMemory() {
        audioPlayer?.stop()
        //set background to red while recording
        collectionView?.backgroundColor = UIColor(red: 0.5, green: 0, blue: 0, alpha: 1)
        
        let recordingSession = AVAudioSession.sharedInstance()
        
        do {
            //configure the session for recording and playback through the speaker
            try recordingSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try recordingSession.setActive(true)
            let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 44100, AVNumberOfChannelsKey: 2, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
            
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        } catch let error {
            //failed to record
            print("Failed to record: \(error)")
            finishRecording(success: false)
        }
        
    }
    
    func finishRecording(success:Bool) {
        collectionView?.backgroundColor = UIColor.darkGray
        audioRecorder?.stop()
        
        if success {
            do {
                let memoryAudioURL = activeMemory.appendingPathExtension("m4a")
                let fm = FileManager.default
                if fm.fileExists(atPath: memoryAudioURL.path) {
                    try fm.removeItem(at: memoryAudioURL)
                }
                try fm.moveItem(at: recordingURL, to: memoryAudioURL)
                transcribeAudio(memory: activeMemory)
                
            } catch let error {
                print("Error finishing recording \(error)")
            }
        }
    }
    
    func transcribeAudio(memory:URL) {
        let audio = audioURL(for: memory)
        let transcription = transcriptionURL(for: memory)
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: audio)
        
        recognizer?.recognitionTask(with: request) {
            [unowned self] (result, error) in
            guard let result = result else {
                print("error transcribing audio \(String(describing: error))")
                return
            }
            if result.isFinal {
                let text = result.bestTranscription.formattedString
                do {
                    try text.write(to: transcription, atomically: true, encoding: String.Encoding.utf8)
                    self.indexMemory(memory: memory, text: text)
                } catch {
                    print("Failed to save transcription")
                }
            }
        }
    }
    
    func indexMemory(memory: URL, text: String) {
        //create basic attribute set
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        attributeSet.title = "Happy Days Memories"
        attributeSet.contentDescription = text
        attributeSet.thumbnailURL = thumbnailURL(for: memory)

        //wrap it in a searchable item, using the memory's full path as its unique identifier
        let item = CSSearchableItem(uniqueIdentifier: memory.path, domainIdentifier: "com.hackingwithswift", attributeSet: attributeSet)
        
        //make it never expire
        item.expirationDate = Date.distantFuture
        
        //ask Spotlight to index the item
        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let anError = error {
                print("Indexing error: \(anError.localizedDescription)")
            } else {
                print("Search item successfully indexed: \(text)")
            }
        }
    }
    
    func imageURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("jpg")
    }
    
    func thumbnailURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("thumb")
    }
    
    func audioURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("m4a")
    }
    
    func transcriptionURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("txt")
    }
    
    func resize(image: UIImage, to width:CGFloat) -> UIImage? {
        //calculate how much we need to bring the width down to match out target size
        
        let scale = width / image.size.width
        
        //bring the height down by the same amount so that the aspect ration is preserved
        let height = image.size.height * scale
        
        //create a new image context we can draw into
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
        
        //draw the original image into the context
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        
        //pull out the resized version
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        return newImage
        
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
            
        }
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
