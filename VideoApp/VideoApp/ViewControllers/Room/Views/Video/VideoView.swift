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

import TwilioVideo
import UIKit

protocol VideoViewDelegate: AnyObject {
    func didUpdateStatus(isVideoOn: Bool)
}

@IBDesignable
class VideoView: CustomView {
    @IBOutlet weak var videoView: TwilioVideo.VideoView!
    weak var delegate: VideoViewDelegate?
    private var videoTrack: VideoTrack?
    private var isVideoOn = false {
        didSet {
            isHidden = !isVideoOn
            delegate?.didUpdateStatus(isVideoOn: !isHidden)
        }
    }
    
    deinit {
        videoTrack?.removeRenderer(videoView) // TODO: Really needed?
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        videoView.delegate = self
        isHidden = true
    }

    func configure(
        videoTrack: VideoTrack?,
        shouldMirror: Bool = false,
        contentMode: UIView.ContentMode = .scaleAspectFit
    ) {
        guard let videoTrack = videoTrack, videoTrack.isEnabled else {
            self.videoTrack?.removeRenderer(videoView)
            isVideoOn = false
            return
        }

        self.videoTrack?.removeRenderer(videoView)
        self.videoTrack = videoTrack
        videoTrack.addRenderer(videoView)
        videoView.shouldMirror = shouldMirror
        isHidden = !videoView.hasVideoData
        videoView.contentMode = contentMode
    }
}

// TODO: Make private?
extension VideoView: TwilioVideo.VideoViewDelegate {
    func videoViewDidReceiveData(view: TwilioVideo.VideoView) {
        isVideoOn = true
    }
}
