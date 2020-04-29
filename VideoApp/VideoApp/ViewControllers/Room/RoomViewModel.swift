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

struct RoomViewModelData {
    let roomName: String
    let mainVideo: String
    let participants: [String]
}

protocol RoomViewModelDelegate: AnyObject {
    func didUpdateData()
}

class RoomViewModel {
    weak var delegate: RoomViewModelDelegate?
    private let roomName: String
    private let roomStore: RoomStore

    init(roomName: String, roomStore: RoomStore) {
        self.roomName = roomName
        self.roomStore = roomStore
        roomStore.delegate = self
    }
    
    func connect() {
        roomStore.connect(roomName: roomName)
    }
}

extension RoomViewModel: RoomStoreDelegate {
    func didConnect() {
        delegate?.didUpdateData()
    }
    
    func didFailToConnect(error: Error) {
        
    }
    
    func didDisconnect(error: Error?) {
        delegate?.didUpdateData()
    }
}
