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

protocol MainParticipantStoreDelegate: AnyObject {
    func didUpdateMainParticipant()
    func didUpdateStatus()
}

class MainParticipantStore {
    weak var delegate: MainParticipantStoreDelegate?
    var pinnedParticipant: Participant? { // TODO: Maybe move this to list
        didSet { updateMainParticipant() }
    }
    private(set) var mainParticipant: Participant!
    private let room: Room
    private let participantList: ParticipantList
    private let notificationCenter = NotificationCenter.default
    
    init(room: Room, participantList: ParticipantList) {
        self.room = room
        self.participantList = participantList
        updateMainParticipant()
        notificationCenter.addObserver(self, selector: #selector(roomDidChange(_:)), name: .roomDidChange, object: nil)
        notificationCenter.addObserver(self, selector: #selector(participantDidChange(_:)), name: .participantDidChange, object: nil)
    }

    @objc func roomDidChange(_ notification:Notification) {
        guard let change = notification.userInfo?["key"] as? RoomChange else { return }
        
        switch change {
        case .didConnect, .didFailToConnect, .didDisconnect:
            break
        case .dominantSpeakerDidChange, .didAddRemoteParticipants, .didRemoveRemoteParticipants:
            updateMainParticipant()
        }
    }
    
    @objc func participantDidChange(_ notification:Notification) {
        guard let change = notification.userInfo?["key"] as? ParticipantUpdate else { return }
        
        switch change {
        case let .didUpdateAttributes(participant), let .didUpdateVideoConfig(participant, _):
            if !updateMainParticipant() && participant.identity == mainParticipant.identity {
                delegate?.didUpdateStatus()
            }
        }
    }
    
    @discardableResult private func updateMainParticipant() -> Bool {
        let new =
            pinnedParticipant ??
            room.remoteParticipants.screenPresenter ??
            room.dominantSpeaker ??
            participantList.firstRemoteParticipant ??
            room.localParticipant

        if new.identity != mainParticipant.identity {
            mainParticipant = new
            delegate?.didUpdateMainParticipant()
            return true
        } else {
            return false
        }
    }
}

extension Array where Element == RemoteParticipant {
    var screenPresenter: Participant? { first(where: { $0.screenVideoTrack != nil }) }
}

private extension ParticipantList {
    var firstRemoteParticipant: Participant? { participants.first(where: { $0.isRemote })}
}
