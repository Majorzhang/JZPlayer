//
//  JZPlayerManager.swift
//  JZAVPlayerController
//
//  Created by Jun Zhang on 16/7/26.
//  Copyright © 2016年 Jun Zhang. All rights reserved.
//

import UIKit
import AVFoundation
let JZPlayable = "playable"
let JZFailure = "failure"
struct KeyPath {
    static var playbackBufferEmpty = "playbackBufferEmpty"
    static var playbackLikelyToKeepUp = "playbackLikelyToKeepUp"
    static var status = "status"
    static var loadedTimeRanges = "loadedTimeRanges"
    static var currentItem = "currentItem"
    static var rate = "rate"

}

struct UnsafePointer {
    static var playbackBufferEmpty: UInt8 = 0
    static var playbackLikelyToKeepUp: UInt8 = 0
    static var status: UInt8 = 0
    static var loadedTimeRanges: UInt8 = 0
    static var currentItem: UInt8 = 0
    static var rate: UInt8 = 0

}

enum JZPlayerStatus {
    case Prepare
    case Begin
    case Playing
    case Pause
    case End
    case BufferEmpty
    case BufferReady
    case PlayFailed
    case Unknow
}

class JZPlayerManager: NSObject {

    var currentView: JZPlayerView!
    var delegate: JZPlayerViewDelegate?
    var assetItemPlayer: JZPlayerItem?
    var terminated = false
    var jzUrl: NSURL?
    var enterBackground = false
    var bufferEmptyPause = false
    var forcePause = false
    
    class var sharedInstance: JZPlayerManager {
        struct Static {
            static var once: dispatch_once_t = 0
            static var instance: JZPlayerManager? = nil
        }
        dispatch_once(&Static.once) {
            Static.instance = JZPlayerManager()
        }
        return Static.instance!
    }
    
    var status: JZPlayerStatus = .Prepare {
        didSet {
            if status != oldValue {
                updateStatus()
            }
        }
    }
    
    func updateStatus() {
        switch status {
        case .Prepare:
            debugPrint("Prepare")
            currentView.hud.hidden = false
        case .Begin:
            currentView.hud.hidden = true
        case .BufferEmpty:
            currentView.hud.hidden = false
        case .End:
            currentView.hud.hidden = true
            currentView.playButton.hidden = false
            currentView.playButton.selected = false
        default:
            currentView.hud.hidden = true
        }
    }
    
    func playWithUrl(url: NSURL, onView: JZPlayerView) {
        self.delegate = onView
        if url != jzUrl {
            let assest = AVURLAsset(URL: url, options: nil)
            let requestedKeys = [JZPlayable]
            currentView = onView
            assest.loadValuesAsynchronouslyForKeys(requestedKeys, completionHandler: {
              dispatch_async(dispatch_get_main_queue(), { 
                if !self.terminated {
                    self.validate(assest, keys: requestedKeys)
                }
              })
            })
        }
    }
    
    private func validate(asset: AVURLAsset, keys: [String]) {
        for key in keys {
            var error: NSError? = nil
            let status = asset.statusOfValueForKey(key, error: &error)
            if status == .Failed {
                removeAllObserver()
                return
            }
        }
        if !asset.playable {
            let localLizedDescription = NSLocalizedString(JZPlayable, comment: "cant not play")
            let localLizedDescriptionFailure = NSLocalizedString(JZPlayable + JZFailure  , comment: "cant not play due to unknown reason")
            
            let error =  NSError(domain: JZPlayable, code: 0, userInfo: [NSLocalizedDescriptionKey: localLizedDescription,
                NSLocalizedFailureReasonErrorKey: localLizedDescriptionFailure])
            assetFailure(error)
            return
        }
        assetItemPlayer = JZPlayerItem(asset: asset)
        if assetItemPlayer != nil {
            let player = JZPlayer(playerItem: assetItemPlayer!)
            currentView.player = player
            (currentView.layer as! AVPlayerLayer).player = player
            (currentView.layer as! AVPlayerLayer).videoGravity = AVLayerVideoGravityResizeAspectFill
            status = .Begin
            player.play()
            currentView.playButton.selected = true
          let dict = [KeyPath.currentItem, KeyPath.rate]
          let context = [UnsafePointer.currentItem, UnsafePointer.rate]
          player.addObservers(self, keyPathArray: dict, options: .New, context: context)
        }

        let dict: [String] = [KeyPath.status, KeyPath.playbackLikelyToKeepUp,KeyPath.playbackBufferEmpty, KeyPath.loadedTimeRanges]
        let context: [UInt8] = [UnsafePointer.status, UnsafePointer.playbackLikelyToKeepUp,UnsafePointer.playbackBufferEmpty, UnsafePointer.loadedTimeRanges]
        
        assetItemPlayer?.addObserver(self, keyPathArray: dict, options: .New, context: context)
        notificationCenterWork()
        
    }
    
    func assetFailure(error: NSError?) {
        
    }
    
    
    func removeAllObserver() {
        
    }
    
