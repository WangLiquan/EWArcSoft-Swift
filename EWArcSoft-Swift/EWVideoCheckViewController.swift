//
//  EWVideoCheckViewController.swift
//  EWArcSoft-Swift
//
//  Created by Ethan.Wang on 2018/12/21.
//  Copyright © 2018 Ethan. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion

let IMAGE_WIDTH = 720
let IMAGE_HEIGHT = 1280

class EWVideoCheckViewController: UIViewController {

    private let motionManager: CMMotionManager = CMMotionManager()
    private var takePhone: Bool = false
    private let showImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: (UIScreen.main.bounds.size.width - 230)/2, y: 231, width: 230, height: 230))
        imageView.layer.cornerRadius = 115
        imageView.layer.masksToBounds = true
        imageView.contentMode = .center
        return imageView
    }()
    private lazy var imageBackView: UIImageView = {
        let imageView = UIImageView(frame: UIScreen.main.bounds)
        imageView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        imageView.isHidden = true
        imageView.addSubview(showImageView)
        return imageView
    }()
    private let scanningImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: (UIScreen.main.bounds.size.width - 230)/2, y: 231, width: 230, height: 230))
        imageView.image = UIImage(named: "scanning")
        return imageView
    }()

    private var cameraController: EWCameraController = EWCameraController()
    private var videoProcessor: ASFVideoProcessor = ASFVideoProcessor()
    private var allFaceRectViewArray: [UIView] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        startMotionManager()

        let uiOrientation = UIApplication.shared.statusBarOrientation
        cameraController.delegate = self
        cameraController.setUpCaptureSession(videoOrientation: AVCaptureVideoOrientation(ui:uiOrientation))
        guard self.cameraController.previewLayer != nil else { return }
        self.view.layer.addSublayer(self.cameraController.previewLayer!)
        self.cameraController.previewLayer?.frame = self.view.layer.frame

        videoProcessor.initProcessor()
        self.view.addSubview(imageBackView)
        self.view.addSubview(scanningImageView)


    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.cameraController.startCaptureSession()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.cameraController.stopCaptureSession()
    }
    private func dataFaceRectToViewFaceRect(faceRect: MRECT) -> CGRect{
        var frameRect: CGRect = CGRect.zero
        let viewFrame = self.view.frame
        let faceWidth = faceRect.right - faceRect.left
        let faceHeight = faceRect.bottom - faceRect.top
        frameRect.size.width = viewFrame.width/CGFloat(IMAGE_WIDTH)*CGFloat(faceWidth)
        frameRect.size.height = viewFrame.height/CGFloat(IMAGE_HEIGHT)*CGFloat(faceHeight)
        frameRect.origin.x = viewFrame.width/CGFloat(IMAGE_WIDTH)*CGFloat(faceRect.left)
        frameRect.origin.y = viewFrame.height/CGFloat(IMAGE_HEIGHT)*CGFloat(faceRect.top)
        return frameRect
    }
    /// 开始陀螺仪判断
    private func startMotionManager(){
        motionManager.startGyroUpdates()
    }
    /// 根据CMSampleBuffer媒体文件获取相片
    private func getImageFromSampleBuffer (buffer:CMSampleBuffer) -> UIImage? {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            if let image = context.createCGImage(ciImage, from: imageRect) {
                return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .up)
            }
        }
        return nil
    }

}


extension EWVideoCheckViewController: EWCameraControllerDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if takePhone == false {

            guard let cameraData = Utility.getCameraData(from: sampleBuffer) else {              return }
            guard let faceInfoArray = self.videoProcessor.process(cameraData) as? [ASFVideoFaceInfo] else {
                Utility.freeCameraData(cameraData)
                return
            }

            DispatchQueue.main.async { [weak self] in
                guard let weakSelf = self else {
                    Utility.freeCameraData(cameraData)
                    return
                }
                if weakSelf.allFaceRectViewArray.count < faceInfoArray.count {
                    for _ in faceInfoArray{
                        let view = UIView()
                        weakSelf.view.addSubview(view)
                        weakSelf.allFaceRectViewArray.append(view)
                    }
                }
                for (index,_) in faceInfoArray.enumerated() {
                    let faceRectView: UIView = weakSelf.allFaceRectViewArray[index]
                    let faceInfo: ASFVideoFaceInfo = faceInfoArray[index]
                    faceRectView.frame = weakSelf.dataFaceRectToViewFaceRect(faceRect: faceInfo.faceRect)
                    guard faceInfo.face3DAngle != nil else {
                        break
                    }
                    guard faceInfo.face3DAngle.status == 0 else {
                        break
                    }
                    guard faceInfo.face3DAngle.rollAngle <= 10 && faceInfo.face3DAngle.rollAngle >= -10 else {
                        break
                    }
                    guard faceInfo.face3DAngle.yawAngle <= 10 && faceInfo.face3DAngle.yawAngle >= -10 else {
                        break
                    }
                    guard faceInfo.face3DAngle.pitchAngle <= 10 && faceInfo.face3DAngle.pitchAngle >= -10 else {
                        break
                    }
                    guard CGRect(x: 30, y: 150, width: UIScreen.main.bounds.size.width - 60, height: UIScreen.main.bounds.size.height-300).contains(faceRectView.frame) else {
                        break
                    }
                    guard let newestAccel = weakSelf.motionManager.gyroData else {
                        break
                    }
                    guard newestAccel.rotationRate.x < 0.005 && newestAccel.rotationRate.y < 0.005 && newestAccel.rotationRate.z < 0.005 else {
                        break
                    }
                    weakSelf.takePhone = true
                    let resultImage = weakSelf.getImageFromSampleBuffer(buffer: sampleBuffer)
                    weakSelf.imageBackView.isHidden = false
                    weakSelf.showImageView.image = resultImage

                    UIView.animate(withDuration: 1.3, animations: {
                        weakSelf.showImageView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
                    }, completion: { (finished) in
                        let animationView = EWRippleAnimationView(frame:CGRect(x: 0, y: 0, width: weakSelf.showImageView.frame.size.width , height: weakSelf.showImageView.frame.size.height))
                        animationView.center = weakSelf.showImageView.center
                        weakSelf.imageBackView.addSubview(animationView)
                        weakSelf.imageBackView.bringSubviewToFront(weakSelf.showImageView)
                        let vc = EWShowImageViewController()
                        vc.image = resultImage
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0, execute: {
                            weakSelf.present(vc, animated: false, completion: nil)
                        })
                    })

                }
            }
            Utility.freeCameraData(cameraData)
        }
    }
}
