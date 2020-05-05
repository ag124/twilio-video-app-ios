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

protocol RoomViewModelDelegate: AnyObject {
    func didUpdateData() // TODO: Change to connection changes
    func didAddParticipants(at indexes: [Int])
    func didRemoveParticipants(at indices: [Int])
    func didMoveParticipant(at index: Int, to newIndex: Int)
    func didUpdateParticipantAttributes(at index: Int) // Observe each participant? No probably bad idea because then it isn't just data
    func didUpdateMainParticipant()
}

class RoomViewModel {
    weak var delegate: RoomViewModelDelegate?
    var data: RoomViewModelData {
        .init(
            roomName: roomName,
            participants: participantList.participants.map { .init(participant: $0) },
            mainParticipant: .init(participant: mainParticipantStore.mainParticipant)
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
    private let participantList: ParticipantList!
    private let mainParticipantStore: MainParticipantStore!
    private let notificationCenter = NotificationCenter.default

    init(roomName: String, room: Room) {
        self.roomName = roomName
        self.room = room
        participantList = ParticipantList(room: room)
        mainParticipantStore = MainParticipantStore(room: room, participantList: participantList)
        notificationCenter.addObserver(self, selector: #selector(handleRoomDidChangeNotification(_:)), name: .roomDidChange, object: nil)
        notificationCenter.addObserver(self, selector: #selector(participantListChange(_:)), name: .participantListChange, object: nil)
        notificationCenter.addObserver(self, selector: #selector(mainParticipantChange(_:)), name: .mainParticipantStoreChange, object: nil)
    }
    
    func connect() {
        room.connect(roomName: roomName)
    }
    
    func togglePin(at index: Int) {
        participantList.togglePin(at: index)
    }

    func flipCamera() {
        room.localParticipant.flipCamera()
    }
    
    @objc func handleRoomDidChangeNotification(_ notification: Notification) {
        guard let change = notification.userInfo?["key"] as? RoomChange else { return }
        
        switch change {
        case .didConnect:
            delegate?.didUpdateData()
        case .didFailToConnect: // TODO: Handle error
            break
        case .didDisconnect: // TODO: Handle error
            delegate?.didUpdateData()
        case .didAddRemoteParticipants, .didRemoveRemoteParticipants, .dominantSpeakerDidChange:
            break
        }
    }

    // TODO: Maybe have data source observe directly
    @objc func participantListChange(_ notification: Notification) {
        guard let change = notification.userInfo?["key"] as? ParticipantListChange else { return }

        switch change {
        case let .didInsertParticipants(indices):
            delegate?.didAddParticipants(at: indices)
        case let .didDeleteParticipants(indices):
            delegate?.didRemoveParticipants(at: indices)
        case let .didMoveParticipant(oldIndex, newIndex):
            delegate?.didMoveParticipant(at: oldIndex, to: newIndex)
        case let .didUpdateParticipant(index):
            delegate?.didUpdateParticipantAttributes(at: index)
        }
    }
    
    @objc func mainParticipantChange(_ notification: Notification) {
        guard let change = notification.userInfo?["key"] as? MainParticipantStoreChange else { return }

        switch change {
        case .didUpdateMainParticipant:
            delegate?.didUpdateMainParticipant()
        }
    }
}
