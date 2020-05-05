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

class LocalParticipant: NSObject, Participant {
    let identity: String
    var micAudioTrack: LocalAudioTrack? { localMediaController.localAudioTrack } // Use track name
    var cameraVideoTrack: VideoTrack? { localMediaController.localVideoTrack } // Use track name
    var screenVideoTrack: VideoTrack? { nil }
    var localCameraVideoTrack: LocalVideoTrack? { localMediaController.localVideoTrack } // Use track name
    let shouldMirrorVideo = true
    let isRemote = false
    var isPinned = false
    let isDominantSpeaker = false
    var networkQualityLevel: NetworkQualityLevel { participant?.networkQualityLevel ?? .unknown }
    var isMicOn: Bool {
        get {
            localMediaController.localAudioTrack?.isEnabled ?? false // TODO: Use mic track name
        }
        set {
            if newValue {
                localMediaController.createLocalAudioTrack()
                
                if let localAudioTrack = localMediaController.localAudioTrack {
                    participant?.publishAudioTrack(localAudioTrack)
                }
            } else {
                guard let localAudioTrack = localMediaController.localAudioTrack else { return }
                
                participant?.unpublishAudioTrack(localAudioTrack) // TODO: Rename this to mic
                localMediaController.destroyLocalAudioTrack()
            }
            
            postChange(.didUpdate(participant: self))
        }
    }
    var isCameraOn: Bool {
        get {
            localMediaController.localVideoTrack?.isEnabled ?? false
        }
        set {
            if newValue {
                localMediaController.createLocalVideoTrack()
                
                if let localVideoTrack = localMediaController.localVideoTrack {
                    participant?.publishVideoTrack(localVideoTrack)
                }
            } else {
                guard let localVideoTrack = localMediaController.localVideoTrack else { return }
                
                participant?.unpublishVideoTrack(localVideoTrack)
                localMediaController.destroyLocalVideoTrack()
            }

            postChange(.didUpdate(participant: self))
        }
    }
    var participant: TwilioVideo.LocalParticipant? {
        didSet {
            participant?.delegate = self
        }
    }
    private let localMediaController: LocalMediaController
    private let notificationCenter = NotificationCenter.default
    
    init(identity: String, localMediaController: LocalMediaController) {
        self.identity = identity
        self.localMediaController = localMediaController
        super.init()
    }
    
    func flipCamera() {
        localMediaController.flipCamera()
    }

    private func postChange(_ change: ParticipantUpdate) {
        self.notificationCenter.post(name: .participantDidChange, object: self, userInfo: ["key": change])
    }
}

extension LocalParticipant: LocalParticipantDelegate {
    func localParticipantDidPublishVideoTrack(participant: TwilioVideo.LocalParticipant, videoTrackPublication: LocalVideoTrackPublication) {
        // TODO: notify delegate somehow
    }
    
    func localParticipantDidFailToPublishVideoTrack(participant: TwilioVideo.LocalParticipant, videoTrack: LocalVideoTrack, error: Error) {

    }
    
    func localParticipantDidPublishAudioTrack(participant: TwilioVideo.LocalParticipant, audioTrackPublication: LocalAudioTrackPublication) {

    }
    
    func localParticipantDidFailToPublishAudioTrack(participant: TwilioVideo.LocalParticipant, audioTrack: LocalAudioTrack, error: Error) {

    }
    
    func localParticipantNetworkQualityLevelDidChange(participant: TwilioVideo.LocalParticipant, networkQualityLevel: NetworkQualityLevel) {
        postChange(.didUpdate(participant: self))
    }
}
