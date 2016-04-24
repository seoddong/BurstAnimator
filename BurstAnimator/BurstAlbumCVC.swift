//
// Copyright 2014 Scott Logic
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit
import Photos

class BurstAlbumCVC: UICollectionViewCell {
    
    @IBOutlet weak var imgView: UIImageView!
    
    var imageManager: PHImageManager?
    var targetSizeX: CGFloat?
    
    var imageAsset: PHAsset? {
        didSet {
            // 여기서 CGSize를 정하는 것과 BurstAlbum의 CollectionView에서 CGSize를 정하는 것의 차이는 무엇일까?
            self.imageManager?.requestImageForAsset(imageAsset!, targetSize: CGSizeMake(targetSizeX!-5, targetSizeX!-5), contentMode: .AspectFill, options: nil) { image, info in
                self.imgView.image = image
            }
        }
    }
    
    
}
