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

import TwilioVideo // TODO: Don't import
import UIKit

class ParticipantCell: UICollectionViewCell {
    struct Status {
        let identity: String
        let isMicMuted: Bool
        let networkQualityLevel: NetworkQualityLevel
        let isPinned: Bool
    }
    
    @IBOutlet weak var videoView: TwilioVideo.VideoView!
    @IBOutlet weak var identityLabel: UILabel!
    @IBOutlet weak var networkQualityImage: UIImageView!
    @IBOutlet weak var pinView: UIView!
    @IBOutlet weak var muteView: UIView!
    private var videoTrack: VideoTrack?
    
    deinit {
        videoTrack?.removeRenderer(videoView) // TODO: Really needed?
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        videoView.delegate = self
        videoView.contentMode = .scaleAspectFill // TODO: Why doesn't this work from storyboard?
    }
    
    func configure(status: Status) {
        identityLabel.text = status.identity
        muteView.isHidden = !status.isMicMuted
        pinView.isHidden = !status.isPinned
        
        // This can be cleaner
        if let imageName = status.networkQualityLevel.imageName {
            networkQualityImage.image = UIImage(named: imageName)
        } else {
            networkQualityImage.image = nil
        }
    }
    
    func configure(videoTrack: VideoTrack?, shouldMirror: Bool) {
        guard let videoTrack = videoTrack, videoTrack.isEnabled else {
            self.videoTrack?.removeRenderer(videoView)
            videoView.isHidden = true
            return
        }

        videoTrack.addRenderer(videoView)
        videoView.shouldMirror = shouldMirror
        videoView.isHidden = !videoView.hasVideoData
    }
}

extension ParticipantCell: VideoViewDelegate { // TODO: Make private?
    func videoViewDidReceiveData(view: TwilioVideo.VideoView) {
        videoView.isHidden = false
    }
}

private extension NetworkQualityLevel {
    var imageName: String? {
        switch self {
        case .unknown: return nil
        case .zero: return "network-quality-level-0"
        case .one: return "network-quality-level-1"
        case .two: return "network-quality-level-2"
        case .three: return "network-quality-level-3"
        case .four: return "network-quality-level-4"
        case .five: return "network-quality-level-5"
        @unknown default:
            return nil
        }
    }
}
