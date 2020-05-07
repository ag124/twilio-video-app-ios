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

enum ParticipantListChange {
    case didUpdateParticipant(index: Int)
    case didUpdateList(diff: ListIndexSetResult)
}

class ParticipantsStore {
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
        guard let payload = notification.payload as? RoomChange else { return }
        
        switch payload {
        case .didStartConnecting, .didConnect, .didFailToConnect, .didDisconnect: break
        case let .didAddRemoteParticipants(participants): insertParticipants(participants: participants)
        case let .didRemoveRemoteParticipants(participants): deleteParticipants(participants: participants)
        }
    }

    @objc func handleParticipantDidChangeNotification(_ notification:Notification) {
        guard let payload = notification.payload as? ParticipantUpdate else { return }
        
        switch payload {
        case let .didUpdate(participant):
            guard let index = participants.index(of: participant) else { return }
            
            post(.didUpdateParticipant(index: index))
            
            if participant.screenVideoTrack != nil && index != participants.newScreenIndex {
                var new = participants
                new.remove(at: index)
                new.insert(participant, at: new.newScreenIndex)
                sendDiff(new: new)
            }
        }
    }

    func togglePin(at index: Int) {
        if let oldPinIndex = participants.firstIndex(where: { $0.isPinned }), oldPinIndex != index {
            participants[oldPinIndex].isPinned = false
            post(.didUpdateParticipant(index: oldPinIndex))
        }
        
        participants[index].isPinned = !participants[index].isPinned
        post(.didUpdateParticipant(index: index))
    }
    
    private func insertParticipants(participants: [Participant]) {
        var new = self.participants
        
        participants.forEach { participant in
            let index: Int
            
            if !participant.isRemote {
                index = 0
            } else if participant.screenVideoTrack != nil {
                index = new.newScreenIndex
            } else {
                index = new.endIndex
            }
            
            new.insert(participant, at: index)
        }
        
        sendDiff(new: new)
    }
    
    private func sendDiff(new: [Participant]) {
        let diff = ListDiff(oldArray: self.participants, newArray: new, option: .equality)
        self.participants = new
        post(.didUpdateList(diff: diff))
    }
    
    private func deleteParticipants(participants: [Participant]) {
        let new = self.participants.filter { oldParticipant in
            participants.first { $0 === oldParticipant } == nil
        }

        sendDiff(new: new)
    }
    
    private func post(_ payload: ParticipantListChange) {
        notificationCenter.post(name: .participantListChange, object: self, payload: payload)
    }
}

// TODO: Move
private extension Array where Element == Participant {
    var newScreenIndex: Int { firstIndex(where: { $0.isRemote }) ?? endIndex }
    func index(of participant: Participant) -> Int? { firstIndex(where: { $0 === participant }) }
}
