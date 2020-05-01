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

import TwilioVideo // TODO: Don't import

struct RoomViewModelData {
    struct Participant {
        let identity: String
        let networkQualityLevel: NetworkQualityLevel // TODO: Enum
        let isMicOn: Bool // TODO: Rename to isMicMuted
        let shouldMirrorVideo: Bool
        let cameraVideoTrack: VideoTrack?
        let isPinned: Bool
    }
    
    let roomName: String
    let participants: [Participant]
}

protocol RoomViewModelDelegate: AnyObject {
    func didUpdateData() // TODO: Change to connection changes
    func didAddParticipants(at indexes: [Int])
    func didRemoveParticipant(at index: Int)
    func didUpdateParticipantAttributes(at index: Int)
    func didUpdateParticipantVideoConfig(at index: Int)
}

class RoomViewModel {
    weak var delegate: RoomViewModelDelegate?
    var data: RoomViewModelData {
        let newParticipants = allParticipants.map {
            RoomViewModelData.Participant(
                identity: $0.identity,
                networkQualityLevel: $0.networkQualityLevel,
                isMicOn: $0.isMicOn,
                shouldMirrorVideo: false,
                cameraVideoTrack: $0.cameraVideoTrack,
                isPinned: $0.identity == pinnedParticipant?.identity
            )
        }
        
        return RoomViewModelData(
            roomName: roomName,
            participants: newParticipants
        )
    }
    var isMicOn: Bool {
        get { room.localParticipant.isMicOn
        }
        set {
            // TODO: Make sure the only gets called on a real change
            room.localParticipant.isMicOn = newValue
        }
    }
    private let roomName: String
    private let room: Room
    private var allParticipants: [Participant] { [room.localParticipant] + room.remoteParticipants }
    private var pinnedParticipant: RoomViewModelData.Participant?
    
    init(roomName: String, room: Room) {
        self.roomName = roomName
        self.room = room
        room.delegate = self
        room.localParticipant.delegate = self
    }
    
    func connect() {
        room.connect(roomName: roomName)
    }
    
    // TODO: Use index instead? // Maybe move to Room.Participant
    func togglePin(participant: RoomViewModelData.Participant) {
        if let pinnedParticipant = pinnedParticipant {
            if pinnedParticipant.identity == participant.identity {
                self.pinnedParticipant = nil
                
                if let index = allParticipants.firstIndex(where: { $0.identity == pinnedParticipant.identity }) {
                    delegate?.didUpdateParticipantAttributes(at: index)
                }
            } else {
                self.pinnedParticipant = participant
                
                if let index = allParticipants.firstIndex(where: { $0.identity == participant.identity }) {
                    delegate?.didUpdateParticipantAttributes(at: index)
                }

                if let index = allParticipants.firstIndex(where: { $0.identity == pinnedParticipant.identity }) {
                    delegate?.didUpdateParticipantAttributes(at: index)
                }
            }
        } else {
            self.pinnedParticipant = participant
            
            if let index = allParticipants.firstIndex(where: { $0.identity == participant.identity }) {
                delegate?.didUpdateParticipantAttributes(at: index)
            }
        }
    }

    // Make sure this is done in all correct places
    func updatePin() {
        guard let pinnedParticipant = pinnedParticipant else { return }

        // Cooler way to do this I think
        if allParticipants.first(where: { $0.identity == pinnedParticipant.identity }) == nil {
            self.pinnedParticipant = nil
        }
    }
}

extension RoomViewModel: RoomDelegate {
    func didConnect() {
        delegate?.didUpdateData()
    }
    
    func didFailToConnect(error: Error) {
        
    }
    
    func didDisconnect(error: Error?) {
        updatePin()
        delegate?.didUpdateData()
    }

    // What is this for?
    func didUpdate() {
        delegate?.didUpdateData()
    }

    func didAddRemoteParticipants(at indexes: [Int]) {
        room.remoteParticipants.forEach { $0.delegate = self }
        delegate?.didAddParticipants(at: indexes.map { $0 + 1 })
    }
    
    func didRemoveRemoteParticipant(at index: Int) {
        updatePin() // maybe easier way to do this
        delegate?.didRemoveParticipant(at: index + 1)
    }
}

extension RoomViewModel: ParticipantDelegate {
    func didUpdateAttributes(participant: Participant) {
        guard let index = allParticipants.firstIndex(where: { $0.identity == participant.identity }) else { return }
        
        delegate?.didUpdateParticipantAttributes(at: index)
    }
    
    func didUpdateVideoConfig(participant: Participant) {
        // TODO: Make more DRY
        guard let index = allParticipants.firstIndex(where: { $0.identity == participant.identity }) else { return }

        delegate?.didUpdateParticipantVideoConfig(at: index)
    }
}
