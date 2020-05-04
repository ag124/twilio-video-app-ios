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

protocol ParticipanListDelegate: AnyObject {
    func didInsertParticipants(at indices: [Int])
    func didDeleteParticipants(at indices: [Int])
    func didMoveParticipant(at index: Int, to newIndex: Int)
    func didUpdateStatus(for index: Int)
    func didUpdateVideoConfig(for index: Int)
}

class ParticipantList {
    weak var delegate: ParticipanListDelegate?
    private(set) var participants: [Participant] = []
    private(set) var pinnedParticipant: Participant?
    private let room: Room
    private let notificationCenter = NotificationCenter.default
    // Pinned participant
    
    init(room: Room) {
        self.room = room
        insertParticipants(participants: [room.localParticipant] + room.remoteParticipants)
        
        notificationCenter.addObserver(self, selector: #selector(handleRoomDidChangeNotification(_:)), name: .roomDidChange, object: nil)
        notificationCenter.addObserver(self, selector: #selector(handleParticipantDidChangeNotification(_:)), name: .participantDidChange, object: nil)
    }

    @objc func handleRoomDidChangeNotification(_ notification:Notification) {
        guard let change = notification.userInfo?["key"] as? RoomChange else { return }
        
        switch change {
        case .didConnect, .didFailToConnect, .didDisconnect, .dominantSpeakerDidChange:
            break
        case let .didAddRemoteParticipants(participants):
            insertParticipants(participants: participants)
        case let .didRemoveRemoteParticipants(participants):
            deleteParticipants(participants: participants)
        }
    }

    @objc func handleParticipantDidChangeNotification(_ notification:Notification) {
        guard let change = notification.userInfo?["key"] as? ParticipantUpdate else { return }
        
        switch change {
        case let .didUpdateAttributes(participant):
            guard let index = participants.index(of: participant) else { return }
            
            delegate?.didUpdateStatus(for: index)
        case let .didUpdateVideoConfig(participant, _): // TODO: Need to use source?
            guard let index = participants.index(of: participant) else { return }

            delegate?.didUpdateVideoConfig(for: index)
            
            if participant.screenVideoTrack != nil {
                participants.remove(at: index)
                let newIndex = participants.newScreenIndex
                participants.insert(participant, at: newIndex)
                delegate?.didMoveParticipant(at: index, to: newIndex)
            }
        }
    }

    func togglePin(at index: Int) {
        let participant = participants[index]
        pinnedParticipant = pinnedParticipant === participant ? nil : participant
        notificationCenter.post(name: .participantListDidChange, object: self) // TODO: Post for other changes?
        // TODO: Post update to delegate for old and new pin
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
            if let index = participants.index(of: participant) {
                indices.append(index)
            }
        }

        delegate?.didInsertParticipants(at: indices)
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

        delegate?.didDeleteParticipants(at: indices)
    }
}

// TODO: Move
private extension Array where Element == Participant {
    var newScreenIndex: Int { firstIndex(where: { $0.isRemote }) ?? endIndex }
    func index(of participant: Participant) -> Int? { firstIndex(where: { $0 === participant }) }
}
