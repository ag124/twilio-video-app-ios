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

import Foundation

struct RoomViewModelData {
    struct Participant {
        let identity: String
        let status: ParticipantCell.Status
        let videoConfig: VideoView.Config

        init(participant: VideoApp.Participant, isPinned: Bool) {
            identity = participant.identity
            status = .init(
                isMicMuted: participant.isMicOn,
                networkQualityLevel: participant.networkQualityLevel,
                isPinned: isPinned
            )
            videoConfig = .init(videoTrack: participant.cameraVideoTrack, shouldMirror: participant.shouldMirrorVideo)
        }
    }
    
    struct MainParticipant {
        let identity: String
        let videoConfig: VideoView.Config
        
        init(participant: VideoApp.Participant) {
            identity = participant.identity
            videoConfig = .init(
                videoTrack: participant.screenVideoTrack ?? participant.cameraVideoTrack,
                shouldMirror: participant.shouldMirrorVideo
            )
        }
    }
    
    let roomName: String
    let participants: [Participant]
    let mainParticipant: MainParticipant
}
