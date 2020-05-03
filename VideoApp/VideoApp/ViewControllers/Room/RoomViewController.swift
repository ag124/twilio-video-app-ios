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
    @IBOutlet weak var disableMicButton: VariableAlphaToggleButton!
    @IBOutlet weak var disableCameraButton: VariableAlphaToggleButton!
    @IBOutlet weak var leaveButton: RoundButton!
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
        
        viewModel.delegate = self
        viewModel.connect()

        configureMainVideoView()
    }
    
    @IBAction func disableCameraButtonTapped(_ sender: Any) {
        disableCameraButton.isSelected = !disableCameraButton.isSelected
        viewModel.isCameraOn = !disableCameraButton.isSelected
    }
    
    @IBAction func disableMicButtonTapped(_ sender: Any) {
        disableMicButton.isSelected = !disableMicButton.isSelected // TODO: Move to button
        viewModel.isMicOn = !disableMicButton.isSelected
    }
    
    @IBAction func leaveButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func switchCameraButtonTapped(_ sender: Any) {
        viewModel.flipCamera()
    }
    
    func configureMainVideoView() {
        let participant = viewModel.data.mainParticipant
        mainVideoView.configure(identity: participant.identity)
        mainVideoView.configure(videoConfig: participant.videoConfig)
    }
}

extension RoomViewController: RoomViewModelDelegate {
    func didUpdateData() {

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
        cell.configure(identity: participant.identity, status: participant.status)
    }
    
    func didUpdateParticipantVideoConfig(at index: Int) {
        // TDOO: Make more DRY
        guard let cell = participantCollectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? ParticipantCell else { return }

        let participant = viewModel.data.participants[index]
        cell.configure(videoConfig: participant.videoConfig)
    }
    
    func didUpdateMainParticipant() {
        configureMainVideoView()
    }
    
    func didUpdateMainParticipantVideoConfig() {
        mainVideoView.configure(videoConfig: viewModel.data.mainParticipant.videoConfig)
    }
}

extension RoomViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.data.participants.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ParticipantCell", for: indexPath) as! ParticipantCell

        let participant = viewModel.data.participants[indexPath.item]
        cell.configure(identity: participant.identity, status: participant.status)
        cell.configure(videoConfig: participant.videoConfig)
        
        return cell
    }
}

extension RoomViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.togglePin(at: indexPath.item)
    }
}
