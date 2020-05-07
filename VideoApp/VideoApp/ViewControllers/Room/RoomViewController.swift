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

import UIKit

class RoomViewController: UIViewController {
    @IBOutlet weak var disableMicButton: CircleToggleButton!
    @IBOutlet weak var disableCameraButton:  CircleToggleButton!
    @IBOutlet weak var leaveButton: UIButton!
    @IBOutlet weak var switchCameraButton: UIButton!
    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var participantCollectionView: UICollectionView!
    @IBOutlet weak var mainVideoView: MainVideoView!
    var viewModel: RoomViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        roomNameLabel.text = viewModel.data.roomName
        participantCollectionView.dataSource = self
        participantCollectionView.delegate = self
        disableMicButton.isSelected = !viewModel.isMicOn
        disableCameraButton.isSelected = !viewModel.isCameraOn

        disableMicButton.didToggle = { self.viewModel.isMicOn = !$0 }
        disableCameraButton.didToggle = { self.viewModel.isCameraOn = !$0 }

        participantCollectionView.register(
            UINib(nibName: "ParticipantCell", bundle: nil),
            forCellWithReuseIdentifier: "ParticipantCell"
        )
        
        viewModel.delegate = self
        viewModel.connect()

        let participant = viewModel.data.mainParticipant
        mainVideoView.configure(identity: participant.identity, videoConfig: participant.videoConfig)
    }
    
    @IBAction func leaveButtonTapped(_ sender: Any) {
        viewModel.disconnect()
    }
    
    @IBAction func switchCameraButtonTapped(_ sender: Any) {
        viewModel.cameraPosition = viewModel.cameraPosition == .front ? .back : .front // TODO: Improve with toggle button
    }
}

extension RoomViewController: RoomViewModelDelegate {
    func didConnect() {
        roomNameLabel.text = viewModel.data.roomName
    }
    
    func didFailToConnect(error: Error) {
        showError(error: error) { [weak self] in self?.navigationController?.popViewController(animated: true) }
    }
    
    func didDisconnect(error: Error?) {
        guard let error = error else {
            navigationController?.popViewController(animated: true)
            return
        }
        
        showError(error: error) { [weak self] in self?.navigationController?.popViewController(animated: true) }
    }
    
    // TODO: Rename to indices?
    func didAddParticipants(at indexes: [Int]) {
        participantCollectionView.insertItems(at: indexes.map { IndexPath(item: $0, section: 0) })
    }
    
    func didRemoveParticipants(at indices: [Int]) {
        participantCollectionView.deleteItems(at: indices.map { IndexPath(item: $0, section: 0) }) // Maybe make Int to Index path extension
    }

    func didMoveParticipant(at index: Int, to newIndex: Int) {
        participantCollectionView.moveItem(at: IndexPath(item: index, section: 0), to: IndexPath(item: newIndex, section: 0))
    }

    func didUpdateParticipantAttributes(at index: Int) {
        guard let cell = participantCollectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? ParticipantCell else { return }
        
        let participant = viewModel.data.participants[index]
        cell.configure(identity: participant.identity, status: participant.status, videoConfig: participant.videoConfig)
    }
    
    func didUpdateMainParticipant() {
        let participant = viewModel.data.mainParticipant
        mainVideoView.configure(identity: participant.identity, videoConfig: participant.videoConfig)
    }
}

extension RoomViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.data.participants.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ParticipantCell", for: indexPath) as! ParticipantCell

        let participant = viewModel.data.participants[indexPath.item]
        cell.configure(identity: participant.identity, status: participant.status, videoConfig: participant.videoConfig)
        
        return cell
    }
}

extension RoomViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.togglePin(at: indexPath.item)
    }
}
