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

protocol RoomStoreDelegate: AnyObject {
    func didConnect()
    func didFailToConnect(error: Error)
    func didDisconnect(error: Error?)
}

class RoomStore: NSObject {
    weak var delegate: RoomStoreDelegate?
    private(set) var room: Room?
    private let accessTokenStore: TwilioAccessTokenStoreReading
    private let connectOptionsFactory: ConnectOptionsFactory
    private let localParticipant: LocalParticipant
    
    init(
        accessTokenStore: TwilioAccessTokenStoreReading,
        connectOptionsFactory: ConnectOptionsFactory,
        localParticipant: LocalParticipant
    ) {
        self.accessTokenStore = accessTokenStore
        self.connectOptionsFactory = connectOptionsFactory
        self.localParticipant = localParticipant
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
                let room = TwilioVideoSDK.connect(options: options, delegate: self)
                self.room = Room(room: room, localParticipant: self.localParticipant)
            case let .failure(error):
                self.delegate?.didFailToConnect(error: error)
            }
        }
    }
}

extension RoomStore: TwilioVideo.RoomDelegate {
    func roomDidConnect(room: TwilioVideo.Room) {
        self.room?.roomDidConnect(room: room)
        delegate?.didConnect()
    }
    
    func roomDidFailToConnect(room: TwilioVideo.Room, error: Error) {
        self.room?.roomDidFailToConnect(room: room, error: error)
        self.room = nil
        delegate?.didFailToConnect(error: error)
    }
    
    func roomDidDisconnect(room: TwilioVideo.Room, error: Error?) {
        self.room?.roomDidDisconnect(room: room, error: error)
        self.room = nil
        delegate?.didDisconnect(error: error)
    }
    
    func participantDidConnect(room: TwilioVideo.Room, participant: TwilioVideo.RemoteParticipant) {
        self.room?.participantDidConnect(room: room, participant: participant)
    }
    
    func participantDidDisconnect(room: TwilioVideo.Room, participant: TwilioVideo.RemoteParticipant) {
        self.room?.participantDidDisconnect(room: room, participant: participant)
    }
    
    func roomDidStartRecording(room: TwilioVideo.Room) {
        self.room?.roomDidStartRecording(room: room)
    }
    
    func roomDidStopRecording(room: TwilioVideo.Room) {
        self.room?.roomDidStopRecording(room: room)
    }
    
    func dominantSpeakerDidChange(room: TwilioVideo.Room, participant: TwilioVideo.RemoteParticipant?) {
        self.room?.dominantSpeakerDidChange(room: room, participant: participant)
    }
}
