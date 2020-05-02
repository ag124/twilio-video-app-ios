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
    func didConnect()
    func didFailToConnect(error: Error)
    func didDisconnect(error: Error?)
    func didUpdate()
    func didAddRemoteParticipants(at indexes: [Int])
    func didRemoveRemoteParticipant(at index: Int)
}

// TODO: Rename to RoomStore?
class Room: NSObject {
    weak var delegate: RoomDelegate?
    var isRecording: Bool { room?.isRecording ?? false }
    let localParticipant: LocalParticipant
    var remoteParticipants: [RemoteParticipant] = [] // Maybe I don't have to cache these anymore
    private let accessTokenStore: TwilioAccessTokenStoreReading
    private let connectOptionsFactory: ConnectOptionsFactory
    private var room: TwilioVideo.Room?
    
    init(
        localParticipant: LocalParticipant,
        accessTokenStore: TwilioAccessTokenStoreReading,
        connectOptionsFactory: ConnectOptionsFactory
    ) {
        self.localParticipant = localParticipant
        self.accessTokenStore = accessTokenStore
        self.connectOptionsFactory = connectOptionsFactory
    }

    // TODO: Create new status that includes fetching access token
    func connect(roomName: String) {
        // TODO: Fatal error if we are already connecting or connected
        
        accessTokenStore.fetchTwilioAccessToken(roomName: roomName) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .success(accessToken):
                // TODO: Why would audio or video track be nil?
                let options = self.connectOptionsFactory.makeConnectOptions(
                    accessToken: accessToken,
                    roomName: roomName,
                    audioTracks: [self.localParticipant.micAudioTrack].compactMap { $0 },
                    videoTracks: [self.localParticipant.localCameraVideoTrack].compactMap { $0 }
                )
                // TODO: Inject
                self.room = TwilioVideoSDK.connect(options: options, delegate: self)
            case let .failure(error):
                self.delegate?.didFailToConnect(error: error)
            }
        }
    }

    private func updateRemoteParticipants() {
        guard let room = room else { remoteParticipants = []; return }
        
        remoteParticipants = room.remoteParticipants.map { RemoteParticipant(participant: $0) }
    }
}

extension Room: TwilioVideo.RoomDelegate {
    func roomDidConnect(room: TwilioVideo.Room) {
        print("Connect remote participant count: \(room.remoteParticipants.count)")
        localParticipant.participant = room.localParticipant
        updateRemoteParticipants()
        delegate?.didConnect()
        
        if remoteParticipants.count > 0 {
            delegate?.didAddRemoteParticipants(at: [Int](remoteParticipants.indices))
        }
    }
    
    func roomDidFailToConnect(room: TwilioVideo.Room, error: Error) {
        self.room = nil
        delegate?.didFailToConnect(error: error)
    }
    
    func roomDidDisconnect(room: TwilioVideo.Room, error: Error?) {
        self.room = nil
        let oldIndices = remoteParticipants.indices
        updateRemoteParticipants()
        delegate?.didDisconnect(error: error)
        
        if oldIndices.count > 0 {
            delegate?.didAddRemoteParticipants(at: [Int](oldIndices)) // TODO: Should be remove I think
        }
    }
    
    func participantDidConnect(room: TwilioVideo.Room, participant: TwilioVideo.RemoteParticipant) {
        print("Participant did connect participant count: \(room.remoteParticipants.count)")
        updateRemoteParticipants()
        delegate?.didAddRemoteParticipants(at: [remoteParticipants.count - 1])
    }
    
    func participantDidDisconnect(room: TwilioVideo.Room, participant: TwilioVideo.RemoteParticipant) {
        print("Participant did disconnect participant count: \(room.remoteParticipants.count)")
        // TODO: Log error
        guard let index = remoteParticipants.firstIndex(where: { $0.identity == participant.identity }) else { return }
        
        updateRemoteParticipants()
        delegate?.didRemoveRemoteParticipant(at: index)
    }
    
    func roomDidStartRecording(room: TwilioVideo.Room) {
        // Do nothing
    }
    
    func roomDidStopRecording(room: TwilioVideo.Room) {
        // Do nothing
    }
    
    func dominantSpeakerDidChange(room: TwilioVideo.Room, participant: TwilioVideo.RemoteParticipant?) {
        guard let participant = participant else { return }
        
        remoteParticipants.forEach { $0.isDominantSpeaker = false }
        remoteParticipants.first(where: { $0.identity == participant.identity })?.isDominantSpeaker = true
    }
}
