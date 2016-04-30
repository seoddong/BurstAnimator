//
//  BurstImageVC.swift
//  BurstAnimator
//
//  Created by SeoDongHee on 2016. 4. 26..
//  Copyright © 2016년 SeoDongHee. All rights reserved.
//

import UIKit
import Photos

private var reuseIdentifier = "Cell2"

class BurstImageVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var burstImagesCollection: UICollectionView!
    
    var burstImages: PHFetchResult!
    var option: PHFetchOptions!
    var burstIdentifier: String!
    var targetSizeX: CGFloat!
    var scale: CGFloat!
    
    let imageManager = PHCachingImageManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        burstImagesCollection.delegate = self
        burstImagesCollection.dataSource = self
        
        // scale은 레티나 여부를 판단하기 위함
        scale = UIScreen.mainScreen().scale
        // 화면의 좁은 쪽을 기준으로 3등분한다. - 세워져있을 때는 가로를 기준으로 한다.
        targetSizeX = CGRectGetWidth(UIScreen.mainScreen().bounds) * scale / 3
        
        // BurstImages는 정렬을 하지 않으면 제멋대로 들어있다.
        option = PHFetchOptions()
        option.includeAllBurstAssets = true
        let sort1 = NSSortDescriptor(key: "creationDate", ascending: true)
        option.sortDescriptors = [sort1]
        
        // burstIdentifier에 해당하는 Burst Images를 가져온다.
        burstImages = PHAsset.fetchAssetsWithBurstIdentifier(burstIdentifier!, options: option)
        print("burstImages.count = \(burstImages.count)")
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        _ = UIAlertController.init(title: "MemoryWarning", message: "\(self.nibName!) get didReceiveMemoryWarning()", preferredStyle: .Alert)
        
    }
    

    // 1. 섹션 수
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    // 2. 섹션별 아이템 수
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        
        return burstImages.count
    }
    
    // 3. 셀 크기
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        targetSizeX = burstImagesCollection.frame.width / 3 - 1 // Min Spacing For Cell
        // print("Cell 크기 설정 - targetSizeX = \(targetSizeX)")
        
        return CGSizeMake(targetSizeX, targetSizeX)
    }
    
    // 4. 미니멈 아이템 스페이싱
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        
        return 1 as CGFloat
    }
    
    // 5. 미니멈 라인 스페이싱
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        
        return 1 as CGFloat
    }
    
    // 셀 내용
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let imageAsset: PHAsset = burstImages[indexPath.item] as! PHAsset
        
        if let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as? BurstImageCVC {
            
            cell.representedAssetIdentifier = imageAsset.localIdentifier;
            
            // 이미지를 가져올 때 사용할 크기
            let size: CGSize = CGSizeMake(cell.imgView.bounds.width * scale, cell.imgView.bounds.height * scale)
            
            // 이미지를 가져올 때 사용할 옵션
            let option: PHImageRequestOptions = PHImageRequestOptions()
            
            // iCloud 이미지를 가져올 수도 있으므로 네트워크 사용을 허용한다.
            option.networkAccessAllowed = true
            
            // 아래 메소드의 targetSize를 Cell의 크기나 imgView의 크기보다 더 크게 설정할 수 있다.
            // 그렇게 해도 contentMode에 의해서 자동으로 imgView 크기에 맞추게 된다.
            // AspectFill: 이미지 원본의 비율을 무시하고 무조건 imgView에 딱 맞춘다. 즉 이미지가 찌그러질 수 있다는 것.
            // AspectFit: default 설정이다. 이미지 원본의 비율을 유지한채 imgView에 맞춘다고 하니 사실상 여백이 발생할 수 있다는 것.
            self.imageManager.requestImageForAsset(imageAsset, targetSize: size, contentMode: .AspectFill, options: option, resultHandler: { (result, info) -> Void in
                
                // Set the cell's thumbnail image if it's still showing the same asset.
                if (cell.representedAssetIdentifier == imageAsset.localIdentifier) {
                    cell.imgView.image = result
                }
            })
            
            return cell
        }
        else {
            return UICollectionViewCell()
        }
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        
        if segue.identifier == "animateSegue" {
            if let animateVC = segue.destinationViewController as? AnimateVC {
                // AnimateVC로 BurstImages를 넘긴다.
                animateVC.fetchresult = burstImages
            }
        }
    }

}
