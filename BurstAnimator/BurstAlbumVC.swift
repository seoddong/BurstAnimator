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
        burstAlbumCollectionView.delegate = self
        burstAlbumCollectionView.dataSource = self
        
        // 화면의 가로 사이즈를 구한다.
        // 화면이 landscape라면 세로 사이즈를 구한다.
        scale = UIScreen.mainScreen().scale
        // 화면의 좁은 쪽을 기준으로 3등분한다.
        targetSizeX = CGRectGetWidth(UIScreen.mainScreen().bounds) * scale / 3
        
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
        

        print("targetSizeX = \(targetSizeX)")
        // 이 샘플에서는 Cell의 크기를 105x105로 지정한다.
        return CGSizeMake(targetSizeX, targetSizeX)
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
