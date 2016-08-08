//
//  ViewController.swift
//  JZAVPlayerController
//
//  Created by Jun Zhang on 16/7/26.
//  Copyright © 2016年 Jun Zhang. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
class ViewController: UIViewController {

    @IBOutlet weak var jzView: JZPlayerView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mp4 = NSBundle.mainBundle().pathForResource("testvide", ofType: "mp4")
        let url = NSURL(fileURLWithPath: mp4!)

        self.view.addSubview(jzView)
        jzView.url = url
    }

    
    @IBAction func testAction(sender: AnyObject) {
        let otherUrl = NSURL(string: "https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")
        jzView.url = otherUrl
//        jzView.hud.showHUD()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        jzView.layer.frame = jzView.frame
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

