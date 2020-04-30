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

struct RoomViewModelData {
    struct Participant {
        let identity: String
        let networkQualityLevel: String // TODO: Enum
        let isAudioMuted: Bool
        let shouldMirrorVideo: Bool
        let cameraVideoTrack: VideoTrack?
    }
    
    let roomName: String
    let participants: [Participant]
}

protocol RoomViewModelDelegate: AnyObject {
    func didUpdateData()
}

class RoomViewModel {
    weak var delegate: RoomViewModelDelegate?
    var data: RoomViewModelData {
        guard let room = roomStore.room else { return RoomViewModelData(roomName: roomName, participants: []) }
        
        let participants: [Participant] = [room.localParticipant] + room.remoteParticipants
        let newParticipants = participants.map {
            RoomViewModelData.Participant(
                identity: $0.identity,
                networkQualityLevel: "",
                isAudioMuted: false,
                shouldMirrorVideo: false,
                cameraVideoTrack: $0.cameraVideoTrack
            )
        }
        
        return RoomViewModelData(
            roomName: roomName,
            participants: newParticipants
        )
    }
    var isMicOn: Bool {
        get { roomStore.room?.localParticipant.isMicOn ?? false
        }
        set {
            // TODO: Make sure the only gets called on a real change
            roomStore.room?.localParticipant.isMicOn = newValue
        }
    }
    private let roomName: String
    private let roomStore: RoomStore
    private let localMediaController: LocalMediaController

    init(roomName: String, roomStore: RoomStore, localMediaController: LocalMediaController) {
        self.roomName = roomName
        self.roomStore = roomStore
        self.localMediaController = localMediaController
        roomStore.delegate = self
    }
    
    func connect() {
        roomStore.connect(roomName: roomName)
    }
}

extension RoomViewModel: RoomStoreDelegate {
    func didConnect() {
        roomStore.room?.delegate = self
        delegate?.didUpdateData()
    }
    
    func didFailToConnect(error: Error) {
        
    }
    
    func didDisconnect(error: Error?) {
        delegate?.didUpdateData()
    }
}

extension RoomViewModel: RoomDelegate {
    func didUpdate() {
        delegate?.didUpdateData()
    }
}
