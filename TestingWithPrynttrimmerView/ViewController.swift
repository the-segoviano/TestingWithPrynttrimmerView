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


class PlayerView: UIView {
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    private var playerItemContext = 0

    // Keep the reference and use it to observe the loading status.
    private var playerItem: AVPlayerItem?
    
    private func setUpAsset(with url: URL, completion: ((_ asset: AVAsset) -> Void)?) {
        let asset = AVAsset(url: url)
        asset.loadValuesAsynchronously(forKeys: ["playable"]) {
            var error: NSError? = nil
            let status = asset.statusOfValue(forKey: "playable", error: &error)
            switch status {
            case .loaded:
                completion?(asset)
            case .failed:
                print(".failed")
            case .cancelled:
                print(".cancelled")
            default:
                print("default")
            }
        }
    }
    
    private func setUpPlayerItem(with asset: AVAsset) {
        playerItem = AVPlayerItem(asset: asset)
        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: &playerItemContext)
        DispatchQueue.main.async { [weak self] in
            self?.player = AVPlayer(playerItem: self?.playerItem!)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItem.Status
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            // Switch over status value
            switch status {
            case .readyToPlay:
                print(".readyToPlay")
                player?.play()
            case .failed:
                print(".failed")
            case .unknown:
                print(".unknown")
            @unknown default:
                print("@unknown default")
            }
        }
    }
    
    func play(with url: URL) {
        setUpAsset(with: url) { [weak self] (asset: AVAsset) in
            self?.setUpPlayerItem(with: asset)
        }
    }
    
    
    deinit {
        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        print("deinit of PlayerView")
    }
    
}

class ViewController: UIViewController {

    // DEBUG
    // var playerView: UIView!
    var playerContainerView: UIView!
    
    let imagePickerController: UIImagePickerController = UIImagePickerController()
    
    var videoURL: URL?
    
    var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.red.cgColor
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setUpPlayerContainerView()
        
        setUpPlayerView()
        //playVideo()
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
        //self.view.addSubview(imageView)
        
        //playButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 24).isActive = true
        playButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -24).isActive = true
        playButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16).isActive = true
        playButton.widthAnchor.constraint(equalToConstant: 45).isActive = true
        playButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        //openLibrary.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 24).isActive = true
        openLibrary.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -24).isActive = true
        openLibrary.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16).isActive = true
        openLibrary.widthAnchor.constraint(equalToConstant: 45).isActive = true
        openLibrary.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        /*
        imageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        imageView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
        */
    }
    
    // Set  up constraints for the player container view.
    private func setUpPlayerContainerView() {
        playerContainerView = UIView()
        playerContainerView.backgroundColor = .black
        view.addSubview(playerContainerView)
        playerContainerView.translatesAutoresizingMaskIntoConstraints = false
        playerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        playerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        playerContainerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.3).isActive = true
        if #available(iOS 11.0, *) {
            playerContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        } else {
            playerContainerView.topAnchor.constraint(equalTo: topLayoutGuide.topAnchor).isActive = true
        }
        
        let viewControls: UIView = UIView()
        
        //Create Slider
        paybackSlider.minimumValue = 0
        paybackSlider.maximumValue = 10
        paybackSlider.isContinuous = true
        paybackSlider.tintColor = UIColor.gray
        paybackSlider.value = 5
        // paybackSlider.addTarget(self, action: "paybackSliderValueDidChange:",forControlEvents: .ValueChanged)
        
        
    }
    
    let paybackSlider = UISlider()
    
    @objc func paybackSliderValueDidChange(sender: UISlider) {
        print("payback value: \(sender.value)")
        //paybackLabel.text = "\(sender.value)"
    }
    
    @objc func handlePlayPauseButtonPressed(_ sender: UIButton) {
       //  sender.isSelected ?  currentPlayer.pause() :   currentPlayer.play()
        if sender.isSelected {
            // currentPlayer.pause()
        }
        else {
            // currentPlayer.play()
        }
    }
    
    
    // Reference for the player view.
    
    let playerView: PlayerView = PlayerView()
    
    private func setUpPlayerView() {
        playerContainerView.addSubview(playerView)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        playerView.leadingAnchor.constraint(equalTo: playerContainerView.leadingAnchor).isActive = true
        playerView.trailingAnchor.constraint(equalTo: playerContainerView.trailingAnchor).isActive = true
        playerView.heightAnchor.constraint(equalTo: playerContainerView.widthAnchor, multiplier: 16/9).isActive = true
        playerView.centerYAnchor.constraint(equalTo: playerContainerView.centerYAnchor).isActive = true
    }
    
    func playVideo() {
        guard let url = URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4") else { return }
        playerView.play(with: url)
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
            
            playerView.play(with: videoURL)
            
            /*
            let player = AVPlayer(url: videoURL as URL)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            present(playerViewController, animated: true){
                playerViewController.player!.play()
            }
            */
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
        
        /*
        imageView.image = previewImageFromVideo(url: videoURL)!
        imageView.contentMode = .scaleAspectFit
        */
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

