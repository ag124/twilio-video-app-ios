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
    @IBOutlet weak var mainVideoView: VideoView! // TODO: Abstract?
    @IBOutlet weak var participantCollectionView: UICollectionView!
    
    var viewModel: RoomViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        roomNameLabel.text = viewModel.data.roomName
        participantCollectionView.dataSource = self
        participantCollectionView.delegate = self
        disableMicButton.isSelected = !viewModel.isMicOn
        
        viewModel.delegate = self
        viewModel.connect()
    }
    
    @IBAction func disableCameraButtonTapped(_ sender: Any) {
        print("Disable camera tapped.")
    }
    
    @IBAction func disableMicButtonTapped(_ sender: Any) {
        disableMicButton.isSelected = !disableMicButton.isSelected // TODO: Move to button
        viewModel.isMicOn = !disableMicButton.isSelected
    }
    
    @IBAction func leaveButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func switchCameraButtonTapped(_ sender: Any) {
        
    }
}

extension RoomViewController: RoomViewModelDelegate {
    func didUpdateData() {

    }
    
    // TODO: Rename to indices?
    func didAddParticipants(at indexes: [Int]) {
        participantCollectionView.insertItems(at: indexes.map { IndexPath(item: $0, section: 0) })
    }
    
    func didRemoveParticipant(at index: Int) {
        participantCollectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
    }

    func didUpdateParticipantAttributes(at index: Int) {
        guard let cell = participantCollectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? ParticipantCell else { return }
        
        let participant = viewModel.data.participants[index]
        cell.configure(status: .init(identity: participant.identity, isMicMuted: !participant.isMicOn))
    }
    
    func didUpdateParticipantVideoConfig(at index: Int) {
        // TDOO: Make more DRY
        guard let cell = participantCollectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? ParticipantCell else { return }

        let participant = viewModel.data.participants[index]
        cell.configure(videoTrack: participant.cameraVideoTrack, shouldMirror: participant.shouldMirrorVideo)
    }
}

extension RoomViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.data.participants.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ParticipantCell", for: indexPath) as! ParticipantCell

        let participant = viewModel.data.participants[indexPath.item]
        cell.configure(status: .init(identity: participant.identity, isMicMuted: !participant.isMicOn))
        cell.configure(videoTrack: participant.cameraVideoTrack, shouldMirror: participant.shouldMirrorVideo)
        
        return cell
    }
}

extension RoomViewController: UICollectionViewDelegate {
    
}
