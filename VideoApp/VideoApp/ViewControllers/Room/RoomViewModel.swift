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

protocol RoomViewModelDelegate: AnyObject {
    func didUpdateData() // TODO: Change to connection changes
    func didAddParticipants(at indexes: [Int])
    func didRemoveParticipants(at indices: [Int])
    func didMoveParticipant(at index: Int, to newIndex: Int)
    func didUpdateParticipantAttributes(at index: Int) // Observe each participant? No probably bad idea because then it isn't just data
    func didUpdateParticipantVideoConfig(at index: Int)
    func didUpdateMainParticipant()
    func didUpdateMainParticipantVideoConfig()
}

class RoomViewModel {
    weak var delegate: RoomViewModelDelegate?
    var data: RoomViewModelData {
        .init(
            roomName: roomName,
            participants: participantList.participants.map { .init(participant: $0, isPinned: false) }, // Make pin work
            mainParticipant: .init(participant: mainParticipant)
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
    private let participantList = ParticipantList()
    private var mainParticipant: Participant!

    init(roomName: String, room: Room) {
        self.roomName = roomName
        self.room = room
        room.delegate = self
        participantList.insertParticipants(participants: [room.localParticipant]) // use abstracted type
        participantList.delegate = self // Must be after initial insert so we don't get called during init
        mainParticipant = calculateMainParticipant()
    }
    
    func connect() {
        room.connect(roomName: roomName)
    }
    
    func togglePin(at index: Int) {

    }

    func flipCamera() {
        room.localParticipant.flipCamera()
    }
    
    private func calculateMainParticipant() -> Participant {
        // TODO: Move to extension or something
        // TODO: Pin
        let screenSharingParticipant = participantList.participants.first(where: { $0.screenVideoTrack != nil })
        let dominantSpeaker = participantList.participants.first(where: { $0.isDominantSpeaker })
        let firstRemoteParticipant = participantList.participants.first(where: { $0.isRemote })

        
        return screenSharingParticipant ?? dominantSpeaker ?? firstRemoteParticipant ?? room.localParticipant
    }
    
    private func updateMainParticipant() {
        mainParticipant = calculateMainParticipant()
        // TODO: Call delegate
    }
}

extension RoomViewModel: RoomDelegate {
    func didConnect() {
        delegate?.didUpdateData()
    }
    
    func didFailToConnect(error: Error) {
        
    }
    
    func didDisconnect(error: Error?) {
        participantList.deleteParticipants(participants: participantList.participants.filter { $0.isRemote })
        delegate?.didUpdateData()
    }

    // What is this for?
    func didUpdate() {
        delegate?.didUpdateData()
    }

    // Rename to remove remote?
    func didAddRemoteParticipants(participants: [Participant]) {
        participantList.insertParticipants(participants: participants)
    }
    
    func didRemoveRemoteParticipants(participants: [Participant]) {
        participantList.deleteParticipants(participants: participants)
    }
}

extension RoomViewModel: ParticipanListDelegate {
    func didInsertParticipants(at indices: [Int]) {
        delegate?.didAddParticipants(at: indices)
        updateMainParticipant()
    }
    
    func didDeleteParticipants(at indices: [Int]) {
        delegate?.didRemoveParticipants(at: indices)
        updateMainParticipant()
    }
    
    func didMoveParticipant(at index: Int, to newIndex: Int) {
        delegate?.didMoveParticipant(at: index, to: newIndex)
    }
    
    func didUpdateStatus(for index: Int) {
        delegate?.didUpdateParticipantAttributes(at: index)
    }
    
    func didUpdateVideoConfig(for index: Int) {
        delegate?.didUpdateParticipantVideoConfig(at: index)
    }
}
