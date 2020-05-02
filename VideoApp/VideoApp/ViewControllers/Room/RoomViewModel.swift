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
    func didRemoveParticipant(at index: Int)
    func didUpdateParticipantAttributes(at index: Int) // Observe each participant? No probably bad idea because then it isn't just data
    func didUpdateParticipantVideoConfig(at index: Int)
    func didUpdateMainParticipant()
    func didUpdateMainParticipantVideoConfig()
}

class RoomViewModel {
    weak var delegate: RoomViewModelDelegate?
    private var participantsCache: [RoomViewModelData.Participant] = []
    private var mainParticipantCache: RoomViewModelData.MainParticipant!
    var data: RoomViewModelData!
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
    private var dominantSpeakerIdentity: String?

    init(roomName: String, room: Room) {
        self.roomName = roomName
        self.room = room
        room.delegate = self
        room.localParticipant.delegate = self
        participantsCache = [.init(participant: room.localParticipant, isPinned: false)]
        // calculateMainParticipant()
    }
    
    func connect() {
        room.connect(roomName: roomName)
    }
    
    func togglePin(at index: Int) {
        // Maybe there is an easier way to do this like use a class
        updateParticipantsCache(
            new: participantsCache.map {
                RoomViewModelData.Participant(
                    identity: $0.identity,
                    status: .init(
                        isMicMuted: $0.status.isMicMuted,
                        networkQualityLevel: $0.status.networkQualityLevel,
                        isPinned: participantsCache[index].identity == $0.identity),
                    videoConfig: $0.videoConfig
                )
            }
        )
    }

    func flipCamera() {
        room.localParticipant.flipCamera()
    }
    
    private func calculateMainParticipant() -> RoomViewModelData.MainParticipant {
        let pinnedParticipant = participantsCache.first(where: { $0.status.isPinned })
        let dominantSpeaker = participantsCache.first(where: { $0.identity == dominantSpeakerIdentity })
        
        let firstRemoteParticipant: RoomViewModelData.Participant?
        
        // TODO: Probably need my own storage for this and to not couple participants and main participant data :(
        if participantsCache.count > 1 {
            firstRemoteParticipant = participantsCache[1]
        } else {
            firstRemoteParticipant = nil
        }

        return pinnedParticipant ?? dominantSpeaker ?? firstRemoteParticipant ?? participantsCache[0]
    }
    
    private func updateMainParticipant() {
        // calculateMainParticipant()
        
        // Diff, Save and call delegate
    }
    
    private func updateParticipantsCache(new: [RoomViewModelData.Participant]) {
        // TODO: Diff for insert, delete, move, update and call delegate
        
        // TODO: Calculate main participant, diff, save and call delegate
        
        participantsCache = new
    }
}

extension RoomViewModel: RoomDelegate {
    func didConnect() {
        delegate?.didUpdateData()
    }
    
    func didFailToConnect(error: Error) {
        
    }
    
    func didDisconnect(error: Error?) {
        updateParticipantsCache(new: [participantsCache[0]])
        delegate?.didUpdateData()
    }

    // What is this for?
    func didUpdate() {
        delegate?.didUpdateData()
    }

    // Rename to remove remote?
    func didAddRemoteParticipants(participants: [Participant]) {
        // TODO: Sort for screen share
        participants.forEach { $0.delegate = self }
        updateParticipantsCache(new: participantsCache + participants.map { .init(participant: $0, isPinned: false) })
    }
    
    func didRemoveRemoteParticipant(participant: Participant) {
        // TODO: Sort
        updateParticipantsCache(new: participantsCache.filter { $0.identity != participant.identity })
    }
}

extension RoomViewModel: ParticipantDelegate {
    // TODO: Probably only need one of these functions now or maybe just use room delegate
    func didUpdateAttributes(participant: Participant) {
        guard let index = participantsCache.firstIndex(where: { $0.identity == participant.identity }) else { return }
        
        participantsCache[index] = .init(participant: participant, isPinned: false) // TODO: Make pin work
    }
    
    func didUpdateVideoConfig(participant: Participant, source: VideoTrackSource) {
        guard let index = participantsCache.firstIndex(where: { $0.identity == participant.identity }) else { return }
        
        participantsCache[index] = .init(participant: participant, isPinned: false) // TODO: Make pin work
    }
}
