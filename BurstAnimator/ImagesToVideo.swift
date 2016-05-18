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
    
    /**
     *  Convenience methods for UIImage arry to video
     *
     *  param arrayImages   UIImages to convert to video
     *  @param fps           FPS of video
     */
    func saveVideoFromUIImages(arrayImages: NSArray, fps: Int) -> String {
        
        
        var outputSize: CGSize
        
        let image = arrayImages[0] as! UIImage
        outputSize = CGSizeMake(image.size.width, image.size.height)
        
        debugPrint("arrayImages[0] = \(arrayImages[0])")
        debugPrint("outputSize = \(outputSize)")
        
        let fileManager = NSFileManager()
        let tempPath = NSTemporaryDirectory().stringByAppendingString("temp.mp4")
        if (fileManager.fileExistsAtPath(tempPath)){
            do {
                try NSFileManager.defaultManager().removeItemAtPath(tempPath)
                debugPrint("removeItemAtPath = success..")
            }
            catch {
                debugPrint("removeItemAtPath = error occured...")
            }
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
        
        let writingGroup = dispatch_group_create()
        // Handle completion.
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        dispatch_group_notify(writingGroup, queue) {

        }
        
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
                        
                        // 비디오 변환 후 마지막 이미지의 pxbuffer만 이미지뷰에 표시한다.
                        let parentVC = sender as! AnimateVC
                        let checkImage = CIImage.init(CVPixelBuffer: pixelBufferPointer.memory!)
                        parentVC.animatedImageView.image = UIImage.init(CIImage: checkImage)
                        
                        
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
                        
                        debugPrint("ii=\(ii)")

                        //pixelBufferPointer = self.pixelBufferFromCGImage(arrayImages[ii] as! CGImage, size: outputSize)
                        self.pixelBufferFromCGImage(arrayImages[ii] as! UIImage, pxbuffer: pixelBufferPointer)
                        
                        
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
    func pixelBufferFromCGImage(image: UIImage, pxbuffer: UnsafeMutablePointer<CVPixelBuffer?>) {
        
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

        let width = CGImageGetWidth(cgimage)
        let height = CGImageGetHeight(cgimage)
        
        //let pxbuffer = UnsafeMutablePointer<CVPixelBuffer?>.alloc(1)
        // pxbuffer = nil 할 경우 status = -6661 에러 발생한다.
        var status = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                         kCVPixelFormatType_32ARGB, options, pxbuffer)
        if (status != 0){
            debugPrint("CVPixelBufferCreate status = \(status)")
        }
        
        status = CVPixelBufferLockBaseAddress(pxbuffer.memory!, 0);
        if (status != 0){
            debugPrint("CVPixelBufferLockBaseAddress status = \(status)")
        }
        
        let bufferAddress = CVPixelBufferGetBaseAddress(pxbuffer.memory!);
        //debugPrint("pxbuffer.memory = \(pxbuffer.memory)")

        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        let bytesperrow = CVPixelBufferGetBytesPerRow(pxbuffer.memory!)
        let context = CGBitmapContextCreate(bufferAddress, width,
                                            height, 8, bytesperrow, rgbColorSpace,
                                            CGImageAlphaInfo.NoneSkipFirst.rawValue);
        //debugPrint("image = \(image)")
        CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), cgimage);

        status = CVPixelBufferUnlockBaseAddress(pxbuffer.memory!, 0);
        if (status != 0){
            debugPrint("CVPixelBufferUnlockBaseAddress status = \(status)")
        }
    }
    
    func convertCIImageToCGImage(inputImage: CIImage) -> CGImage! {
        let context = CIContext(options: nil)
        
        return context.createCGImage(inputImage, fromRect: inputImage.extent)

    }
    



    
    /*
    // 아래 메소드들은 디버그용이다. 출력창에 이미지를 대충 그리기 위함
    func drawOutput(pixelbuffer: UnsafeMutablePointer<CVPixelBuffer?>, width: Int, height: Int) {
        let pixels = pixelbuffer
        for var ii in 0...height {
            for var jj in 0...width {
                let color = pixels.memory! as Int
                print("\(r8(color)+g8(color)+b8(color)/3.0)")
                pixels ++
            }
            print("\n");
        }
    }
    func mask8(int: Int) -> Int {
        return int & 0xFF
    }
    func r8(int: Int) -> Int {
        return mask8(int)
    }
    func g8(int: Int) -> Int {
        return mask8(int) >> 8
    }
    func b8(int: Int) -> Int {
        return mask8(int) >> 16
    }
    */
    
    
    
}


// 나중에 쓸모가 있을 코드인 것 같다.
extension CVPixelBufferRef {
    /**
     Iterates through each pixel in the receiver (assumed to be in ARGB format)
     and overwrites the color component at the given index with a zero. This
     has the effect of "cyanifying," "rosifying," etc (depending on the chosen
     color component) the overall image represented by the pixel buffer.
     */
    func removeARGBColorComponentAtIndex(componentIndex: size_t) throws {
        let lockBaseAddressResult = CVPixelBufferLockBaseAddress(self, 0)
        
        guard lockBaseAddressResult == kCVReturnSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(lockBaseAddressResult), userInfo: nil)
        }
        
        let bufferHeight = CVPixelBufferGetHeight(self)
        
        let bufferWidth = CVPixelBufferGetWidth(self)
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(self)
        
        let bytesPerPixel = bytesPerRow / bufferWidth
        
        let base = UnsafeMutablePointer<Int8>(CVPixelBufferGetBaseAddress(self))
        
        // For each pixel, zero out selected color component.
        for row in 0..<bufferHeight {
            for column in 0..<bufferWidth {
                let pixel: UnsafeMutablePointer<Int8> = base + (row * bytesPerRow) + (column * bytesPerPixel)
                pixel[componentIndex] = 0
            }
        }
        
        let unlockBaseAddressResult = CVPixelBufferUnlockBaseAddress(self, 0)
        
        guard unlockBaseAddressResult == kCVReturnSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(unlockBaseAddressResult), userInfo: nil)
        }
    }
}
