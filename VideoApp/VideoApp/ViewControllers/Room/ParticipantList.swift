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

enum ParticipantListChange {
    case didInsertParticipants(indices: [Int])
    case didDeleteParticipants(indices: [Int])
    case didMoveParticipant(oldIndex: Int, newIndex: Int)
    case didUpdateParticipant(index: Int)
}

class ParticipantList {
    private(set) var participants: [Participant] = []
    private let room: Room
    private let notificationCenter = NotificationCenter.default
    
    init(room: Room) {
        self.room = room
        insertParticipants(participants: [room.localParticipant] + room.remoteParticipants)
        
        notificationCenter.addObserver(self, selector: #selector(handleRoomDidChangeNotification(_:)), name: .roomDidChange, object: nil)
        notificationCenter.addObserver(self, selector: #selector(handleParticipantDidChangeNotification(_:)), name: .participantDidChange, object: nil)
    }

    @objc func handleRoomDidChangeNotification(_ notification:Notification) {
        guard let change = notification.userInfo?["key"] as? RoomChange else { return }
        
        switch change {
        case .didConnect, .didFailToConnect, .didDisconnect: break
        case let .didAddRemoteParticipants(participants): insertParticipants(participants: participants)
        case let .didRemoveRemoteParticipants(participants): deleteParticipants(participants: participants)
        }
    }

    @objc func handleParticipantDidChangeNotification(_ notification:Notification) {
        guard let change = notification.userInfo?["key"] as? ParticipantUpdate else { return }
        
        switch change {
        case let .didUpdate(participant):
            guard let index = participants.index(of: participant) else { return }
            
            post(change: .didUpdateParticipant(index: index))
            
            if participant.screenVideoTrack != nil && index != participants.newScreenIndex {
                participants.remove(at: index)
                let newIndex = participants.newScreenIndex
                participants.insert(participant, at: newIndex)
                post(change: .didMoveParticipant(oldIndex: index, newIndex: newIndex))
            }
        }
    }

    func togglePin(at index: Int) {
        if let oldPinIndex = participants.firstIndex(where: { $0.isPinned }), oldPinIndex != index {
            participants[oldPinIndex].isPinned = false
            post(change: .didUpdateParticipant(index: oldPinIndex))
        }
        
        participants[index].isPinned = !participants[index].isPinned
        post(change: .didUpdateParticipant(index: index))
    }
    
    private func insertParticipants(participants: [Participant]) {
        participants.forEach { participant in
            let index: Int
            
            if !participant.isRemote {
                index = 0
            } else if participant.screenVideoTrack != nil {
                index = self.participants.newScreenIndex
            } else {
                index = self.participants.endIndex
            }
            
            self.participants.insert(participant, at: index)
        }
        
        var indices: [Int] = []

        participants.forEach { participant in
            if let index = self.participants.index(of: participant) {
                indices.append(index)
            }
        }

        post(change: .didInsertParticipants(indices: indices))
    }
    
    private func deleteParticipants(participants: [Participant]) {
        var indices: [Int] = []

        participants.forEach { participant in
            if let index = self.participants.index(of: participant) {
                indices.append(index)
            }
        }
        
        participants.forEach { participant in
            self.participants.removeAll(where: { participant === $0 }) // TODO: Maybe this can be even cleaner
        }

        post(change: .didDeleteParticipants(indices: indices))
    }
    
    private func post(change: ParticipantListChange) {
        self.notificationCenter.post(name: .participantListChange, object: self, userInfo: ["key": change])
    }
}

// TODO: Move
private extension Array where Element == Participant {
    var newScreenIndex: Int { firstIndex(where: { $0.isRemote }) ?? endIndex }
    func index(of participant: Participant) -> Int? { firstIndex(where: { $0 === participant }) }
}
