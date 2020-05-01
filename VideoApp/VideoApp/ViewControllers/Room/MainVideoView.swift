//
//  Copyright (C) 2020 Twilio, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit

@IBDesignable
class MainVideoView: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var identityLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        identityLabel.text = "Tim"
    }
    
    func configure(identity: String) {
        identityLabel.text = identity
    }
    
    
//    let nibName = "MainVideoView"
//    var contentView:UIView?
//
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        commonInit()
//    }
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        commonInit()
//    }
//    func commonInit() {
//        guard let view = loadViewFromNib() else { return }
//        view.frame = self.bounds
//        self.addSubview(view)
//        contentView = view
//    }
//    func loadViewFromNib() -> UIView? {
//        let bundle = Bundle(for: type(of: self))
//        let nib = UINib(nibName: nibName, bundle: bundle)
//        return nib.instantiate(withOwner: self, options: nil).first as? UIView
//    }


    override init(frame: CGRect) {
     super.init(frame: frame)
     setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
      setup()
    }
    
    func setup() {
      contentView = loadViewFromNib()
      contentView.frame = bounds
      
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      
      addSubview(contentView)
    }
    
    func loadViewFromNib() -> UIView! {
      let bundle = Bundle(for: type(of: self))
      let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
      let view = nib.instantiate(withOwner: self, options: nil).first as? UIView
      
      return view
    }
}
