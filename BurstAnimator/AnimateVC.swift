//
//  AnimateVC.swift
//  BurstAnimator
//
//  Created by SeoDongHee on 2016. 4. 30..
//  Copyright © 2016년 SeoDongHee. All rights reserved.
//

import UIKit
import Photos
import AVKit

class AnimateVC: UIViewController {

    @IBOutlet weak var animatedImageView: UIImageView!
    @IBOutlet weak var labelCount: UILabel!

    var fetchresult: PHFetchResult!
    var scale: CGFloat!
    var outputSize: CGSize!
    // 아래 변수를 optional로 선언을 했더니 animatedimagesarray.append() 할 때 unexpectedly found nil while unwrapping an Optional value 메시지가 계속 나온다.
    // 아래와 같이 optional 빼고 초기값 주었더니 오류는 안 난다.
    var animatedimagesarray: [UIImage] = []
    var path: String!
    
    let imagemanager = PHCachingImageManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // scale은 레티나 여부를 판단하기 위함
        scale = UIScreen.mainScreen().scale / 2 // 사진 크기를 작게 하려고 2로 나눔
        // 이미지를 가져올 때 사용할 크기
        outputSize = CGSizeMake(self.animatedImageView.bounds.width * scale, self.animatedImageView.bounds.height * scale)
        print("scale = \(scale), size = \(outputSize)")
        
        // 이미지를 가져올 때 사용할 옵션
        let option: PHImageRequestOptions = PHImageRequestOptions()
        // iCloud 이미지를 가져올 수도 있으므로 네트워크 사용을 허용한다.
        // 만약 이게 false이고 사진이 iCloud에 저장된 경우라면 HighQualityFormat으로 가져올 수 없는 상황이므로 오류가 발생하게 된다.
        option.networkAccessAllowed = true
        option.deliveryMode = .HighQualityFormat
        // option.synchronous = false로 하게 되면 사진을 다 가져오지 못 한 상태에서 다음 루프문이 실행되기 때문에 nil이 생기고 에러가 발생한다. 이 때에는 dispatch_async를 사용해야 하는데 해 보았는데 잘 안 되더라. 에러는 안 나는데 사진이 보이지 않는 문제가 있었다.
        option.synchronous = true
        
        // targetSize에 정확하게 맞추기 위함
        option.resizeMode = .Exact
        
        // progress bar를 넣을 예정 - 각각의 이미지 로딩 진척률을 조합하여 계산 필요.
        // 버튼의 숫자가 안 바뀐다.
        labelCount.text = String(fetchresult.count)
        //self.view.setNeedsDisplay()
        
        
        // fetchresult에는 burstImages가 들어있다.
        for ii in 0 ..< fetchresult.count {
            let imageasset = fetchresult[ii] as! PHAsset
            
            // 도대체 왜 이미지가 찌그러지는지 알 수가 없다. - 드디어 알아냈다. 너무 간단했다. Main.Storyboard의 animatedImageView 속성이 Scale to Fill로 되어 있었다. 어쩐지 이미지 뷰 크기에 딱 맞게 계속 채워지더라니..
            self.imagemanager.requestImageForAsset(imageasset, targetSize: outputSize, contentMode: .AspectFit, options: option, resultHandler: { (result, info) -> Void in
                print("result = \(result)")
                self.animatedimagesarray.append(result!)
            })
            labelCount.text = String(fetchresult.count - ii - 1)
            //self.view.setNeedsDisplay()
            
        }
        
        animatedImageView.animationImages = animatedimagesarray
        // animationDuration은 animation이 플레이될 총 시간(sec)을 의미한다. 그러므로 이미지 개수에 따라 총 시간을 다르게 설정해주어야 한다.
        animatedImageView.animationDuration = Double(fetchresult.count) * 0.1
        animatedImageView.animationRepeatCount = 0
        animatedImageView.startAnimating()
        
        //self.view.setNeedsDisplay()
        
    }
    
    override func viewWillAppear(animated: Bool) {

        // viewDidLoad에 들어갈 코드를 여기다가 넣었더니, 다음 view로 넘어갔다가 되돌아오면 코드가 다시 실행되어 보기 좋지 않았다.

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        _ = UIAlertController.init(title: "MemoryWarning", message: "get didReceiveMemoryWarning()", preferredStyle: .Alert)
        
    }
    
    @IBAction func btnSavePressed(sender: AnyObject) {
        self.animatedImageView.stopAnimating()
        self.view.setNeedsDisplay()
        
        let imagestovideo = ImagesToVideo(sender: self)
        path = imagestovideo.saveVideoFromImages(self.animatedimagesarray, outputSize: self.outputSize)
    }
    

    @IBAction func btnPlayPressed(sender: AnyObject) {
        print("btnPlayPressed")
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        print("segue..")
        
        if segue.identifier == "avplayer" {
            print("path = \(path)")
            let player = AVPlayer()
            let playeritem = AVPlayerItem(URL: NSURL(fileURLWithPath: path))
            player.replaceCurrentItemWithPlayerItem(playeritem)
            
            let playerController = segue.destinationViewController as! AVPlayerViewController
            playerController.player = player
            
            
//            dispatch_async(dispatch_get_main_queue()) {
//                playerController.player = player
//                self.presentViewController(playerController, animated: true) {
//                    let delay = 2 * Double(NSEC_PER_SEC)
//                    let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
//                    dispatch_after(time, dispatch_get_main_queue()){
//                        player.play()
//                    }
//                }
//            }
        }
    }


}
