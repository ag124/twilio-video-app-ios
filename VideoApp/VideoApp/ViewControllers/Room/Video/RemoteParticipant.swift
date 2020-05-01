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

class RemoteParticipant: NSObject, Participant {
    weak var delegate: ParticipantDelegate?
    var identity: String { participant.identity }
    var isMicOn: Bool { participant.remoteAudioTracks.first?.isTrackEnabled == true } // TODO: Use correct track name
    var cameraVideoTrack: VideoTrack? { participant.remoteVideoTracks.first?.remoteTrack }
    var shouldMirrorVideo: Bool { false }
    var networkQualityLevel: NetworkQualityLevel { participant.networkQualityLevel }
    var isDominantSpeaker = false {
        didSet {
            if isDominantSpeaker != oldValue {
                delegate?.didUpdateAttributes(participant: self) // TODO: Make sure we really need to compare to old value
            }
        }
    }
    private let participant: TwilioVideo.RemoteParticipant
    
    init(participant: TwilioVideo.RemoteParticipant) {
        self.participant = participant
        super.init()
        participant.delegate = self
    }
}

extension RemoteParticipant: RemoteParticipantDelegate {
    func remoteParticipantDidPublishVideoTrack(participant: TwilioVideo.RemoteParticipant, publication: RemoteVideoTrackPublication) {
//        delegate?.didUpdateVideoConfig(participant: self)
    }
    
    func remoteParticipantDidUnpublishVideoTrack(participant: TwilioVideo.RemoteParticipant, publication: RemoteVideoTrackPublication) {
//        delegate?.didUpdateVideoConfig(participant: self)
    }

    func remoteParticipantDidEnableVideoTrack(participant: TwilioVideo.RemoteParticipant, publication: RemoteVideoTrackPublication) {
        delegate?.didUpdateVideoConfig(participant: self)
    }
    
    func remoteParticipantDidDisableVideoTrack(participant: TwilioVideo.RemoteParticipant, publication: RemoteVideoTrackPublication) {
        delegate?.didUpdateVideoConfig(participant: self)
    }
    
    func didSubscribeToVideoTrack(videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication, participant: TwilioVideo.RemoteParticipant) {
        delegate?.didUpdateVideoConfig(participant: self)
    }
    
    func didUnsubscribeFromVideoTrack(videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication, participant: TwilioVideo.RemoteParticipant) {
        delegate?.didUpdateVideoConfig(participant: self)
    }
    
    func remoteParticipantDidEnableAudioTrack(participant: TwilioVideo.RemoteParticipant, publication: RemoteAudioTrackPublication) {
        delegate?.didUpdateAttributes(participant: self)
    }
    
    func remoteParticipantDidDisableAudioTrack(participant: TwilioVideo.RemoteParticipant, publication: RemoteAudioTrackPublication) {
        delegate?.didUpdateAttributes(participant: self)
    }
    
    func didSubscribeToAudioTrack(audioTrack: RemoteAudioTrack, publication: RemoteAudioTrackPublication, participant: TwilioVideo.RemoteParticipant) {
        delegate?.didUpdateAttributes(participant: self)
    }
    
    func didUnsubscribeFromAudioTrack(audioTrack: RemoteAudioTrack, publication: RemoteAudioTrackPublication, participant: TwilioVideo.RemoteParticipant) {
        delegate?.didUpdateAttributes(participant: self)
    }

    func remoteParticipantNetworkQualityLevelDidChange(participant: TwilioVideo.RemoteParticipant, networkQualityLevel: NetworkQualityLevel) {
        delegate?.didUpdateAttributes(participant: self)
    }
}
