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

protocol RoomDelegate: AnyObject {
    func didUpdate()
}

class Room: NSObject {
    weak var delegate: RoomDelegate?
    var isRecording: Bool { room.isRecording }
    var localParticipant: LocalParticipant!
    var remoteParticipants: [RemoteParticipant] = []
    private let room: TwilioVideo.Room
    private let localMediaController: LocalMediaController
    
    init(room: TwilioVideo.Room, localMediaController: LocalMediaController) {
        self.room = room
        self.localMediaController = localMediaController
    }

    private func updateRemoteParticipants() {
        remoteParticipants = room.remoteParticipants.map { RemoteParticipant(participant: $0) }
        remoteParticipants.forEach { $0.delegate = self }
    }
}

extension Room: TwilioVideo.RoomDelegate {
    func roomDidConnect(room: TwilioVideo.Room) {
        localParticipant = LocalParticipant(participant: room.localParticipant!, localMediaController: localMediaController)
        delegate?.didUpdate()
    }
    
    func roomDidFailToConnect(room: TwilioVideo.Room, error: Error) {

    }
    
    func roomDidDisconnect(room: TwilioVideo.Room, error: Error?) {
        
    }
    
    func participantDidConnect(room: TwilioVideo.Room, participant: TwilioVideo.RemoteParticipant) {
        updateRemoteParticipants()
        delegate?.didUpdate()
    }
    
    func participantDidDisconnect(room: TwilioVideo.Room, participant: TwilioVideo.RemoteParticipant) {
        updateRemoteParticipants()
        delegate?.didUpdate()
    }
    
    func roomDidStartRecording(room: TwilioVideo.Room) {
        // Do nothing
    }
    
    func roomDidStopRecording(room: TwilioVideo.Room) {
        // Do nothing
    }
    
    func dominantSpeakerDidChange(room: TwilioVideo.Room, participant: TwilioVideo.RemoteParticipant?) {

    }
}

extension Room: ParticipantDelegate {
    func didUpdate() {
        delegate?.didUpdate()
    }
}
