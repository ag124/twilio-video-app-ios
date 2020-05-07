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

import AVFoundation // TODO: Maybe avoid this
import IGListDiffKit

protocol RoomViewModelDelegate: AnyObject {
    func didConnect()
    func didFailToConnect(error: Error)
    func didDisconnect(error: Error?)
    func didUpdateParticipants(diff: ListIndexSetResult)
    func didUpdateParticipantAttributes(at index: Int)
    func didUpdateMainParticipant()
}

class RoomViewModel {
    weak var delegate: RoomViewModelDelegate?
    var data: RoomViewModelData {
        .init(
            roomName: room.state == .connecting ? "Connecting..." : roomName,
            participants: participantsStore.participants.map { .init(participant: $0) },
            mainParticipant: .init(participant: mainParticipantStore.mainParticipant)
        )
    }
    var isMicOn: Bool {
        get { room.localParticipant.isMicOn }
        set { room.localParticipant.isMicOn = newValue }
    }
    var isCameraOn: Bool {
        get { room.localParticipant.isCameraOn }
        set { room.localParticipant.isCameraOn = newValue }
    }
    var cameraPosition: AVCaptureDevice.Position {
        get { room.localParticipant.cameraPosition }
        set { room.localParticipant.cameraPosition = newValue }
    }
    private let roomName: String
    private let room: Room
    private let participantsStore: ParticipantsStore!
    private let mainParticipantStore: MainParticipantStore!
    private let notificationCenter = NotificationCenter.default

    init(roomName: String, room: Room) {
        self.roomName = roomName
        self.room = room
        participantsStore = ParticipantsStore(room: room)
        mainParticipantStore = MainParticipantStore(room: room, participantsStore: participantsStore)
        notificationCenter.addObserver(self, selector: #selector(handleRoomDidChangeNotification(_:)), name: .roomDidChange, object: room)
        notificationCenter.addObserver(self, selector: #selector(participantListChange(_:)), name: .participantListChange, object: participantsStore)
        notificationCenter.addObserver(self, selector: #selector(mainParticipantChange(_:)), name: .mainParticipantStoreChange, object: mainParticipantStore)
    }
    
    func connect() {
        room.connect(roomName: roomName)
    }
    
    func disconnect() {
        room.disconnect()
    }
    
    func togglePin(at index: Int) {
        participantsStore.togglePin(at: index)
    }

    @objc func handleRoomDidChangeNotification(_ notification: Notification) {
        guard let change = notification.userInfo?["key"] as? RoomChange else { return }
        
        switch change {
        case .didStartConnecting, .didConnect: delegate?.didConnect()
        case let .didFailToConnect(error): delegate?.didFailToConnect(error: error)
        case let .didDisconnect(error): delegate?.didDisconnect(error: error)
        case .didAddRemoteParticipants, .didRemoveRemoteParticipants: break
        }
    }

    // TODO: Maybe have data source observe directly
    @objc func participantListChange(_ notification: Notification) {
        guard let change = notification.userInfo?["key"] as? ParticipantListChange else { return }

        switch change {
        case let .didUpdateList(diff): delegate?.didUpdateParticipants(diff: diff)
        case let .didUpdateParticipant(index): delegate?.didUpdateParticipantAttributes(at: index)
        }
    }
    
    @objc func mainParticipantChange(_ notification: Notification) {
        guard let change = notification.userInfo?["key"] as? MainParticipantStoreChange else { return }

        switch change {
        case .didUpdateMainParticipant: delegate?.didUpdateMainParticipant()
        }
    }
}
