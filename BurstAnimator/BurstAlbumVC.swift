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
        
        // scale은 레티나 여부를 판단하기 위함
        scale = UIScreen.mainScreen().scale
        // 화면의 좁은 쪽을 기준으로 3등분한다. - 세워져있을 때는 가로를 기준으로 한다.
        targetSizeX = CGRectGetWidth(UIScreen.mainScreen().bounds) * scale / 3

        // subtype이 SmartAlbumUserLibrary이면 카메라롤을 의미한다. SmartAlbumBursts이 Burst앨범을 의미한다.
        burstAlbum = PHAssetCollection.fetchAssetCollectionsWithType(.SmartAlbum, subtype: .SmartAlbumBursts, options: nil)

        // 사진을 역순으로 정렬하기 위한 fetch option 설정
        let option = PHFetchOptions()
        let sort1 = NSSortDescriptor(key: "creationDate", ascending: false)
        option.sortDescriptors = [sort1]
        
        let collection = (burstAlbum.firstObject as! PHAssetCollection)
        burstImages = PHAsset.fetchAssetsInAssetCollection(collection, options: option)
        print("burstImages.count = \(burstImages.count)")
        

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
        
        let imageAsset: PHAsset = burstImages[indexPath.item] as! PHAsset
        
        if let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as? BurstAlbumCVC {
            
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
    
    // 셀이 선택되었을 때를 설정하는 메소드
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        // 셀이 선택되었음을 보여주기 위해서 셀의 모양에 변화를 주려 했으나 실제 셀이 선택되는 순간 뷰가 변경되므로 무의미한 코드가 되어버렸다.
        if let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as? BurstAlbumCVC {
        
            cell.layer.borderColor = UIColor.yellowColor().CGColor
            cell.layer.borderWidth = 5
            
        }
        
        // 셀이 선택될 때 BurstImageVC를 호출하기 위한 코드이다. 나중에 Burst Images를 불러오기 위하여 호출할 뷰에 burstIdentifier값을 넘겨주도록 하였다.
        // BurstImageSegue는 Main.Storyboard에서 뷰와 뷰 사이의 연결고리에 설정한 identifier 값과 동일하게 설정한다.
        let burstIdentifier = burstImages[indexPath.item].burstIdentifier
        performSegueWithIdentifier("BurstImageSegue", sender: burstIdentifier)
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        // 셀을 선택했을 때 이게 호출되므로 sender는 cell이다.
        
        // 위 performSegueWithIdentifier가 호출될 때 넘긴 burstIdentifier를 다음 뷰에 넘겨준다.
        if segue.identifier == "BurstImageSegue" {
            if let burstImageVC = segue.destinationViewController as? BurstImageVC {
                if let burstIdentifier = sender as? String {
                    burstImageVC.burstIdentifier = burstIdentifier
                }
            }
        }
    }


}
