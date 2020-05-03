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
    // Dominant speaker
    // Pinned participant
    // Main participant
    
    func insertParticipants(participants: [Participant]) {
        participants.forEach { participant in
            participant.delegate = self
            
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
    
    func deleteParticipants(participants: [Participant]) {
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

extension ParticipantList: ParticipantDelegate {
    func didUpdateAttributes(participant: Participant) {
        guard let index = participants.index(of: participant) else { return }
        
        delegate?.didUpdateStatus(for: index)
    }
    
    func didUpdateVideoConfig(participant: Participant, source: VideoTrackSource) {
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

private extension Array where Element == Participant {
    var newScreenIndex: Int { firstIndex(where: { $0.isRemote }) ?? endIndex }
    func index(of participant: Participant) -> Int? { firstIndex(where: { $0 === participant }) }
}
