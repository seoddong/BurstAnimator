//
//  File.swift
//  BurstAnimator
//
//  Created by SeoDongHee on 2016. 5. 2..
//  Copyright © 2016년 SeoDongHee. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class ImagesToVideo {
    
    var sender: AnyObject
    
    init(sender: AnyObject) {
        self.sender = sender
    }
    
    func saveVideoFromImages(arrayImages: NSArray, outputSize: CGSize) -> String {
        
        
        let tempPath = NSTemporaryDirectory().stringByAppendingString("temp.mp4")
        do {
            try NSFileManager.defaultManager().removeItemAtPath(tempPath)
            debugPrint("removeItemAtPath = success..")
        }
        catch {
            debugPrint("removeItemAtPath = error occured...")
        }
        
        
        var videoWriter: AVAssetWriter!
        do {
            videoWriter = try AVAssetWriter(URL: NSURL(fileURLWithPath: tempPath), fileType: AVFileTypeMPEG4)
            debugPrint("videoWriter = \(videoWriter)")
        }
        catch {
            debugPrint("AVAssetWriter is failed..")
        }
        
        
        let videoSettings: [String: AnyObject] = [
            AVVideoCodecKey : AVVideoCodecH264,
            AVVideoWidthKey : NSNumber(integer: Int(outputSize.width)),
            AVVideoHeightKey : NSNumber(integer: Int(outputSize.height))
        ]
        
        let input = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)
        videoWriter.addInput(input)
        videoWriter.startWriting()
        videoWriter.startSessionAtSourceTime(kCMTimeZero)
        
        var pixelBufferPointer = UnsafeMutablePointer<CVPixelBuffer?>.alloc(1)
        CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, pixelBufferPointer)
        
        // 아래 10은 10fps를 의미한다.
        let fps: Int32 = 10
        
        var ii = 0
        
        // 초당 10프레임짜리 중 0번째 프레임을 의미함
        var presentTime = CMTimeMake(Int64(ii), fps)
        
        debugPrint("presentTime = \(presentTime)")
        var boolWhile = true
        var readyForMoreMediaDataFalseCount = 0
        while (boolWhile) {
            
            // 아래 autoreleasepool 찾는데 한 4일 걸렸다. 이 코드를 사용하지 않으면 memory usage가 계속 올라가서 500메가도 넘다가 결국 앱이 죽고 만다.
            autoreleasepool({() -> () in
                
                if(input.readyForMoreMediaData) {
                    presentTime = CMTimeMake(Int64(ii), fps)
                    
                    if(ii >= arrayImages.count){
                        pixelBufferPointer.dealloc(1)
                        //pixelBufferPointer.destroy()
                        pixelBufferPointer = nil
                        
                        input.markAsFinished()
                        videoWriter.endSessionAtSourceTime(presentTime)
                        videoWriter.finishWritingWithCompletionHandler({ () -> Void in
                            if videoWriter.status == AVAssetWriterStatus.Failed {
                                debugPrint("oh noes, an error: \(videoWriter.error!.description)")
                            } else {
                                debugPrint("hrmmm, there should be a movie?")
                                UISaveVideoAtPathToSavedPhotosAlbum(tempPath, self, nil, nil);
                                debugPrint("saved..")
                                boolWhile = false
                            }
                        })
                        
                    }
                    else {

                        //pixelBufferPointer = self.pixelBufferFromCGImage(arrayImages[ii] as! CGImage, size: outputSize)
                        self.pixelBufferFromCGImage(arrayImages[ii] as! UIImage, size: outputSize, pxbuffer: pixelBufferPointer)
                        
                        //debugPrint("ii=\(ii)")
                        while (!input.readyForMoreMediaData) {
                            // 초당 10프레임짜리 3초 짜리 동영상 만드는데 여기 5000번 가량 들어온다. 10ms씩 재워주면 1000번 가량으로 줄어든다.
                            usleep(10);
                        }
                        adaptor.appendPixelBuffer(pixelBufferPointer.memory!, withPresentationTime: presentTime)

                        
                        ii += 1
                    }
                    
                }
                else {
                    readyForMoreMediaDataFalseCount += 1
                    //debugPrint("\(readyForMoreMediaDataFalseCount): readyForMoreMediaData is false at ii = \(ii)")
                }
            })
        }

        return tempPath
        
    }
    
    //func pixelBufferFromCGImage(image: CGImage, size: CGSize) -> UnsafeMutablePointer<CVPixelBuffer?> {
    func pixelBufferFromCGImage(image: UIImage, size: CGSize, pxbuffer: UnsafeMutablePointer<CVPixelBuffer?>) {
        
        // UIImage를 쉽게 CGImage로 바꿀 수 없다는 것을 알았다. 아래의 과정을 거쳐야만 한다. 검은 화면이 나오는 것도 다 이런 이유였다.
        let ciimage = CIImage(image: image)
        let cgimage = convertCIImageToCGImage(ciimage!)

        // 아래 주석문의 Objective-C 구문을 swift로 변경하기 위해 이렇게 기나긴 코드를 작성해야 하다니!!
        // 오죽하면 아래 코드의 원작자도 stupid라는 주석을 달아놓았다!! ㅋㅋ
        /*
         NSDictionary *options = @{(id)kCVPixelBufferCGImageCompatibilityKey: @YES,
         (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES};
        */
        // stupid CFDictionary stuff
        let keys: [CFStringRef] = [kCVPixelBufferCGImageCompatibilityKey, kCVPixelBufferCGBitmapContextCompatibilityKey]
        let values: [CFTypeRef] = [kCFBooleanTrue, kCFBooleanTrue]
        let keysPointer = UnsafeMutablePointer<UnsafePointer<Void>>.alloc(1)
        let valuesPointer =  UnsafeMutablePointer<UnsafePointer<Void>>.alloc(1)
        keysPointer.initialize(keys)
        valuesPointer.initialize(values)
        //let options = CFDictionaryCreate(kCFAllocatorDefault, keysPointer, valuesPointer, keys.count, UnsafePointer<CFDictionaryKeyCallBacks>(), UnsafePointer<CFDictionaryValueCallBacks>())
        // 원래 위 코드였는데 swift3에서 변경되었다고 한다.
        let options = CFDictionaryCreate(kCFAllocatorDefault, keysPointer, valuesPointer, keys.count, nil, nil)
        // 여기까지가 CFDictionary를 위한 코드

        
        
        //let pxbuffer = UnsafeMutablePointer<CVPixelBuffer?>.alloc(1)
        // pxbuffer = nil 할 경우 status = -6661 에러 발생한다.
        var status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height),
                                         kCVPixelFormatType_32ARGB, options, pxbuffer)
        debugPrint("status = \(status)")
        status = CVPixelBufferLockBaseAddress(pxbuffer.memory!, 0);
        
        let bufferAddress = CVPixelBufferGetBaseAddress(pxbuffer.memory!);
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        let context = CGBitmapContextCreate(bufferAddress, Int(size.width),
                                            Int(size.height), 8, 4*Int(size.width), rgbColorSpace,
                                            CGImageAlphaInfo.NoneSkipFirst.rawValue);
        //debugPrint("image = \(image)")
        CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(CGImageGetWidth(cgimage)), CGFloat(CGImageGetHeight(cgimage))), cgimage);
        
        /*
        // context에 그림이 제대로 그려졌는지 이미지로 변경하여 확인
        if let contextImage = CGBitmapContextCreateImage(context) {
            let checkImage = UIImage.init(CGImage: contextImage)
            let parentVC = sender as! AnimateVC
            parentVC.animatedImageView.image = checkImage
            //dispatch_async(dispatch_get_main_queue()) {
            // 이렇게 해도 카메라롤 가면 9장 저장 날렸는데 3~4장 밖에 저장이 안 된다.
//            UIImageWriteToSavedPhotosAlbum(checkImage, nil, nil, nil)
//            debugPrint("save..")
            //}
        }
        else {
            debugPrint("why context is null?")
        }
        */
        
        status = CVPixelBufferUnlockBaseAddress(pxbuffer.memory!, 0);
        

        //return pxbuffer
        
    }
    
    func convertCIImageToCGImage(inputImage: CIImage) -> CGImage! {
        let context = CIContext(options: nil)
        
        return context.createCGImage(inputImage, fromRect: inputImage.extent)

    }
    
    
    
    
    
}