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
    var cameraTrack: VideoTrack? { localCameraTrack }
    var screenTrack: VideoTrack? { nil }
    var shouldMirrorCameraVideo: Bool { cameraPosition == .front }
    var networkQualityLevel: NetworkQualityLevel { participant?.networkQualityLevel ?? .unknown }
    let isRemote = false
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

            postUpdate()
        }
    }
    let isDominantSpeaker = false
    var isPinned = false
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

            postUpdate()
        }
    }
    var participant: TwilioVideo.LocalParticipant? {
        didSet { participant?.delegate = self }
    }
    var localCameraTrack: LocalVideoTrack? { camera?.track }
    var cameraPosition: AVCaptureDevice.Position = .front {
        didSet { camera?.position = cameraPosition }
    }
    private(set) var micTrack: LocalAudioTrack?
    private let micTrackFactory: MicTrackFactory
    private let cameraFactory: CameraFactory
    private let notificationCenter: NotificationCenter
    private var camera: Camera?

    init(
        identity: String,
        micTrackFactory: MicTrackFactory,
        cameraFactory: CameraFactory,
        notificationCenter: NotificationCenter
    ) {
        self.identity = identity
        self.micTrackFactory = micTrackFactory
        self.cameraFactory = cameraFactory
        self.notificationCenter = notificationCenter
    }

    private func postUpdate() {
        let payload = ParticipantUpdate.didUpdate(participant: self)
        notificationCenter.post(name: .participantDidChange, object: self, payload: payload)
    }
}

extension LocalParticipant: ListDiffable {
    func diffIdentifier() -> NSObjectProtocol {
        identity as NSString
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        true // Don't use this to detect updates because the SDK tells us when a participant updates
    }
}

extension LocalParticipant: LocalParticipantDelegate {
    func localParticipantDidFailToPublishVideoTrack(
        participant: TwilioVideo.LocalParticipant,
        videoTrack: LocalVideoTrack,
        error: Error
    ) {
        print("Failed to publish video track: \(error)")
    }
    
    func localParticipantDidFailToPublishAudioTrack(
        participant: TwilioVideo.LocalParticipant,
        audioTrack: LocalAudioTrack,
        error: Error
    ) {
        print("Failed to publish audio track: \(error)")
    }
    
    func localParticipantNetworkQualityLevelDidChange(
        participant: TwilioVideo.LocalParticipant,
        networkQualityLevel: NetworkQualityLevel
    ) {
        postUpdate()
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
