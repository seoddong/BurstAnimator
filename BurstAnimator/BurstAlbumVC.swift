//
//  BurstAlbumVC.swift
//  BurstAnimator
//
//  Created by SeoDongHee on 2016. 4. 24..
//  Copyright © 2016년 SeoDongHee. All rights reserved.
//

import UIKit
import Photos

private var reuseIdentifier = "Cell"

class BurstAlbumVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var burstAlbumCollectionView: UICollectionView!
    
    var burstImages, burstAlbum, burst: PHFetchResult!
    var options = PHFetchOptions()
    let imageManager = PHCachingImageManager()
    
    var scale: CGFloat!
    var targetSizeX: CGFloat!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // UX 설정
        // 1. Collection View
        burstAlbumCollectionView.backgroundColor = UIColor.whiteColor()
        // Collection View 설정
        burstAlbumCollectionView.delegate = self
        burstAlbumCollectionView.dataSource = self
        
        // 화면의 가로 사이즈를 구한다.
        // 화면이 landscape라면 세로 사이즈를 구한다.
        scale = UIScreen.mainScreen().scale
        // 화면의 좁은 쪽을 기준으로 3등분한다.
        targetSizeX = CGRectGetWidth(UIScreen.mainScreen().bounds) * scale / 3
        print("targetSizeX = \(targetSizeX)")
        
        options.includeAllBurstAssets = true
        
        burstAlbum = PHAssetCollection.fetchAssetCollectionsWithType(.SmartAlbum, subtype: .SmartAlbumUserLibrary, options: options)
        print("assetCollection.count = \(burstAlbum.count)")
        
        
        let collection = burstAlbum.firstObject as! PHAssetCollection //burstAlbum[0] as! PHAssetCollection
        burstImages = PHAsset.fetchKeyAssetsInAssetCollection(collection, options: options)
        print("images.count = \(burstImages.count)")
        
        
//        if ((burstImages[0].representsBurst) != nil) {
//            if let bi = burstImages[0].burstIdentifier {
//                burst = PHAsset.fetchAssetsWithBurstIdentifier(bi!, options: options)
//                print("burst = \(burst.count)")
//            }
//        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        if let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as? BurstAlbumCVC {
            
            cell.imageManager = imageManager
            print("Cell 내용 설정 - targetSizeX = \(targetSizeX)")
            cell.targetSizeX = targetSizeX
            cell.imageAsset = burstImages[indexPath.item] as? PHAsset
            
            return cell
        }
        else {
            return UICollectionViewCell()
        }
    }
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        // 나중에 정의
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        // 이 샘플에서는 images의 개수가 cell의 개수이다.
        return burstImages.count
    }
    
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        // 이 샘플에서는 Section은 1개이다.
        return 1
    }
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        // Cell spacing과 padding값에 의해서 셀 크기가 계산되어졌다 하더라도 제대로 안 들어가는 경우가 있다.
        // Cell spacing은 10정도 유지하는 것이 좋고 padding은 없는 것이 사진앱과 비슷한 UX를 제공한다.
        // 그러므로 최종 Cell의 크기는 CollectionView의 Min Spacing For Cell 값을 참조하여 빼주도록 한다.
        targetSizeX = burstAlbumCollectionView.frame.width / 3 - 1 // Min Spacing For Cell
        print("Cell 크기 설정 - targetSizeX = \(targetSizeX)")
        
        return CGSizeMake(targetSizeX, targetSizeX)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0 as CGFloat
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1 as CGFloat
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
