//
//  JZSlider.swift
//  JZAVPlayerController
//
//  Created by Jun Zhang on 16/7/28.
//  Copyright © 2016年 Jun Zhang. All rights reserved.
//

import UIKit

protocol JZSliderDelegate: class {
    func beignSlide()
    
    func sliderValueChanged(progress: Double)
    
    func endSlide()
    
}

let kImageViewHalfWidth: CGFloat = 22

class JZSlider: UIView {
    var delegate: JZSliderDelegate?
    var minimumValue = 0.0
    var maximumValue = 1.0
    var backgroundProgress: UIView = UIView()
    var bufferProgress: UIView = UIView()
    var finishProgress: UIView = UIView()
    var jzThumbButton: JZThumbButton = JZThumbButton()
    var lastPointX: CGFloat = 0.0
    var sliderRate: Float? = 0.0
    var fininshValue: Double = 0.0 {
        didSet {
            finishProgress.frame.size.width = (self.width - 2 * kImageViewHalfWidth) * CGFloat(fininshValue)
            jzThumbButton.center.x = finishProgress.width + finishProgress.frame.origin.x
            if fininshValue > trackValue {
                JZPlayerManager.sharedInstance.status = .BufferEmpty
            } else {
                JZPlayerManager.sharedInstance.status = .BufferReady
            }
        }
    }
    var trackValue: Double = 0.0 {
        didSet {
            bufferProgress.frame.size.width = (self.width - 2 * kImageViewHalfWidth) * CGFloat(trackValue)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        createSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        createSubviews()
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        resizeSubViewsIfNeeded(rect)
    }
    
    func createSubviews() {
        let y = (frame.size.height - progressHieght) * 0.5
        let point = CGPoint(x: kImageViewHalfWidth, y: y)
        
        configView(backgroundProgress, color: UIColor.lightGrayColor(), frame: CGRect(origin: point, size: CGSize(width: frame.size.width, height: progressHieght)))
        configView(bufferProgress, color: UIColor.whiteColor(), frame: CGRect(origin: point, size: CGSize(width: 0, height: progressHieght)))
        configView(finishProgress, color: UIColor.yellowColor(), frame: CGRect(origin: point, size: CGSize(width: 0, height: progressHieght)))
        configView(jzThumbButton, color: UIColor.clearColor(), frame: CGRect(origin: CGPoint(x:0,y:0), size: CGSize(width: 44, height: 44)))
        jzThumbButton.addTarget(self, action: #selector(drag(_:event:)), forControlEvents: .TouchDragInside)
        jzThumbButton.addTarget(self, action: #selector(sliderBegin), forControlEvents: .TouchDown)
        jzThumbButton.addTarget(self, action: #selector(sliderEnd), forControlEvents: .TouchUpInside)
        jzThumbButton.addTarget(self, action: #selector(sliderEnd), forControlEvents: .TouchUpOutside)
        jzThumbButton.addTarget(self, action: #selector(sliderEnd), forControlEvents: .TouchCancel)
    }
    
    func configView(progress: UIView, color: UIColor, frame: CGRect) {
        progress.frame = frame
        self.addSubview(progress)
        progress.backgroundColor = color
    }
    
    func resizeSubViewsIfNeeded(rect: CGRect) {
        let point = CGPoint(x: kImageViewHalfWidth, y: (rect.size.height - progressHieght) * 0.5)
        backgroundProgress.frame = CGRect(origin: point, size: CGSize(width: rect.size.width - kImageViewHalfWidth * 2, height: progressHieght))
        bufferProgress.frame = CGRect(origin: point, size: CGSize(width: 0, height: progressHieght))
        finishProgress.frame = CGRect(origin: point, size: CGSize(width: 0, height: progressHieght))
        jzThumbButton.frame = CGRect(origin: CGPoint(x:backgroundProgress.frame.origin.x,y:0), size: CGSize(width: kImageViewHalfWidth * 2, height: kImageViewHalfWidth * 2))
        jzThumbButton.center.x = backgroundProgress.frame.origin.x
//        jzThumbButton.alpha = 0.3
        lastPointX = jzThumbButton.center.x
    }
    
    func drag(button: UIButton, event: UIEvent) {
        let point = (event.allTouches())?.map {
            $0.locationInView(self)
        }
        print(point, lastPointX)
        if let x = point?.last?.x {
            button.center.x += x - lastPointX
            
            if button.center.x >= self.width - kImageViewHalfWidth {
                button.center.x = self.width - kImageViewHalfWidth
            } else if button.center.x <= kImageViewHalfWidth {
                button.center.x = kImageViewHalfWidth
            }
            lastPointX = button.center.x
            finishProgress.frame.size.width = button.center.x - kImageViewHalfWidth
            fininshValue = Double(finishProgress.frame.size.width / (self.width - kImageViewHalfWidth * 2))
        }
        
        print(fininshValue)
        delegate?.sliderValueChanged(fininshValue)
    }
    
    func sliderBegin() {
        if JZPlayerManager.sharedInstance.bufferEmptyPause == true {
            (self.superview as? JZPlayerView)?.player?.rate = 0.0
        } else {
            (self.superview as? JZPlayerView)?.player?.pause()
        }
        delegate?.beignSlide()
    }
    func sliderEnd() {
        
//        (self.superview as? JZPlayerView)?.player?.play()
        delegate?.endSlide()
    }
}
