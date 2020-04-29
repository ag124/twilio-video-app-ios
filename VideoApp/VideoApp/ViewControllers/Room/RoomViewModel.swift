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

@objc class RoomViewModel: NSObject {
    @objc let roomName: String
    @objc var room: Room?
    @objc let localMediaController: LocalMediaController
    @objc var selectedParticipantUIModel: RemoteParticipantUIModel?
    @objc var remoteParticipantUIModels: [RemoteParticipantUIModel] = []
    @objc var mainParticipant: Participant? {
        if let pinnedParticipant = pinnedParticipant {
            return pinnedParticipant
        } else if let dominantSpeaker = dominantSpeaker {
            return dominantSpeaker
        } else {
            return remoteParticipantUIModels.first?.remoteParticipant
        }
    }
    @objc var mainParticipantUIModel: RemoteParticipantUIModel? {
        guard let mainParticipant = mainParticipant else { return nil }
        
        return remoteParticipantUIModels.first { $0.remoteParticipant == mainParticipant }
    }
    @objc var dominantSpeaker: Participant?
    @objc var pinnedParticipant: Participant?
    @objc var allParticipants: [Participant] {
        let localParticipant = localMediaController.localParticipant! as Participant // Don't bang?
        let remoteParticipants = remoteParticipantUIModels.map { $0.remoteParticipant as Participant }
        return [localParticipant] + remoteParticipants
    }

    @objc init(localMediaController: LocalMediaController, roomName: String) {
        self.localMediaController = localMediaController
        self.roomName = roomName
    }
    
    @objc func addRemoteParticipantUIModel(_ model: RemoteParticipantUIModel) {
        remoteParticipantUIModels.append(model)
    }

    @objc func removeAllRemoteParticipantUIModels() {
        remoteParticipantUIModels.removeAll()
    }
    
    @objc func removeRemoteParticipantUIModels(at indexes: IndexSet) {
        indexes.reversed().forEach { remoteParticipantUIModels.remove(at: $0) } // Try to remove this
    }
    
    @objc func togglePin(at index: Int) {
        let participant = allParticipants[index]
        
        if participant == pinnedParticipant {
            pinnedParticipant = nil
        } else {
            pinnedParticipant = participant
        }
    }
}
