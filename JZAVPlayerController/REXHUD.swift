//
//  REXHUD.swift
//  JZAVPlayerController
//
//  Created by Jun Zhang on 16/8/4.
//  Copyright © 2016年 Jun Zhang. All rights reserved.
//

import UIKit

class REXHUD: UIWindow {
        
    //    var backgroundWindow: UIWindow!
    var indicatorView: UIView!
    var imageOuter: UIImageView!
    var imageCenter: UIImageView!
    var imageInner: UIImageView!
    
    let indicatorSize =  50.0
    var animationDuration = 0.3
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(REXHUD.rotated), name: UIDeviceOrientationDidChangeNotification, object: nil)
        
        self.backgroundColor = UIColor.clearColor()
        
        self.initSubViews()
        
        // update frame
//        self.updatePosition()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawRect(rect: CGRect) {
//        self.updatePosition()
    }
    
    private func initSubViews(){
        let screenWidth = UIScreen.mainScreen().bounds.width
        let screenHeight = UIScreen.mainScreen().bounds.height
        indicatorView = UIView(frame: CGRect(x: (Double(screenHeight) - indicatorSize)/2, y: (Double(screenWidth) - indicatorSize)/2, width: indicatorSize, height: indicatorSize))
        indicatorView.backgroundColor = UIColor.clearColor()
        indicatorView.layer.cornerRadius = 8;
        self.addSubview(indicatorView)
        
        imageOuter = UIImageView(frame: CGRect(x: 0, y: 0, width: indicatorSize, height: indicatorSize))
        imageOuter.image = UIImage(named: "loading_outer")
        indicatorView.addSubview(imageOuter)
        
        imageCenter = UIImageView(frame: CGRect(x: 0, y: 0, width: indicatorSize, height: indicatorSize))
        imageCenter.image = UIImage(named: "loading_center")
        indicatorView.addSubview(imageCenter)
        
        imageInner = UIImageView(frame: CGRect(x: 0, y: 0, width: indicatorSize, height: indicatorSize))
        imageInner.image = UIImage(named: "loading_inner")
        indicatorView.addSubview(imageInner)
    }
    
    func rotated()
    {
//        self.updatePosition()
    }
    
//    private func updatePosition() {
//        let screenWidth = UIScreen.mainScreen().bounds.width
//        let screenHeight = UIScreen.mainScreen().bounds.height
//        
//        if(REXUtilities.isLandscape())
//        {
//            self.frame = CGRect(x: 0, y: 0, width: screenHeight, height: screenWidth)
//            indicatorView.frame = CGRect(x: (Double(screenHeight) - indicatorSize)/2, y: (Double(screenWidth) - indicatorSize)/2, width: indicatorSize, height: indicatorSize)
//        } else {
//            self.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
//            indicatorView.frame = CGRect(x: (Double(screenWidth) - indicatorSize)/2, y: (Double(screenHeight) - indicatorSize)/2, width: indicatorSize, height: indicatorSize)
//        }
//    }
    
    private func rotationAnimation(speed: Double) -> CABasicAnimation{
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(M_PI * 2.0)
        rotateAnimation.duration = speed
        rotateAnimation.cumulative = false;
        rotateAnimation.repeatCount = Float.infinity;
        rotateAnimation.removedOnCompletion=false;
        rotateAnimation.fillMode=kCAFillModeForwards;
        rotateAnimation.autoreverses = false;
        rotateAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        return rotateAnimation
    }
    
    func showHUD(){
        
        self.hidden = false
        UIView.animateWithDuration(0.2) {
            UIApplication.sharedApplication().keyWindow?.alpha = 0.5
        }
        print(self, UIApplication.sharedApplication().keyWindow)
        //        self.makeKeyAndVisible()
        
        imageOuter.layer.addAnimation(self.rotationAnimation(animationDuration*3), forKey:"outer")
        imageCenter.layer.addAnimation(self.rotationAnimation(animationDuration*2), forKey:"center")
        imageInner.layer.addAnimation(self.rotationAnimation(animationDuration), forKey:"inner")
        
//        self.updatePosition()
    }
    
    func hideHUD(){
        self.hidden = true
        UIApplication.sharedApplication().keyWindow?.alpha = 1.0
        
        imageOuter.layer.removeAnimationForKey("outer")
        imageCenter.layer.removeAnimationForKey("center")
        imageInner.layer.removeAnimationForKey("inner")
    }
}
