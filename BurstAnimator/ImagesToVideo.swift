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
    
    func saveVideoFromImages(arrayImages: NSArray, outputSize: CGSize) {
        
        
        let tempPath = NSTemporaryDirectory().stringByAppendingString("temp.mp4")
        do {
            try NSFileManager.defaultManager().removeItemAtPath(tempPath)
            print("removeItemAtPath = success..")
        }
        catch {
            print("removeItemAtPath = error occured...")
        }
        
        
        var videoWriter: AVAssetWriter!
        do {
            videoWriter = try AVAssetWriter(URL: NSURL(fileURLWithPath: tempPath), fileType: AVFileTypeMPEG4)
            print("videoWriter = \(videoWriter)")
        }
        catch {
            print("AVAssetWriter is failed..")
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
        var presentTime = CMTimeMake(Int64(ii), fps)
        print("presentTime = \(presentTime)")
        while (true) {
            
            // 아래 autoreleasepool 찾는데 한 4일 걸렸다. 이 코드를 사용하지 않으면 memory usage가 계속 올라가서 500메가도 넘다가 결국 앱이 죽고 만다.
            autoreleasepool({() -> () in
                
                if(input.readyForMoreMediaData) {
                    presentTime = CMTimeMake(Int64(ii), fps)
                    
                    if(ii >= arrayImages.count){
                        pixelBufferPointer.dealloc(1)
                        //pixelBufferPointer.destroy()
                        pixelBufferPointer = nil
                        
                        input.markAsFinished()
                        videoWriter.finishWritingWithCompletionHandler({ () -> Void in
                            if videoWriter.status == AVAssetWriterStatus.Failed {
                                print("oh noes, an error: \(videoWriter.error!.description)")
                            } else {
                                print("hrmmm, there should be a movie?")
                                UISaveVideoAtPathToSavedPhotosAlbum(tempPath, self, nil, nil);
                            }
                        })
                        
                    }
                    else {
                        /*
                         // 아래와 같이 할 수도 있다고 한다.
                         var buffer: CVPixelBuffer?
                         &buffer = self.pixelBufferFromCGImage(arrayImages[ii] as! CGImage, size: outputSize)
                         */
                        //pixelBufferPointer = self.pixelBufferFromCGImage(arrayImages[ii] as! CGImage, size: outputSize)
                        self.pixelBufferFromCGImage(arrayImages[ii] as! CGImage, size: outputSize, pxbuffer: pixelBufferPointer)
                        while (!input.readyForMoreMediaData) {
                            usleep(1);
                        }
                        adaptor.appendPixelBuffer(pixelBufferPointer.memory!, withPresentationTime: CMTimeMake(Int64(ii), 30))
                        
                        ii += 1
                    }
                    
                }
            })
        }
        
        
        
        
        
    }
    
    //func pixelBufferFromCGImage(image: CGImage, size: CGSize) -> UnsafeMutablePointer<CVPixelBuffer?> {
    func pixelBufferFromCGImage(image: CGImage, size: CGSize, pxbuffer: UnsafeMutablePointer<CVPixelBuffer?>) {

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
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height),
                                         kCVPixelFormatType_32ARGB, options, pxbuffer)
        print("status = \(status)")
        CVPixelBufferLockBaseAddress(pxbuffer.memory!, 0);
        let bufferData = CVPixelBufferGetBaseAddress(pxbuffer.memory!);
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        let context = CGBitmapContextCreate(bufferData, Int(size.width),
                                            Int(size.height), 8, 4*Int(size.width), rgbColorSpace,
                                            CGImageAlphaInfo.NoneSkipFirst.rawValue);
        CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(CGImageGetWidth(image)), CGFloat(CGImageGetHeight(image))), image);
        
        CVPixelBufferUnlockBaseAddress(pxbuffer.memory!, 0);

        //return pxbuffer
        
    }
    
    
    
    
    
    
    
}