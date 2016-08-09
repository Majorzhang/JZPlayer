//
//  JZPlayer.swift
//  JZAVPlayerController
//
//  Created by Jun Zhang on 16/7/26.
//  Copyright © 2016年 Jun Zhang. All rights reserved.
//

import UIKit
import AVFoundation
let progressHieght: CGFloat = 3.0

class JZPlayerItem: AVPlayerItem {
    deinit {
        let dict: [String] = [KeyPath.status, KeyPath.playbackLikelyToKeepUp,KeyPath.playbackBufferEmpty, KeyPath.loadedTimeRanges]
        removeObservers(JZPlayerManager.sharedInstance, keyPathArray: dict)
    }
}

class JZPlayer: AVPlayer {
    
    var duration: CMTime? {
        get {
          let playerDuration =  (self.currentItem?.status == .ReadyToPlay) ? self.currentItem?.duration : kCMTimeInvalid
            return playerDuration
        }
    }
    
    var currentDuration: Float64 {
        get {
            return CMTimeGetSeconds(self.currentTime()) ?? 0.0
        }
    }
    
    func removeObservers() {
        let dict = [KeyPath.currentItem, KeyPath.rate]
//        let context = [UnsafePointer.currentItem, UnsafePointer.rate]
        removeObservers(JZPlayerManager.sharedInstance, keyPathArray: dict)
    }
    
    deinit {
        removeObservers()
    }
}


func Font(size: CGFloat) -> UIFont {
    return  UIFont.systemFontOfSize(size)
}
func isLandscape() -> Bool {
    if UIScreen.mainScreen().bounds.width > UIScreen.mainScreen().bounds.height {
        return true
    }
    return false
}

protocol JZPlayerViewDelegate: class {
    func playProgressChange(initalize: Bool)
    
    func bufferValueChanged(progress: Double)
}

class JZPlayerView: UIView {

    var url: NSURL? {
        didSet {
            if url != nil && url != oldValue {
                JZPlayerManager.sharedInstance.playWithUrl(url!, onView: self)
            }
        }
    }
    var timeObserver: AnyObject?
    var currentTimeLabel = UILabel()
    var totalTimeLabel = UILabel()
//    var slider: UISlider!
    var jzSlider: JZSlider!
    var player: JZPlayer?
    var hud: JZHUD!
    var playButton = UIButton()
    
    deinit {
        
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        createSubViews(frame)
    }
    
    func createSubViews(rect: CGRect) {
        userInteractionEnabled = true
        hud = JZHUD(frame: rect)
        self.addSubview(hud)
        configTimeLabel(CGRectMake(10, rect.size.height - 44, 44, 44), observer: currentTimeLabel)
        configTimeLabel(CGRectMake(rect.size.width - 54, rect.size.height - 44, 44, 44), observer: totalTimeLabel)
        jzSlider = JZSlider(frame:CGRect(x: 54, y: rect.size.height - 44, width: rect.size.width - 54 * 2, height: 44))
        jzSlider.delegate = self
        jzSlider.backgroundColor = UIColor.clearColor()
        addSubview(jzSlider)
        playButton.setImage(UIImage(named: "normal"), forState: .Normal)
        playButton.setImage(UIImage(named: "pause"), forState: .Selected)
        playButton.selected = false
        playButton.addTarget(self, action: #selector(playAction), forControlEvents: .TouchUpInside)
        addSubview(playButton)
        addTapGesture()
    }
    
    func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        self.addGestureRecognizer(tapGesture)
    }
    
     func tapAction() {
        playButton.hidden = !playButton.hidden
    }
     func playAction() {
        if playButton.selected {
            JZPlayerManager.sharedInstance.forcePause = true
            player?.pause()
        } else {
            JZPlayerManager.sharedInstance.forcePause = false
            if  JZPlayerManager.sharedInstance.status == .End {
               jzSlider.fininshValue = 0.0
                sliderValueChanged(0.0)
            }
            player?.play()
        }
        playButton.selected = !playButton.selected
    }
    
    func configTimeLabel(rect: CGRect, observer: UILabel) {
        observer.frame = rect
        observer.font = Font(9)
        observer.textColor = UIColor.whiteColor()
        observer.text = "00:00:00"
        self.addSubview(observer)
    }
    
    func resizeSubViewsIfNeeded(rect: CGRect) {
        hud.frame = rect
        currentTimeLabel.frame = CGRectMake(10, rect.size.height - 44, 44, 44)
        totalTimeLabel.frame = CGRectMake(rect.size.width - 54, rect.size.height - 44, 44, 44)

        jzSlider.frame = CGRect(x: 54, y: rect.size.height - 44, width: rect.size.width - 54 * 2, height: 44)
        playButton.center = center
        playButton.bounds.size = CGSize(width: 44, height: 44)
        hud.setNeedsDisplay()
        jzSlider.setNeedsDisplay()
    }
    
