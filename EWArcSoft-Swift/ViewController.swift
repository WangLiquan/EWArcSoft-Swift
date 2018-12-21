//
//  ViewController.swift
//  EWArcSoft-Swift
//
//  Created by Ethan.Wang on 2018/12/21.
//  Copyright © 2018 Ethan. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let activateButton = UIButton()
        activateButton.frame = CGRect(x: 50, y: 120, width: 200, height: 100)
        activateButton.backgroundColor = UIColor.gray
        activateButton.setTitle("引擎激活", for: .normal)
        activateButton.addTarget(self, action: #selector(onClickActivateButton), for: .touchUpInside)
        self.view.addSubview(activateButton)
        let cameraButton = UIButton()
        cameraButton.frame = CGRect(x: 50, y: 360, width: 200, height: 100)
        cameraButton.backgroundColor = UIColor.gray
        cameraButton.setTitle("camera模式", for: .normal)
        cameraButton.addTarget(self, action: #selector(onClickCameraButton), for: .touchUpInside)
        self.view.addSubview(cameraButton)
    }

    @objc private func onClickCameraButton(){
        self.present(EWVideoCheckViewController(), animated: true, completion: nil)
    }

    @objc private func onClickActivateButton(){
        let appid = "827JymBcUZD7E5GKisw4jVGL3JvEWAjcJyHkhGzR7iH4"
        let sdkkey = "CSHHVMxni2LNY9VP8tq9UF2japndSZcXvFjxAStdrV9B"
        let engine = ArcSoftFaceEngine()
        let mr = engine.active(withAppId: appid, sdkKey: sdkkey)
        if mr == ASF_MOK || mr == MERR_ASF_ALREADY_ACTIVATED{
            let alertController = UIAlertController(title: "SDK激活成功", message: "", preferredStyle: .alert)
            self.present(alertController, animated: true, completion: nil)
            alertController.addAction(UIAlertAction(title: "确定", style: .cancel, handler: nil))
        }else {
            let result = "SDK激活失败: \(mr)"
            let alertController = UIAlertController(title: result, message: "", preferredStyle: .alert)
            self.present(alertController, animated: true, completion: nil)
            alertController.addAction(UIAlertAction(title: "确定", style: .cancel, handler: nil))
        }
    }

}

