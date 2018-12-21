//
//  EWCameraController.swift
//  EWArcSoft-Swift
//
//  Created by Ethan.Wang on 2018/12/21.
//  Copyright © 2018 Ethan. All rights reserved.
//

import UIKit
import AVFoundation

protocol EWCameraControllerDelegate {
    func captureOutput(_ output: AVCaptureOutput,didOutput sampleBuffer: CMSampleBuffer,from connection: AVCaptureConnection)
}

class EWCameraController: NSObject {
    public var delegate: EWCameraControllerDelegate?
    public var previewLayer: AVCaptureVideoPreviewLayer?

    private let captureSession = AVCaptureSession()
    private var videoConnection: AVCaptureConnection?
    private var captureDevice:AVCaptureDevice!

    public func setUpCaptureSession(videoOrientaion: AVCaptureVideoOrientation) -> Bool{
        captureSession.beginConfiguration()
        /// SessionPreset,用于设置output输出流的bitrate或者说画面质量
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        /// 获取输入设备,builtInWideAngleCamera是通用相机,AVMediaType.video代表视频媒体,front表示前置摄像头,如果需要后置摄像头修改为back
        let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .front).devices
        /// 获取前置摄像头
        captureDevice = availableDevices.first
        do {
            /// 将前置摄像头作为session的input输入流
            let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(captureDeviceInput)
        }catch {
            print(error.localizedDescription)
        }

        /// 设定视频预览层,也就是相机预览layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        /// 相机页面展现形式
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill /// 拉伸充满frame
        /// 设定输出流
        let dataOutput = AVCaptureVideoDataOutput()
        /// 指定像素格式
        dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString):NSNumber(value:kCVPixelFormatType_32BGRA)] as [String : Any]
        /// 是否直接丢弃处理旧帧时捕获的新帧,默认为True,如果改为false会大幅提高内存使用
        dataOutput.alwaysDiscardsLateVideoFrames = true
        /// 将输出流加入session
        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
        }
        /// 开新线程进行输出流代理方法调用
        let queue = DispatchQueue(label: "com.brianadvent.captureQueue")
        dataOutput.setSampleBufferDelegate(self, queue: queue)

        videoConnection = dataOutput.connection(with: .video)
        guard videoConnection != nil else {
            return true
        }
        if videoConnection!.isVideoMirroringSupported{
            videoConnection?.isVideoMirrored = true
        }
        if videoConnection!.isVideoOrientationSupported{
            videoConnection?.videoOrientation = .portrait
        }
        if captureSession.canSetSessionPreset(.iFrame1280x720){
            captureSession.sessionPreset = .iFrame1280x720
        }
        return true
    }

    public func startCaptureSession(){
        if !captureSession.isRunning{
            captureSession.startRunning()
        }
    }
    public func stopCaptureSession(){
        captureSession.stopRunning()
    }

}
extension EWCameraController: AVCaptureVideoDataOutputSampleBufferDelegate{
    /// 输出流代理方法,实时调用
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if connection ==  videoConnection{
            self.delegate?.captureOutput(output, didOutput: sampleBuffer, from: connection)
        }
    }
}


extension EWCameraController: EWCameraControllerDelegate{
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

    }

}