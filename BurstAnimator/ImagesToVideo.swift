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
    
    let sender: AnyObject
    let serialQueue: dispatch_queue_t
    
    init(sender: AnyObject) {
        self.sender = sender
        serialQueue = dispatch_queue_create("com.songahbie.BurstAnimator.serial", DISPATCH_QUEUE_SERIAL)
    }
    
    /**
     *  Convenience methods for UIImage arry to video
     *
     *  param arrayImages   UIImages to convert to video
     *  @param fps           FPS of video
     */
    func saveVideoFromUIImages(arrayImages: NSArray, fps: Int) -> String {
        
        let framePerFile = 3 //arrayImages.count
        let processCount = Int(ceil(Double(arrayImages.count) / Double(framePerFile)))
        debugPrint("processCount=\(processCount)")
        var arrayTempPath: [String] = []
        for kk in 0..<processCount {
            arrayTempPath.append("temp_\(kk).mp4")
            var tempArrayImages: [UIImage] = []
            for ll in 0..<framePerFile {
                let current = kk * framePerFile + ll
                if (current >= arrayImages.count) {
                    debugPrint("current = \(current)")
                    break
                }
                else {
                    
                    tempArrayImages.append(arrayImages[kk*framePerFile + ll] as! UIImage)
                }
                
            }
            
            dispatch_async(serialQueue) {
                
                let returnPath = self.iterateSaveVideoFromUIImages(
                    { (progress: NSProgress) in
                    NSLog("Progress: \(progress.completedUnitCount) / \(progress.totalUnitCount)")
                    dispatch_async(dispatch_get_main_queue(), {
                        let progressPercentage = Float(progress.completedUnitCount) / Float(progress.totalUnitCount)
                        //progressHUD.setProgress(progressPercentage, animated: true)
                        debugPrint("progressPercentage = \(progressPercentage)")
                    })
                    }, arrayImages: tempArrayImages, fps: fps, tempPath: arrayTempPath[kk])
                debugPrint("saveVideoFromUIImages[\(kk)]:returnPath = \(returnPath)")
            }
        }
        return "succeed"
    }
    
    func iterateSaveVideoFromUIImages(progress: (NSProgress -> Void), arrayImages: NSArray, fps: Int, tempPath: String) -> String {

        //debugPrint("iterateSaveVideoFromUIImages:arrayImages.count=\(arrayImages.count)")
        //var outputSize: CGSize
        
        let image = arrayImages[0] as! UIImage
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        //outputSize = CGSizeMake(image.size.width, image.size.height)
        
        debugPrint("arrayImages[0] = \(arrayImages[0])")
        debugPrint("iterateSaveVideoFromUIImages:width = \(width), height = \(height)")
        
        let fileManager = NSFileManager()
        let tempPath = NSTemporaryDirectory().stringByAppendingString(tempPath)
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
            AVVideoWidthKey : width,
            AVVideoHeightKey : height
        ]
        
        let input = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
        
        // pixelBufferPool을 사용하기 위해서는 sourcePixelBufferAttributes가 nil이면 안된다고 함. (Pass nil if you do not need a pixel buffer pool for allocating buffers.)
        let bytesPerRow = self.getBytesPerRowFromUIImage(image)
        let sourceBufferAttributes = [String : AnyObject](dictionaryLiteral:
            (kCVPixelBufferPixelFormatTypeKey as String, Int(kCVPixelFormatType_32ARGB)),
            (kCVPixelBufferBytesPerRowAlignmentKey as String, Float(bytesPerRow)),
            (kCVPixelBufferWidthKey as String, Float(width)),
            (kCVPixelBufferHeightKey as String, Float(height))
        )
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: sourceBufferAttributes)
        debugPrint("adaptor = \(adaptor)")
        
        assert(videoWriter.canAddInput(input))
        videoWriter.addInput(input)
        
        if videoWriter.startWriting() {
            
            videoWriter.startSessionAtSourceTime(kCMTimeZero)
            assert(adaptor.pixelBufferPool != nil)
            
            
            input.requestMediaDataWhenReadyOnQueue(serialQueue) {() -> Void in
                
                // 아래 10은 10fps를 의미한다.
                let fps: Int32 = 10
                let frameDuration = CMTimeMake(1, fps)
                
                let currentProgress = NSProgress(totalUnitCount: Int64(arrayImages.count))
                
                var frameCount: Int64 = 0
                var readyMediaCount = 0
                while (Int(frameCount) < arrayImages.count) {
                    
                    if input.readyForMoreMediaData {
                        
                        let lastFrameTime = CMTimeMake(frameCount, fps)
                        let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
                        
                        if !self.appendPixelBufferForUIImage(arrayImages[Int(frameCount)] as! UIImage, pixelBufferAdaptor: adaptor, presentationTime: presentationTime) {
                            
                            debugPrint("appendPixelBufferForUIImage() is failed")
                            break
                        }
                        
                        frameCount += 1
                        debugPrint("frameCount = \(frameCount)")
                        
                        currentProgress.completedUnitCount = frameCount
                        progress(currentProgress)
                    }
                    else {
                        readyMediaCount += 1
                    }
                } //while
                debugPrint("readyMediaCount = \(readyMediaCount)")
                
                input.markAsFinished()
                //videoWriter.endSessionAtSourceTime(presentTime)
                videoWriter.finishWritingWithCompletionHandler({ () -> Void in
                    if videoWriter.status == AVAssetWriterStatus.Failed {
                        debugPrint("oh noes, an error: \(videoWriter.error!.description)")
                    } else {
                        debugPrint("hrmmm, there should be a movie?")
                        UISaveVideoAtPathToSavedPhotosAlbum(tempPath, self, nil, nil);
                        debugPrint("saved..")
                    }
                    
                })
                
            } //input.requestMediaDataWhenReadyOnQueue
        } //if videoWriter.startWriting()
        else {
            debugPrint("AVAssetWriter failed to start writing")
        }
        
        
        return tempPath
        
    }
    
    func appendPixelBufferForUIImage(image: UIImage, pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor, presentationTime: CMTime) -> Bool {
        var appendSucceeded = false
        
        autoreleasepool {
            if let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool {
                
                let pixelBufferPointer = UnsafeMutablePointer<CVPixelBuffer?>.alloc(1)
                let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, pixelBufferPointer)
                debugPrint("status = \(status)")
                if let pixelBuffer = pixelBufferPointer.memory where status == 0 {
                    fillPixelBufferFromImage(image, pixelBuffer: pixelBuffer)
                    debugPrint("presentationTime = \(presentationTime)")
                    appendSucceeded = pixelBufferAdaptor.appendPixelBuffer(pixelBuffer, withPresentationTime: presentationTime)
                    //debugPrint("appendSucceeded1 = \(appendSucceeded)")
                    pixelBufferPointer.destroy()
                } else {
                    NSLog("NSLog:error: Failed to allocate pixel buffer from pool")
                    debugPrint("debugPrint: Failed to allocate pixel buffer from pool")
                }
                
                pixelBufferPointer.dealloc(1)
            }
            else {
                debugPrint("pixelBufferPool = false")
            }
        }
        return appendSucceeded
    }
    
    func fillPixelBufferFromImage(image: UIImage, pixelBuffer: CVPixelBufferRef) {
        CVPixelBufferLockBaseAddress(pixelBuffer, 0)
        
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGBitmapContextCreate(pixelData, Int(image.size.width), Int(image.size.height), 8, CVPixelBufferGetBytesPerRow(pixelBuffer), rgbColorSpace, CGImageAlphaInfo.PremultipliedFirst.rawValue)
        
        let ciimage = CIImage(image: image)
        let cgimage = convertCIImageToCGImage(ciimage!)
        CGContextDrawImage(context, CGRectMake(0, 0, image.size.width, image.size.height), cgimage)
        debugPrint("context = \(context)")
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0)
    }
    
    func getCFDictionary(imageWidth: Int?, imageHight: Int?, bytesPerRow: Int?) -> CFDictionary {
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
        

        
        /*
        //var inputSettingsDict: [NSObject : AnyObject] = NSMutableDictionary() as [NSObject : AnyObject]
        var inputSettingsDict: [String : AnyObject] = [:]
        inputSettingsDict[String(kCVPixelBufferPixelFormatTypeKey)] = Int(kCVPixelFormatType_32ARGB)
        if bytesPerRow != nil {
            inputSettingsDict[String(kCVPixelBufferBytesPerRowAlignmentKey)] = bytesPerRow
        }
        if imageWidth != nil {
            inputSettingsDict[String(kCVPixelBufferWidthKey)] = imageWidth
        }
        if imageHight != nil {
            inputSettingsDict[String(kCVPixelBufferHeightKey)] = imageHight
        }
        inputSettingsDict[String(kCVPixelBufferCGImageCompatibilityKey)] = Int(true)
        inputSettingsDict[String(kCVPixelBufferCGBitmapContextCompatibilityKey)] = Int(true)

        
         NSMutableDictionary* inputSettingsDict = [NSMutableDictionary dictionary];
         [inputSettingsDict setObject:[NSNumber numberWithInt:pixelFormat] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
         [inputSettingsDict setObject:[NSNumber numberWithUnsignedInteger:(NSUInteger)(image.uncompressedSize/image.rect.size.height)] forKey:(NSString*)kCVPixelBufferBytesPerRowAlignmentKey];
         [inputSettingsDict setObject:[NSNumber numberWithDouble:image.rect.size.width] forKey:(NSString*)kCVPixelBufferWidthKey];
         [inputSettingsDict setObject:[NSNumber numberWithDouble:image.rect.size.height] forKey:(NSString*)kCVPixelBufferHeightKey];
         [inputSettingsDict setObject:[NSNumber numberWithBool:YES] forKey:(NSString*)kCVPixelBufferCGImageCompatibilityKey];
         [inputSettingsDict setObject:[NSNumber numberWithBool:YES] forKey:(NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey];

         */
        return options
    }

    func getBytesPerRowFromUIImage(image: UIImage) -> Int {
        var bytesPerRow = 0
        autoreleasepool({() -> () in
            let pxbuffer = UnsafeMutablePointer<CVPixelBuffer?>.alloc(1)
            
            // UIImage를 쉽게 CGImage로 바꿀 수 없다는 것을 알았다. 아래의 과정을 거쳐야만 한다. 검은 화면이 나오는 것도 다 이런 이유였다.
            let ciimage = CIImage(image: image)
            let cgimage = convertCIImageToCGImage(ciimage!)
            let options = getCFDictionary(nil, imageHight: nil, bytesPerRow: nil)
            
            let width = CGImageGetWidth(cgimage)
            let height = CGImageGetHeight(cgimage)
            
            let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                kCVPixelFormatType_32ARGB, options, pxbuffer)
            if (status != 0){
                debugPrint("CVPixelBufferCreate status = \(status)")
            }
            bytesPerRow = CVPixelBufferGetBytesPerRow(pxbuffer.memory!)
            pxbuffer.dealloc(1)
            
        })
        return bytesPerRow
    }
    
    func pixelBufferFromCGImage(image: UIImage) -> UnsafeMutablePointer<CVPixelBuffer?> {
    //func pixelBufferFromCGImage(image: UIImage, pxbuffer: UnsafeMutablePointer<CVPixelBuffer?>) {
        
        let pxbuffer = UnsafeMutablePointer<CVPixelBuffer?>.alloc(1)
        // pxbuffer = nil 할 경우 status = -6661 에러 발생한다.
        
        autoreleasepool({() -> () in
            
            // UIImage를 쉽게 CGImage로 바꿀 수 없다는 것을 알았다. 아래의 과정을 거쳐야만 한다. 검은 화면이 나오는 것도 다 이런 이유였다.
            let ciimage = CIImage(image: image)
            let cgimage = convertCIImageToCGImage(ciimage!)
            let options = getCFDictionary(nil, imageHight: nil, bytesPerRow: nil)
            
            let width = CGImageGetWidth(cgimage)
            let height = CGImageGetHeight(cgimage)
            
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
            
            })
        

        return pxbuffer
    }
    
    func convertCIImageToCGImage(inputImage: CIImage) -> CGImage! {
        let context = CIContext(options: nil)
        
        return context.createCGImage(inputImage, fromRect: inputImage.extent)

    }
    
    // Swifth doesn't have an equivalent to Objective C's @synchronized. This is a simple implementation from
    // http://stackoverflow.com/questions/24045895/what-is-the-swift-equivalent-to-objective-cs-synchronized
    // Not identical to the Objective-C implementation, but close enough.
    func synchronized(lock: AnyObject, closure: () -> ()) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }


    
    /*
    // 아래 메소드들은 디버그용이다. 출력창에 이미지를 대충 그리기 위함
    func drawOutput(pixelbuffer: UnsafeMutablePointer<CVPixelBuffer?>, width: Int, height: Int) {
        let pixels = pixelbuffer
        for var ii in 0..<height {
            for var jj in 0..<width {
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
