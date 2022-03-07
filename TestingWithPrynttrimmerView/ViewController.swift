//
//  ViewController.swift
//  TestingWithPrynttrimmerView
//
//  Created by Luis Segoviano on 07/03/22.
//

import UIKit

import AVKit
import AVFoundation
import MobileCoreServices


class ViewController: UIViewController {

    let imagePickerController: UIImagePickerController = UIImagePickerController()
    
    var videoURL: URL?
    
    var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    let playButton: UIButton = UIButton(type: .system)
    
    private func setupUI() {
        playButton.isEnabled = false
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.setTitle("Play", for: .normal)
        playButton.addTarget(self, action: #selector(videoTapped), for: .touchUpInside)
        let openLibrary: UIButton = UIButton(type: .system)
        openLibrary.translatesAutoresizingMaskIntoConstraints = false
        openLibrary.setTitle("Select", for: .normal)
        openLibrary.addTarget(self, action: #selector(selectImageFromPhotoLibrary), for: .touchUpInside)
        self.view.addSubview(openLibrary)
        self.view.addSubview(playButton)
        self.view.addSubview(imageView)
        playButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 24).isActive = true
        playButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16).isActive = true
        playButton.widthAnchor.constraint(equalToConstant: 45).isActive = true
        playButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        openLibrary.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 24).isActive = true
        openLibrary.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16).isActive = true
        openLibrary.widthAnchor.constraint(equalToConstant: 45).isActive = true
        openLibrary.heightAnchor.constraint(equalToConstant: 30).isActive = true
        imageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        imageView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
    }
    
    // MARK: Actions
    
    @objc func selectImageFromPhotoLibrary(sender: UIBarButtonItem) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            imagePickerController.delegate = self
            imagePickerController.sourceType = .photoLibrary
            imagePickerController.mediaTypes = ["public.movie"]
            imagePickerController.modalPresentationStyle = .custom
            imagePickerController.allowsEditing = false
            present(imagePickerController, animated: true, completion: nil)
        }
    }
    
    @objc func videoTapped(sender: UITapGestureRecognizer) {
        if let videoURL = videoURL {
            let player = AVPlayer(url: videoURL as URL)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            present(playerViewController, animated: true){
                playerViewController.player!.play()
            }
        }
    }


}


extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        guard
            let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String,
            mediaType == (kUTTypeMovie as String),
            let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL else {
            print(" URL not found ")
            return
        }
        self.playButton.isEnabled = true
        self.videoURL = videoURL
        imageView.image = previewImageFromVideo(url: videoURL)!
        imageView.contentMode = .scaleAspectFit
        imagePickerController.dismiss(animated: true, completion: nil)
    }
    
    
    func previewImageFromVideo(url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset:asset)
        imageGenerator.appliesPreferredTrackTransform = true
        var time = asset.duration
        time.value = min(time.value, 2)
        do {
            let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch {
            print("Unexpected error: \(error).")
            return nil
        }
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imagePickerController.dismiss(animated: true, completion: nil)
    }
    
}

