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

protocol Participant: AnyObject {
    var delegate: ParticipantDelegate? { get set }
    var identity: String { get }
    var cameraVideoTrack: VideoTrack? { get }
    
    
    // Screen share track
    // Camera track
    // Audio track
    // Network quality
}

protocol ParticipantDelegate: AnyObject {
    func didUpdate()
}

class LocalParticipant: NSObject, Participant {
    weak var delegate: ParticipantDelegate?
    var identity: String { participant.identity }
    var cameraVideoTrack: VideoTrack? { participant.localVideoTracks.first?.localTrack } // Use track name
    var isMicOn: Bool {
        get {
            localMediaController.localAudioTrack != nil
        }
        set {
            if newValue {
                localMediaController.createLocalAudioTrack()
                
                if let localAudioTrack = localMediaController.localAudioTrack {
                    participant.publishAudioTrack(localAudioTrack)
                }
            } else {
                guard let localAudioTrack = localMediaController.localAudioTrack else { return }
                
                participant.unpublishAudioTrack(localAudioTrack) // TODO: Rename this to mic
                localMediaController.destroyLocalAudioTrack()
            }
        }
    }
    private let participant: TwilioVideo.LocalParticipant
    private let localMediaController: LocalMediaController
    
    init(participant: TwilioVideo.LocalParticipant, localMediaController: LocalMediaController) {
        self.participant = participant
        self.localMediaController = localMediaController
        super.init()
        participant.delegate = self
    }
}

extension LocalParticipant: LocalParticipantDelegate {
    func localParticipantDidPublishVideoTrack(participant: TwilioVideo.LocalParticipant, videoTrackPublication: LocalVideoTrackPublication) {
        delegate?.didUpdate()
    }
    
    func localParticipantDidFailToPublishVideoTrack(participant: TwilioVideo.LocalParticipant, videoTrack: LocalVideoTrack, error: Error) {
        delegate?.didUpdate()
    }
    
    func localParticipantDidPublishAudioTrack(participant: TwilioVideo.LocalParticipant, audioTrackPublication: LocalAudioTrackPublication) {
        delegate?.didUpdate()
    }
    
    func localParticipantDidFailToPublishAudioTrack(participant: TwilioVideo.LocalParticipant, audioTrack: LocalAudioTrack, error: Error) {
        delegate?.didUpdate()
    }
    
    func localParticipantNetworkQualityLevelDidChange(participant: TwilioVideo.LocalParticipant, networkQualityLevel: NetworkQualityLevel) {
        delegate?.didUpdate()
    }
}

class RemoteParticipant: NSObject, Participant {
    weak var delegate: ParticipantDelegate?
    var identity: String { participant.identity }
    var cameraVideoTrack: VideoTrack? { participant.remoteVideoTracks.first?.remoteTrack }
    private let participant: TwilioVideo.RemoteParticipant
    
    init(participant: TwilioVideo.RemoteParticipant) {
        self.participant = participant
        super.init()
        participant.delegate = self
    }
}

extension RemoteParticipant: RemoteParticipantDelegate {
    func remoteParticipantDidPublishVideoTrack(participant: TwilioVideo.RemoteParticipant, publication: RemoteVideoTrackPublication) {
        delegate?.didUpdate()
    }
    
    func remoteParticipantDidUnpublishVideoTrack(participant: TwilioVideo.RemoteParticipant, publication: RemoteVideoTrackPublication) {
        delegate?.didUpdate()
    }

    func remoteParticipantDidEnableVideoTrack(participant: TwilioVideo.RemoteParticipant, publication: RemoteVideoTrackPublication) {
        delegate?.didUpdate()
    }
    
    func remoteParticipantDidDisableVideoTrack(participant: TwilioVideo.RemoteParticipant, publication: RemoteVideoTrackPublication) {
        delegate?.didUpdate()
    }
    
    func didSubscribeToVideoTrack(videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication, participant: TwilioVideo.RemoteParticipant) {
        delegate?.didUpdate()
    }
    
    func didUnsubscribeFromVideoTrack(videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication, participant: TwilioVideo.RemoteParticipant) {
        delegate?.didUpdate()
    }
    
    func remoteParticipantDidEnableAudioTrack(participant: TwilioVideo.RemoteParticipant, publication: RemoteAudioTrackPublication) {
        delegate?.didUpdate()
    }
    
    func remoteParticipantDidDisableAudioTrack(participant: TwilioVideo.RemoteParticipant, publication: RemoteAudioTrackPublication) {
        delegate?.didUpdate()
    }
    
    func didSubscribeToAudioTrack(audioTrack: RemoteAudioTrack, publication: RemoteAudioTrackPublication, participant: TwilioVideo.RemoteParticipant) {
        delegate?.didUpdate()
    }
    
    func didUnsubscribeFromAudioTrack(audioTrack: RemoteAudioTrack, publication: RemoteAudioTrackPublication, participant: TwilioVideo.RemoteParticipant) {
        delegate?.didUpdate()
    }

    func remoteParticipantNetworkQualityLevelDidChange(participant: TwilioVideo.RemoteParticipant, networkQualityLevel: NetworkQualityLevel) {
        delegate?.didUpdate()
    }
}
