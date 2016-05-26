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
    var serialQueue: dispatch_queue_t
    
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
                
                let returnPath = self.iterateSaveVideoFromUIImages(tempArrayImages, fps: fps, tempPath: arrayTempPath[kk])
                debugPrint("saveVideoFromUIImages[\(kk)]:returnPath = \(returnPath)")
            }
        }
        return "succeed"
    }
    
    func iterateSaveVideoFromUIImages(arrayImages: NSArray, fps: Int, tempPath: String) -> String {

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
            AVVideoWidthKey : NSNumber(integer: width),
            AVVideoHeightKey : NSNumber(integer: height)
        ]
        
        let input = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
        
        // pixelBufferPool을 사용하기 위해서는 sourcePixelBufferAttributes가 nil이면 안된다고 함. (Pass nil if you do not need a pixel buffer pool for allocating buffers.)
        let sourceBufferAttributes = [String : AnyObject](dictionaryLiteral:
            (kCVPixelBufferPixelFormatTypeKey as String, Int(kCVPixelFormatType_32ARGB)),
            (kCVPixelBufferWidthKey as String, Float(width)),
            (kCVPixelBufferHeightKey as String, Float(height))
        )
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: sourceBufferAttributes)
        debugPrint("adaptor = \(adaptor)")
        videoWriter.addInput(input)
        
        videoWriter.startWriting()
        videoWriter.startSessionAtSourceTime(kCMTimeZero)
        
//        let writingGroup = dispatch_group_create()
//        // Handle completion.
//        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
//        
//        dispatch_group_notify(writingGroup, queue) {
//
//        }
        
        var pixelBufferPointer = UnsafeMutablePointer<CVPixelBuffer?>.alloc(1)
        let options = getCFDictionary(nil, imageHight: nil, bytesPerRow: nil)
        CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                         kCVPixelFormatType_32ARGB, options, pixelBufferPointer)
        //CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, pixelBufferPointer)
        
        //let assetWriterQueue = dispatch_queue_create("AssetWriterQueue", DISPATCH_QUEUE_SERIAL);
        
        //input.requestMediaDataWhenReadyOnQueue(assetWriterQueue) {() -> Void in
            // 아래 10은 10fps를 의미한다.
            let fps: Int32 = 10
            
            var ii = 0
            
            // 초당 10프레임짜리 중 0번째 프레임을 의미함
            var presentTime = CMTimeMake(Int64(ii), fps)
            
            debugPrint("presentTime = \(presentTime)")
            var boolWhile = true
            var readyForMoreMediaDataFalseCount = 0
            while (boolWhile) {
                
                var uiimage: UIImage?
                
                // dispatch_async를 추가하였더니 앱이 이유없이 죽는 문제는 사라졌다. 그러나 이제는 메모리 경고를 내뱉으며 메모리가 마구 올라가다가 죽고 만다.
                //dispatch_async(serialQueue) {
                    // 아래 autoreleasepool 찾는데 한 4일 걸렸다. 이 코드를 사용하지 않으면 memory usage가 계속 올라가서 500메가도 넘다가 결국 앱이 죽고 만다.
                    autoreleasepool({() -> () in
                        var boolReady = false
                        boolReady = input.readyForMoreMediaData
                        
                        if(boolReady) {
                            presentTime = CMTimeMake(Int64(ii), fps)
                            
                            if(ii >= arrayImages.count){
                                
                                // 비디오 변환 후 마지막 이미지의 pxbuffer만 이미지뷰에 표시한다.
//                                let parentVC = self.sender as! AnimateVC
//                                let checkImage = CIImage.init(CVPixelBuffer: pixelBufferPointer.memory!)
//                                parentVC.animatedImageView.image = UIImage.init(CIImage: checkImage)
                                
                                dispatch_async(self.serialQueue) {
                                    
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
                                
                            }
                            else {
                                
                                uiimage = arrayImages[ii] as? UIImage
                                
                                // dispatch_async를 한 번 더 써주니 한 번 더 메모리 경고를 받게 되며 최종적으로 앱이 죽기 전에 "Message from debugger: Terminated due to memory issue"라는 메시지를 받을 수 있었다.
                                dispatch_async(self.serialQueue) {
                                    debugPrint("before ii=\(ii)")
                                    
                                    // The current solution i am using is to separate the writing task to different segments, each segment writes a single file. At the end of the loop, i use AVMutableComposition to combine all small files. By this method, peak memory appears in each segment. Because each segment there are not many imgs to write, the memory will not be consumed too much. I appreciate other ideas
                                    // 아직까지 방법은 이와 같이 파일을 잘게 쪼개서 저장했다가 합치는 것 밖에 없는 것 같다.
                                    let pixelBuffer = self.pixelBufferFromCGImage(uiimage!)
                                    
                                    // appendPixelBuffer에서 미친듯이 죽고 있다. 그 어떤 에러메시지 없이 죽어나자빠지는 것을 보니 스레드 실행에서 문제가 있는 것 같다. 다른 소스들은 @syncronized 같은 것을 사용하는데 어떤 것이 맞는 것인지 모르겠다.
                                    let status = adaptor.appendPixelBuffer(pixelBuffer.memory!, withPresentationTime: presentTime)
                                    if !status {
                                        debugPrint("appendPixelBuffer is failed..")
                                    }
                                    pixelBuffer.destroy()
                                    
                                }
                                
                                ii += 1
                                debugPrint("after ii=\(ii)")
                                
//                                while (!boolReady) {
//                                    // 초당 10프레임짜리 3초 짜리 동영상 만드는데 여기 5000번 가량 들어온다. 10ms씩 재워주면 1000번 가량으로 줄어든다.
//                                    usleep(10);
//                                }
                            }
                            
                        }
                        else {
                            readyForMoreMediaDataFalseCount += 1
                            //debugPrint("\(readyForMoreMediaDataFalseCount): readyForMoreMediaData is false at ii = \(ii)")
                        }
                    }) //autoreleasepool
                //} //dispatch_async(serialQueue)
            }
        //}
        

        return tempPath
        
    }
    
    func getCFDictionary(imageWidth: Int?, imageHight: Int?, bytesPerRow: Int?) -> [String : AnyObject] {
        // 아래 주석문의 Objective-C 구문을 swift로 변경하기 위해 이렇게 기나긴 코드를 작성해야 하다니!!
        // 오죽하면 아래 코드의 원작자도 stupid라는 주석을 달아놓았다!! ㅋㅋ
        /*
         NSDictionary *options = @{(id)kCVPixelBufferCGImageCompatibilityKey: @YES,
         (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES};
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
        

         */
        
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

        return inputSettingsDict //options
        
        /*
         NSMutableDictionary* inputSettingsDict = [NSMutableDictionary dictionary];
         [inputSettingsDict setObject:[NSNumber numberWithInt:pixelFormat] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
         [inputSettingsDict setObject:[NSNumber numberWithUnsignedInteger:(NSUInteger)(image.uncompressedSize/image.rect.size.height)] forKey:(NSString*)kCVPixelBufferBytesPerRowAlignmentKey];
         [inputSettingsDict setObject:[NSNumber numberWithDouble:image.rect.size.width] forKey:(NSString*)kCVPixelBufferWidthKey];
         [inputSettingsDict setObject:[NSNumber numberWithDouble:image.rect.size.height] forKey:(NSString*)kCVPixelBufferHeightKey];
         [inputSettingsDict setObject:[NSNumber numberWithBool:YES] forKey:(NSString*)kCVPixelBufferCGImageCompatibilityKey];
         [inputSettingsDict setObject:[NSNumber numberWithBool:YES] forKey:(NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey];

         */
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