    func notificationCenterWork() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(playerItemEnd), name: AVPlayerItemDidPlayToEndTimeNotification, object: assetItemPlayer)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(appEnterForeground), name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(appEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    
    func playerItemEnd() {
        
    }
    
    func appEnterForeground() {
//        self.player
    }
    
    func appEnterBackground() {
        
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath != nil {
            switch keyPath! {
            case KeyPath.status:
                AVPlayerItemStatus.Unknown
                let status: AVPlayerItemStatus = AVPlayerItemStatus(rawValue: (change?[NSKeyValueChangeNewKey] as? Int) ?? 0)!
                switch status {
                case .Unknown:
                    removeTimeObserver()
                    delegate?.playProgressChange(false)
                    self.status = .Unknow
                case .ReadyToPlay:
                    if enterBackground {
                        enterBackground = !enterBackground
                    } else {
                        delegate?.playProgressChange(true)
                    }
                case  .Failed:
                    assetFailure(assetItemPlayer?.error)
                }
            case KeyPath.rate :
                print(currentView.player?.rate)
                if currentView.player?.rate == 0 {
                    if forcePause {
                        status = .Pause
                    } else {
                        if currentView.jzSlider.fininshValue >= 1.0 {
                            status = .End
                        } else {
                            bufferEmptyPause = true
                            status = .Prepare
                        }
                    }
                } else if currentView.player?.rate == 1 {
                    forcePause = false
                    bufferEmptyPause = false
                    status = .Begin
                }
            case KeyPath.currentItem:
                if let newPlayerItem = change?[NSKeyValueChangeNewKey] as? JZPlayer{
                    currentView.player = newPlayerItem
                    (currentView.layer as! AVPlayerLayer).player = newPlayerItem
                }
            case KeyPath.loadedTimeRanges:
                let times = assetItemPlayer?.loadedTimeRanges.first
                var range = CMTimeRange()
                times?.getValue(&range)
                let bufferValue = CMTimeGetSeconds(range.start) + CMTimeGetSeconds(range.duration)
                if bufferValue.isNaN{
                    debugPrint("invalid Nan number")
                } else {
                    async({
                        self.updateBufferProgress(bufferValue)
                    })
                }
            default:
                break
            }
        }
//        print("test")
    }

    
    func removeTimeObserver() {
        
    }
    
    func updateBufferProgress(bufferValue: Float64) {
        let playerDuration =  currentView.player?.duration
        
        if playerDuration?.value  > 0 {
            let bufferProgress = bufferValue / CMTimeGetSeconds(playerDuration!)
            delegate?.bufferValueChanged(bufferProgress)

            let sliderProgress = CMTimeGetSeconds(currentView.player?.currentTime() ?? kCMTimeZero) / CMTimeGetSeconds(playerDuration!)
            if  bufferProgress > (sliderProgress + 0.01) && currentView.player?.rate == 0 &&  bufferEmptyPause {
//              if bufferEmptyPause
                //MARK: TO DO
                currentView.player?.play()
            }
        }
    }
    
    
}

extension AVPlayerItem {
    func addObserver(observer: NSObject, keyPathArray: [String],options: NSKeyValueObservingOptions,  context:[UInt8]) {
        var contexts = context
        for index in 0..<keyPathArray.count {
            self.addObserver(observer, forKeyPath: keyPathArray[index], options: .New, context: &contexts[index])
        }
    }
    
//    override func removeObservers(observer: NSObject, keyPathArray: [String]) {
//        for index in 0..<keyPathArray.count {
//            self.removeObserver(observer, forKeyPath: keyPathArray[index])
//        }
//    }
//
}

//extension AVPlayer {
//    func addObservers(observer: NSObject, keyPathArray: [String],options: NSKeyValueObservingOptions,  context:[UInt8]) {
//        var contexts = context
//        for index in 0..<keyPathArray.count {
//            self.addObserver(observer, forKeyPath: keyPathArray[index], options: .New, context: &contexts[index])
//        }
//    }
//
//    func removeObservers(observer: NSObject, keyPathArray: [String]) {
//        for index in 0..<keyPathArray.count {
//            self.removeObserver(observer, forKeyPath: keyPathArray[index])
//        }
//    }
//
//    
//}


extension NSObject {
    func addObservers(observer: NSObject, keyPathArray: [String],options: NSKeyValueObservingOptions,  context:[UInt8]) {
        var contexts = context
        for index in 0..<keyPathArray.count {
            self.addObserver(observer, forKeyPath: keyPathArray[index], options: .New, context: &contexts[index])
        }
    }
    
    func removeObservers(observer: NSObject, keyPathArray: [String]) {
        for index in 0..<keyPathArray.count {
            self.removeObserver(observer, forKeyPath: keyPathArray[index])
        }
    }
    
}

func async(block: (()->Void)) {
    dispatch_async(dispatch_get_main_queue()) {
        block()
    }
}
