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

class BurstImageCVC: UICollectionViewCell {
    
    @IBOutlet weak var imgView: UIImageView!
    
    var imageManager: PHImageManager?
    var targetSizeX: CGFloat?
    
    var imageAsset: PHAsset? {
        didSet {
            
            // imgView의 크기가 유동적으로 변할텐데 이상하게 여기서는 최초의 값만 가지고 있어서 써먹을 수가 없다.
            //print("imgView.frame.width = \(imgView.frame.width)")
            
            // 아래 메소드의 targetSize를 Cell의 크기나 imgView의 크기보다 더 크게 설정할 수 있다.
            // 그렇게 해도 contentMode에 의해서 자동으로 imgView 크기에 맞추게 된다.
            // AspectFill: 이미지 원본의 비율을 무시하고 무조건 imgView에 딱 맞춘다. 즉 이미지가 찌그러질 수 있다는 것.
            // AspectFit: default 설정이다. 이미지 원본의 비율을 유지한채 imgView에 맞춘다고 하니 사실상 여백이 발생할 수 있다는 것.
            self.imageManager?.requestImageForAsset(imageAsset!, targetSize: CGSizeMake(targetSizeX!, targetSizeX!), contentMode: .AspectFit, options: nil) { image, info in
                self.imgView.image = image
                
                // 허나 여기서 다시 imgView의 크기를 재어 보면 딱 맞는 크기로 바뀌어있음을 알 수 있다.
                //print("self.imgView.frame.width2 = \(self.imgView.frame.width)")
                
            }
        }
    }
    
    
}
