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
        //print("targetSizeX = \(targetSizeX)")
        
        options.includeAllBurstAssets = true
        
        // subtype이 SmartAlbumUserLibrary이면 카메라롤을 의미한다. SmartAlbumBursts이 Burst앨범을 의미한다.
        burstAlbum = PHAssetCollection.fetchAssetCollectionsWithType(.SmartAlbum, subtype: .SmartAlbumUserLibrary, options: options)
        //print("assetCollection.count = \(burstAlbum.count)")
        
        
        let collection = burstAlbum.firstObject as! PHAssetCollection //burstAlbum[0] as! PHAssetCollection
        burstImages = PHAsset.fetchKeyAssetsInAssetCollection(collection, options: options)
        //print("images.count = \(burstImages.count)")
        
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    // Collection View가 처리되는 과정은 아래 메소드의 순서대로이다.
    // 1. numberOfSectionsInCollectionView가 가정 먼저 실행되어 Section의 개수를 파악한다.
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        // 이 샘플에서는 Section은 1개이다.
        //print("numberOfSectionsInCollectionView = 1")
        return 1
    }
    
    // 2. numberOfItemsInSection가 실행되어 Section당 Item의 개수를 파악한다.
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        //print("numberOfItemsInSection = \(burstImages.count)")
        // 이 샘플에서는 images의 개수가 cell의 개수이다.
        return burstImages.count
    }
    
    // 3. 셀의 크기 설정이 이루어진다.
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        // 사진앱과 가장 비슷한 UX를 제공하려면 minimumInteritemSpacingForSectionAtIndex, minimumLineSpacingForSectionAtIndex 둘 다 1로 설정하는 것이다.
        // 이 크기를 감안해서 Cell의 크기를 설정해 주어야 한다.
        // 만약 Spacing을 고려하지 않고 Cell 크기를 설정하게 되어 미묘하게 Cell 크기가 가로 크기를 넘길 경우 이쁘지 않은 레이아웃을 보게 될 것이다.
        // 그러므로 최종 Cell의 크기는 Spacing 값을 참조하여 빼주도록 한다.
        targetSizeX = burstAlbumCollectionView.frame.width / 3 - 1 // Min Spacing For Cell
        // print("Cell 크기 설정 - targetSizeX = \(targetSizeX)")
        
        return CGSizeMake(targetSizeX, targetSizeX)
    }
    
    
    // 4. Cell 내부 아이템의 최소 스페이싱을 설정한다. 셀간의 가로 간격이라고 생각하면 된다.
    // 상세한 내역은 여기 참조 : https://developer.apple.com/library/ios/documentation/WindowsViews/Conceptual/CollectionViewPGforIOS/UsingtheFlowLayout/UsingtheFlowLayout.html
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        
        // print("minimumInteritemSpacingForSectionAtIndex 설정")
        return 1 as CGFloat
    }
    
    // 5. Cell 간 라인 스페이싱을 설정한다. 셀간의 세로 간격이라고 생각하면 된다.
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        
        // print("minimumLineSpacingForSectionAtIndex 설정")
        return 1 as CGFloat
    }
    
    // 셀의 내용을 설정하는 메소드
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        if let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as? BurstAlbumCVC {
            
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
    
    // 셀이 선택되었을 때를 설정하는 메소드
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as? BurstAlbumCVC {
        
            cell.layer.borderColor = UIColor.yellowColor().CGColor
            cell.layer.borderWidth = 5
            
        }
        let burstIdentifier = burstImages[indexPath.item].burstIdentifier
        performSegueWithIdentifier("BurstImageSegue", sender: burstIdentifier)
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        if segue.identifier == "BurstImageSegue" {
            if let burstImageVC = segue.destinationViewController as? BurstImageVC {
                if let burstIdentifier = sender as? String {
                    burstImageVC.burstIdentifier = burstIdentifier
                }
            }
        }
        // Pass the selected object to the new view controller.
    }


}
