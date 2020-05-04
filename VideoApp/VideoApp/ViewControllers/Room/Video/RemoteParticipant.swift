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

import DeepDiff
import TwilioVideo

class RemoteParticipant: NSObject, Participant, DiffAware {
    var identity: String { participant.identity }
    var isMicOn: Bool { participant.remoteAudioTracks.first?.isTrackEnabled == true } // TODO: Use correct track name
    var cameraVideoTrack: VideoTrack? {
        for track in participant.remoteVideoTracks {
            if track.trackName.contains("camera") {
                return track.remoteTrack
            }
        }
        
        return nil
    }
    var screenVideoTrack: VideoTrack? {
        for track in participant.remoteVideoTracks {
            if track.trackName == "screen" {
                return track.remoteTrack
            }
        }
        
        return nil
    }
    var shouldMirrorVideo: Bool { false }
    var isRemote: Bool { true }
    var networkQualityLevel: NetworkQualityLevel { participant.networkQualityLevel }
    private let participant: TwilioVideo.RemoteParticipant
    private let notificationCenter = NotificationCenter.default
    
    init(participant: TwilioVideo.RemoteParticipant) {
        self.participant = participant
        super.init()
        participant.delegate = self
    }
    
    private func postChange(_ change: ParticipantUpdate) {
        self.notificationCenter.post(name: .participantDidChange, object: self, userInfo: ["key": change])
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
        postChange(.didUpdate(participant: self))
    }
    
    func remoteParticipantDidDisableVideoTrack(participant: TwilioVideo.RemoteParticipant, publication: RemoteVideoTrackPublication) {
        postChange(.didUpdate(participant: self))
    }
    
    func didSubscribeToVideoTrack(videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication, participant: TwilioVideo.RemoteParticipant) {
        postChange(.didUpdate(participant: self))
    }
    
    func didUnsubscribeFromVideoTrack(videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication, participant: TwilioVideo.RemoteParticipant) {
        postChange(.didUpdate(participant: self))
    }
    
    func remoteParticipantDidEnableAudioTrack(participant: TwilioVideo.RemoteParticipant, publication: RemoteAudioTrackPublication) {
        postChange(.didUpdate(participant: self))
    }
    
    func remoteParticipantDidDisableAudioTrack(participant: TwilioVideo.RemoteParticipant, publication: RemoteAudioTrackPublication) {
        postChange(.didUpdate(participant: self))
    }
    
    func didSubscribeToAudioTrack(audioTrack: RemoteAudioTrack, publication: RemoteAudioTrackPublication, participant: TwilioVideo.RemoteParticipant) {
        postChange(.didUpdate(participant: self))
    }
    
    func didUnsubscribeFromAudioTrack(audioTrack: RemoteAudioTrack, publication: RemoteAudioTrackPublication, participant: TwilioVideo.RemoteParticipant) {
        postChange(.didUpdate(participant: self))
    }

    func remoteParticipantNetworkQualityLevelDidChange(participant: TwilioVideo.RemoteParticipant, networkQualityLevel: NetworkQualityLevel) {
        postChange(.didUpdate(participant: self))
    }
}
