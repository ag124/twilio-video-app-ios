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

typealias NetworkQualityLevel = TwilioVideo.NetworkQualityLevel

enum ParticipantUpdate {
    case didUpdate(participant: Participant)
}

protocol Participant: AnyObject {
    var identity: String { get }
    var cameraVideoTrack: VideoTrack? { get }
    var screenVideoTrack: VideoTrack? { get }
    var isMicOn: Bool { get }
    var shouldMirrorVideo: Bool { get } // Rename to should mirror camera, might be able to remove this or implement in extension
    var networkQualityLevel: NetworkQualityLevel { get }
    var isRemote: Bool { get }
    var isPinned: Bool { get set }
    var isDominantSpeaker: Bool { get }
}