    convenience init(frame: CGRect, url: NSURL) {
       self.init(frame: frame)
        self.url = url
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(orientation(_:)), name: UIDeviceOrientationDidChangeNotification, object: nil)
        createSubViews(self.frame)
    }
    
    func orientation(noti: NSNotification) {
        resizeSubViewsIfNeeded(self.frame)
    }
    override class func layerClass() -> AnyClass {
        return AVPlayerLayer.self
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        resizeSubViewsIfNeeded(rect)

    }
    
    func addTimeObserver() {
        if self.timeObserver == nil {
            timeObserver =  player?.addPeriodicTimeObserverForInterval(CMTimeMake(1, 1), queue: nil, usingBlock: { (time: CMTime) in
                self.playProgressChange(false)
            })
        }
    }

}

extension JZPlayerView: JZSliderDelegate {
    
    func sliderValueChanged(progress: Double) {
        let duration =  CMTimeGetSeconds(self.player?.duration ?? kCMTimeZero)
        let seconds = duration * progress
        let preferredTimeScale : Int32 = 1
        let time = CMTimeMakeWithSeconds(seconds, preferredTimeScale)
        player?.seekToTime(time)
    }

    func endSlide() {
        addTimeObserver()
        if jzSlider.sliderRate > 0 || !JZPlayerManager.sharedInstance.forcePause {
            player?.rate = 1.0
            jzSlider.sliderRate = 0.0
        }
    }
    
    func beignSlide() {
        jzSlider.sliderRate = player?.rate
        if JZPlayerManager.sharedInstance.bufferEmptyPause {
            player?.rate = 0
        } else {
            player?.pause()
        }
    }
    
    func parseTime(time: Double) -> String {
        let hour =  floor(time / (60.0*60))
        let minute = Int(fmod(time / 60, 60))
        let floatMinute = Double(minute)
        let seconds = fmod(time, 60)
        let str = String(format: "%02.0f:%02.0f:%02.0f",hour, floatMinute, seconds)
//        print(hour,minute,seconds)
        return str
    }
    
}

extension JZPlayerView: JZPlayerViewDelegate {
    
    func bufferValueChanged(progress: Double) {
        jzSlider.trackValue = progress
    }

    func playProgressChange(initalize: Bool) {
        let duration = self.player?.duration ?? kCMTimeZero
        if duration == kCMTimeInvalid {
            if !initalize {
                jzSlider.minimumValue = 0.0
            }
            return
        }
        let  durationSeconds = CMTimeGetSeconds(duration)
        let time = self.player?.currentDuration ?? 0.0
        
        currentTimeLabel.adjustsFontSizeToFitWidth = true
        currentTimeLabel.text = parseTime(time)
        if initalize {
           totalTimeLabel.text = parseTime(durationSeconds)
            timeObserver =  player?.addPeriodicTimeObserverForInterval(CMTimeMake(1, 1), queue: nil, usingBlock: { (time: CMTime) in
                self.playProgressChange(false)
            })
        } else {
            let fininshValue = (jzSlider.maximumValue - jzSlider.minimumValue) * time / durationSeconds
            jzSlider.fininshValue = fininshValue
        }
    }
    
}


class JZThumbButton: UIButton {
    var maskImageView: UIImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createSubview(frame)
    }
    
    func createSubview(frame: CGRect) {
        maskImageView.center = self.center
        maskImageView.backgroundColor = UIColor.redColor()
        maskImageView.frame.size = CGSizeMake(15, 15)
        maskImageView.layer.cornerRadius = frame.size.width * 0.5
        maskImageView.layer.masksToBounds = true
        self.addSubview(maskImageView)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        createSubview(self.frame)
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        resizeSubviewIfNeeded(rect)
    }
 
    func resizeSubviewIfNeeded(rect: CGRect) {
        maskImageView.frame = CGRectMake(0, rect.size.height * 0.5 + rect.origin.y - 7.5, 15, 15)
        maskImageView.layer.cornerRadius = 7.5
        maskImageView.center.x = self.center.x + 7.5
        maskImageView.frame.size = CGSizeMake(15, 15)
    }
    
}

extension UIView {
    var width: CGFloat {
        get {
            return self.frame.size.width
        }
    }
    
    var height: CGFloat {
        return self.frame.size.height
    }
}