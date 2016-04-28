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
    var options: PHFetchOptions!
    var burstIdentifier: String!
    var targetSizeX: CGFloat!
    
    let imageManager = PHCachingImageManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        burstImagesCollection.delegate = self
        burstImagesCollection.dataSource = self
        
        // BurstImages는 정렬을 하지 않으면 제멋대로 들어있다.
        options = PHFetchOptions()
        options.includeAllBurstAssets = true
        let sort1 = NSSortDescriptor(key: "creationDate", ascending: true)
        options.sortDescriptors = [sort1]
        
        // burstIdentifier에 해당하는 Burst Images를 가져온다.
        burstImages = PHAsset.fetchAssetsWithBurstIdentifier(burstIdentifier!, options: options)
        print("burstImages.count = \(burstImages.count)")
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        
        targetSizeX = burstImagesCollection.frame.width / 4 - 1 // Min Spacing For Cell
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
        
        if let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as? BurstImageCVC {
            
            cell.imageManager = imageManager
            // print("Cell 내용 설정 - targetSizeX = \(targetSizeX)")
            cell.targetSizeX = targetSizeX
            cell.imageAsset = burstImages[indexPath.item] as? PHAsset
            
            return cell
        }
        else {
            return UICollectionViewCell()
        }
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
