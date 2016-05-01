//
//  AnimateVC.swift
//  BurstAnimator
//
//  Created by SeoDongHee on 2016. 4. 30..
//  Copyright © 2016년 SeoDongHee. All rights reserved.
//

import UIKit
import Photos

class AnimateVC: UIViewController {

    @IBOutlet weak var animatedImageView: UIImageView!

    var fetchresult: PHFetchResult!
    var scale: CGFloat!
    // 아래 변수를 optional로 선언을 했더니 animatedimagesarray.append() 할 때 unexpectedly found nil while unwrapping an Optional value 메시지가 계속 나온다.
    // 아래와 같이 optional 빼고 초기값 주었더니 오류는 안 난다.
    var animatedimagesarray: [UIImage] = []
    
    let imagemanager = PHCachingImageManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("viewDidLoad")
    }
    
    override func viewWillAppear(animated: Bool) {
        print("viewWillAppear")
        self.reloadInputViews()
        // scale은 레티나 여부를 판단하기 위함
        scale = UIScreen.mainScreen().scale
        // 이미지를 가져올 때 사용할 크기
        let size: CGSize = CGSizeMake(self.animatedImageView.bounds.width * scale, self.animatedImageView.bounds.height * scale)
        print("scale = \(scale), size = \(size)")
        
        // 이미지를 가져올 때 사용할 옵션
        let option: PHImageRequestOptions = PHImageRequestOptions()
        // iCloud 이미지를 가져올 수도 있으므로 네트워크 사용을 허용한다.
        option.networkAccessAllowed = true
        option.deliveryMode = .HighQualityFormat
        // option.synchronous = false로 하게 되면 사진을 다 가져오지 못 한 상태에서 다음 루프문이 실행되기 때문에 nil이 생기고 에러가 발생한다. 이 때에는 dispatch_async를 사용해야 하는데 해 보았는데 잘 안 되더라. 에러는 안 나는데 사진이 보이지 않는 문제가 있었다.
        option.synchronous = true
        
        // progress bar를 넣을 예정 - 각각의 이미지 로딩 진척률을 조합하여 계산 필요.
        
        
        // fetchresult에는 burstImages가 들어있다.
        for ii in 0 ..< fetchresult.count {
            let imageasset = fetchresult[ii] as! PHAsset
            
            // 도대체 왜 이미지가 찌그러지는지 알 수가 없다. - 드디어 알아냈다. 너무 간단했다. Main.Storyboard의 animatedImageView 속성이 Scale to Fill로 되어 있었다. 어쩐지 이미지 뷰 크기에 딱 맞게 계속 채워지더라니..
            self.imagemanager.requestImageForAsset(imageasset, targetSize: size, contentMode: .AspectFit, options: option, resultHandler: { (result, info) -> Void in
                self.animatedimagesarray.append(result!)
            })
            
        }
        
        animatedImageView.animationImages = animatedimagesarray
        // animationDuration은 animation이 플레이될 총 시간(sec)을 의미한다. 그러므로 이미지 개수에 따라 총 시간을 다르게 설정해주어야 한다.
        animatedImageView.animationDuration = Double(fetchresult.count) * 0.1
        animatedImageView.animationRepeatCount = 0
        animatedImageView.startAnimating()
        
        // 아래 코드가 필요할까 잘 모르겠다.
        self.view.layoutIfNeeded()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        _ = UIAlertController.init(title: "MemoryWarning", message: "\(self.nibName!) get didReceiveMemoryWarning()", preferredStyle: .Alert)
    }
    
    
    @IBAction func stopBtnPressed(sender: AnyObject) {
        animatedImageView.stopAnimating()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
