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
        let cameraVideoTrack: VideoTrack? // Rename to just videoTrack
        let isPinned: Bool
    }
    
    struct MainParticipant {
        let identity: String
        let shouldMirrorVideo: Bool
        let videoTrack: VideoTrack?
    }
    
    let roomName: String
    let participants: [Participant]
    let mainParticipant: MainParticipant
}

protocol RoomViewModelDelegate: AnyObject {
    func didUpdateData() // TODO: Change to connection changes
    func didAddParticipants(at indexes: [Int])
    func didRemoveParticipant(at index: Int)
    func didUpdateParticipantAttributes(at index: Int) // Observe each participant? No probably bad idea because then it isn't just data
    func didUpdateParticipantVideoConfig(at index: Int)
    func didUpdateMainParticipant()
    func didUpdateMainParticipantVideoConfig()
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

        let mainParticipant = RoomViewModelData.MainParticipant(
            identity: self.mainParticipant.identity,
            shouldMirrorVideo: self.mainParticipant.shouldMirrorVideo,
            videoTrack: self.mainParticipant.screenVideoTrack ?? self.mainParticipant.cameraVideoTrack
        )
        
        return RoomViewModelData(
            roomName: roomName,
            participants: newParticipants,
            mainParticipant: mainParticipant
        )
    }
    var isMicOn: Bool {
        get { room.localParticipant.isMicOn }
        set { room.localParticipant.isMicOn = newValue } // TODO: Make sure the only gets called on a real change
    }
    var isCameraOn: Bool {
        get { room.localParticipant.isCameraOn }
        set { room.localParticipant.isCameraOn = newValue }
    }
    private let roomName: String
    private let room: Room
    private var allParticipants: [Participant] { [room.localParticipant] + room.remoteParticipants }
    private var pinnedParticipant: RoomViewModelData.Participant?
    private var rawPinnedParticipant: Participant? {
        guard let pinnedParticipant = pinnedParticipant else { return nil }
        
        return room.remoteParticipants.first(where: { $0.identity == pinnedParticipant.identity })
    }
    private var dominantSpeaker: Participant? {
        room.remoteParticipants.first(where: { $0.isDominantSpeaker })
    }
    private var mainParticipant: Participant!

    init(roomName: String, room: Room) {
        self.roomName = roomName
        self.room = room
        room.delegate = self
        room.localParticipant.delegate = self
        mainParticipant = calculcateMainParticipant()
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
        
        updateMainParticipant()
    }

    func flipCamera() {
        room.localParticipant.flipCamera()
    }
    
    // Make sure this is done in all correct places
    func updatePin() {
        guard let pinnedParticipant = pinnedParticipant else { return }

        // Cooler way to do this I think
        if allParticipants.first(where: { $0.identity == pinnedParticipant.identity }) == nil {
            self.pinnedParticipant = nil
        }
    }
    
    private func calculcateMainParticipant() -> Participant {
        rawPinnedParticipant ?? dominantSpeaker ?? room.remoteParticipants.first ?? room.localParticipant
    }
    
    private func updateMainParticipant() {
        let mainParticipant = calculcateMainParticipant()
        
        if mainParticipant.identity != self.mainParticipant.identity {
            self.mainParticipant = mainParticipant
            delegate?.didUpdateMainParticipant()
        }
    }
}

extension RoomViewModel: RoomDelegate {
    func didConnect() {
        updateMainParticipant()
        delegate?.didUpdateData()
    }
    
    func didFailToConnect(error: Error) {
        
    }
    
    func didDisconnect(error: Error?) {
        updatePin()
        updateMainParticipant()
        delegate?.didUpdateData()
    }

    // What is this for?
    func didUpdate() {
        delegate?.didUpdateData()
    }

    // I don't think room should have to deal with indexes, oh wait maybe it should because connect is very basic
    func didAddRemoteParticipants(at indexes: [Int]) {
        room.remoteParticipants.forEach { $0.delegate = self }
        delegate?.didAddParticipants(at: indexes.map { $0 + 1 })
        updateMainParticipant()
    }
    
    func didRemoveRemoteParticipant(at index: Int) {
        updatePin() // maybe easier way to do this
        delegate?.didRemoveParticipant(at: index + 1)
        updateMainParticipant()
    }
}

extension RoomViewModel: ParticipantDelegate {
    func didUpdateAttributes(participant: Participant) {
        guard let index = allParticipants.firstIndex(where: { $0.identity == participant.identity }) else { return }
        
        delegate?.didUpdateParticipantAttributes(at: index)
        updateMainParticipant()
    }
    
    func didUpdateVideoConfig(participant: Participant, source: VideoTrackSource) {
        // TODO: Make more DRY

        switch source {
        case .camera:
            guard let index = allParticipants.firstIndex(where: { $0.identity == participant.identity }) else { return }

            delegate?.didUpdateParticipantVideoConfig(at: index)
        case .screen:
            break
        }

        // This needs to be smarter to avoid flashing
        if participant.identity == mainParticipant.identity {
            delegate?.didUpdateMainParticipantVideoConfig()
        }
    }
}
