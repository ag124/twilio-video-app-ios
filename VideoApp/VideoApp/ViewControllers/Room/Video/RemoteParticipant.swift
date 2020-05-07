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

class RemoteParticipant: NSObject, Participant {
    var identity: String { participant.identity }
    var isMicOn: Bool { participant.remoteAudioTracks.first?.isTrackEnabled == true } // TODO: Use correct track name
    var cameraVideoTrack: VideoTrack? { participant.remoteVideoTracks.first(where: { $0.trackName.contains("camera") })?.remoteTrack }
    var screenVideoTrack: VideoTrack? { participant.remoteVideoTracks.first(where: { $0.trackName.contains("screen") })?.remoteTrack }
    let shouldMirrorVideo = false
    let isRemote = true
    var isPinned = false
    var isDominantSpeaker = false { didSet { postUpdate() } }
    var networkQualityLevel: NetworkQualityLevel { participant.networkQualityLevel }
    private let participant: TwilioVideo.RemoteParticipant
    private let notificationCenter = NotificationCenter.default
    
    init(participant: TwilioVideo.RemoteParticipant) {
        self.participant = participant
        super.init()
        participant.delegate = self
    }
    
    private func postUpdate() {
        self.notificationCenter.post(name: .participantDidChange, object: self, userInfo: ["key": ParticipantUpdate.didUpdate(participant: self)])
    }
}

extension RemoteParticipant {
    func diffIdentifier() -> NSObjectProtocol {
        identity as NSString
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        return true // Don't use this to detect updates because the SDK tells us when a participant updates
    }
}

extension RemoteParticipant: RemoteParticipantDelegate {
    func remoteParticipantDidPublishVideoTrack(
        participant: TwilioVideo.RemoteParticipant,
        publication: RemoteVideoTrackPublication
    ) {
//        delegate?.didUpdateVideoConfig(participant: self)
    }
    
    func remoteParticipantDidUnpublishVideoTrack(
        participant: TwilioVideo.RemoteParticipant,
        publication: RemoteVideoTrackPublication
    ) {
//        delegate?.didUpdateVideoConfig(participant: self)
    }

    func remoteParticipantDidEnableVideoTrack(
        participant: TwilioVideo.RemoteParticipant,
        publication: RemoteVideoTrackPublication
    ) {
        postUpdate()
    }
    
    func remoteParticipantDidDisableVideoTrack(
        participant: TwilioVideo.RemoteParticipant,
        publication: RemoteVideoTrackPublication
    ) {
        postUpdate()
    }
    
    func didSubscribeToVideoTrack(
        videoTrack: RemoteVideoTrack,
        publication: RemoteVideoTrackPublication,
        participant: TwilioVideo.RemoteParticipant
    ) {
        postUpdate()
    }
    
    func didUnsubscribeFromVideoTrack(
        videoTrack: RemoteVideoTrack,
        publication: RemoteVideoTrackPublication,
        participant: TwilioVideo.RemoteParticipant
    ) {
        postUpdate()
    }
    
    func remoteParticipantDidEnableAudioTrack(
        participant: TwilioVideo.RemoteParticipant,
        publication: RemoteAudioTrackPublication
    ) {
        postUpdate()
    }
    
    func remoteParticipantDidDisableAudioTrack(
        participant: TwilioVideo.RemoteParticipant,
        publication: RemoteAudioTrackPublication
    ) {
        postUpdate()
    }
    
    func didSubscribeToAudioTrack(
        audioTrack: RemoteAudioTrack,
        publication: RemoteAudioTrackPublication,
        participant: TwilioVideo.RemoteParticipant
    ) {
        postUpdate()
    }
    
    func didUnsubscribeFromAudioTrack(
        audioTrack: RemoteAudioTrack,
        publication: RemoteAudioTrackPublication,
        participant: TwilioVideo.RemoteParticipant
    ) {
        postUpdate()
    }

    func remoteParticipantNetworkQualityLevelDidChange(
        participant: TwilioVideo.RemoteParticipant,
        networkQualityLevel: NetworkQualityLevel
    ) {
        postUpdate()
    }
}
