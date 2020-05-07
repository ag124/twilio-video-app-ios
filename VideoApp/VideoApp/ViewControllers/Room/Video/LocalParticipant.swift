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

import IGListDiffKit
import TwilioVideo

class LocalParticipant: NSObject, Participant {
    let identity: String
    var cameraVideoTrack: VideoTrack? { localCameraVideoTrack }
    var screenVideoTrack: VideoTrack? { nil }
    var localCameraVideoTrack: LocalVideoTrack? { camera?.track }
    var shouldMirrorVideo: Bool { cameraPosition == .front }
    let isRemote = false
    var isPinned = false
    let isDominantSpeaker = false
    var networkQualityLevel: NetworkQualityLevel { participant?.networkQualityLevel ?? .unknown }
    var isMicOn: Bool {
        get {
            micTrack?.isEnabled ?? false
        }
        set {
            if newValue {
                guard micTrack == nil, let micTrack = micTrackFactory.makeMicTrack() else { return }
                
                self.micTrack = micTrack
                participant?.publishAudioTrack(micTrack)
            } else {
                guard let micTrack = micTrack else { return }
                
                participant?.unpublishAudioTrack(micTrack)
                self.micTrack = nil
            }

            postChange(.didUpdate(participant: self))
        }
    }
    var isCameraOn: Bool {
        get {
            camera?.track.isEnabled ?? false
        }
        set {
            if newValue {
                guard camera == nil, let camera = cameraFactory.makeCamera(position: cameraPosition) else { return }
                
                self.camera = camera
                camera.delegate = self
                participant?.publishVideoTrack(camera.track)
            } else {
                guard let camera = camera else { return }
                
                participant?.unpublishVideoTrack(camera.track)
                self.camera = nil
            }

            postChange(.didUpdate(participant: self))
            NSLog("TCR: Post change")
        }
    }
    var participant: TwilioVideo.LocalParticipant? {
        didSet {
            participant?.delegate = self
        }
    }
    var cameraPosition: AVCaptureDevice.Position = .front {
        didSet { camera?.position = cameraPosition }
    }
    private(set) var micTrack: LocalAudioTrack?
    private let notificationCenter = NotificationCenter.default
    private let micTrackFactory: MicTrackFactory
    private let cameraFactory: CameraFactory
    private var camera: Camera?
    
    init(identity: String, micTrackFactory: MicTrackFactory, cameraFactory: CameraFactory) {
        self.identity = identity
        self.micTrackFactory = micTrackFactory
        self.cameraFactory = cameraFactory
    }

    private func postChange(_ change: ParticipantUpdate) {
        self.notificationCenter.post(name: .participantDidChange, object: self, userInfo: ["key": change])
    }
}

extension LocalParticipant {
    func diffIdentifier() -> NSObjectProtocol {
        identity as NSString
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        return true // Don't use this to detect updates because the SDK tells us when a participant updates
    }
}

extension LocalParticipant: LocalParticipantDelegate {
    func localParticipantDidFailToPublishVideoTrack(
        participant: TwilioVideo.LocalParticipant,
        videoTrack: LocalVideoTrack,
        error: Error
    ) {

    }
    
    func localParticipantDidFailToPublishAudioTrack(
        participant: TwilioVideo.LocalParticipant,
        audioTrack: LocalAudioTrack,
        error: Error
    ) {

    }
    
    func localParticipantNetworkQualityLevelDidChange(
        participant: TwilioVideo.LocalParticipant,
        networkQualityLevel: NetworkQualityLevel
    ) {
        postChange(.didUpdate(participant: self))
    }
}

extension LocalParticipant: CameraDelegate {
    func cameraSourceWasInterrupted(camera: Camera) {
        participant?.unpublishVideoTrack(camera.track)
    }
    
    func cameraSourceInterruptionEnded(camera: Camera) {
        participant?.publishVideoTrack(camera.track)
    }
}
