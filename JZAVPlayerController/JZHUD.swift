//
//  jzHUD.swift
//  JZAVPlayerController
//
//  Created by Jun Zhang on 16/8/4.
//  Copyright © 2016年 Jun Zhang. All rights reserved.
//

import UIKit
import Foundation
let G_PI = CGFloat(M_PI)
class JZHUD: UIView {
 
    var shapeLayer = CAShapeLayer()
    var path: UIBezierPath!
    var shapeView = UIView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        addCircleLayer()
    }
    
    private func addCircleLayer() {
        self.backgroundColor = UIColor.clearColor()
        path = UIBezierPath(arcCenter: self.center, radius: 10, startAngle: 0, endAngle: G_PI * 1.00, clockwise: true)
        shapeLayer.path = path.CGPath
        shapeLayer.lineWidth = 2
        shapeLayer.fillColor = UIColor.clearColor().CGColor
        shapeLayer.strokeColor = UIColor.whiteColor().CGColor
        shapeView.layer.addAnimation(configAnimation(), forKey: "rotate")
        shapeView.center = self.center
        shapeView.backgroundColor = UIColor.clearColor()
        shapeView.bounds.size = CGSize(width: 30, height: 30)
        shapeView.layer.addSublayer(shapeLayer)
        addSubview(shapeView)
        userInteractionEnabled = true
    }
    
    
    private func configAnimation() -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.duration = 0.5
        animation.toValue = G_PI * 2
        animation.repeatCount = Float.infinity
        animation.removedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        return animation
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addCircleLayer()
    }
 
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        shapeView.center = center
        shapeView.bounds.size = CGSize(width: 30, height: 30)
        path = UIBezierPath(arcCenter: CGPoint(x: 15, y: 15), radius: 15, startAngle: 0, endAngle: G_PI * 1.0, clockwise: true)
        shapeLayer.path = path.CGPath
    }
    
}
