//
//  Copyright (C) 2019 Twilio, Inc.
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

#import "RoomViewControllerOld.h"
#import "LocalMediaController.h"
#import "VariableAlphaToggleButton.h"
#import "RoundButton.h"
#import "StatsViewController.h"
#import "StatsUIModel.h"
#import "VideoCollectionViewCell.h"
#import "RemoteParticipantUIModel.h"

@import TwilioVideo;

@interface RoomViewControllerOld () <LocalMediaControllerDelegate,
                                  TVIRoomDelegate,
                                  TVILocalParticipantDelegate,
                                  TVIRemoteParticipantDelegate,
                                  UICollectionViewDelegate,
                                  UICollectionViewDataSource>

@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) IBOutlet UILabel *mainLabel;
@property (nonatomic, weak) IBOutlet UILabel *joiningLabel;
@property (nonatomic, weak) IBOutlet UILabel *joiningRoomLabel;
@property (nonatomic, weak) IBOutlet UILabel *recordingWarningLabel;
@property (nonatomic, weak) IBOutlet UILabel *noVideoParticipantLabel;
@property (nonatomic, weak) IBOutlet UIImageView *noVideoImageView;
@property (nonatomic, weak) IBOutlet UICollectionView *videoCollectionView;
@property (nonatomic, weak) IBOutlet UIImageView *recordingIndicator;

@property (nonatomic, weak) IBOutlet UIView *remoteParticipantLabelView;
@property (nonatomic, weak) IBOutlet UILabel *remoteParticipantLabel;
@property (nonatomic, weak) IBOutlet UIImageView *remoteParticipantMutedStateImage;
@property (nonatomic, weak) IBOutlet UIImageView *remoteParticipantDominantSpeakerIndicatorImage;
@property (weak, nonatomic) IBOutlet UIImageView *remoteParticipantNetworkQualityIndicator;

@property (nonatomic, weak) IBOutlet VariableAlphaToggleButton *audioToggleButton;
@property (nonatomic, weak) IBOutlet VariableAlphaToggleButton *videoToggleButton;
@property (nonatomic, weak) IBOutlet RoundButton *hangupButton;
@property (nonatomic, weak) IBOutlet UIButton *flipCameraButton;
@property (nonatomic, weak) IBOutlet TVIVideoView *largeVideoView;

@property (nonatomic, weak) StatsViewController *statsViewController;

@end

@implementation RoomViewControllerOld

- (void)viewDidLoad {
    [super viewDidLoad];

    // Stats view controller
    self.statsViewController = (StatsViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"statsViewController"];
    [self.statsViewController addAsSwipeableViewToParentViewController:self];

    self.mainLabel.text = SwiftToObjc.userDisplayName;
    self.joiningRoomLabel.text = self.viewModel.roomName;

    self.remoteParticipantLabelView.layer.cornerRadius = self.remoteParticipantLabelView.bounds.size.width / 2.0;
    self.remoteParticipantLabelView.layer.backgroundColor = CGColorCreateCopyWithAlpha(self.remoteParticipantLabelView.layer.backgroundColor, 0.5);

    // Make sure the video and container views are still at the back of the stack... They're being... Difficult...
    [self.view sendSubviewToBack:self.containerView];
    [self.view sendSubviewToBack:self.largeVideoView];

    self.videoCollectionView.hidden = YES;
}

- (BOOL)isModalInPresentation {
    // Swiping to dismiss the RoomViewController does not disconnect from the Room. Press the disconnect button instead.
    return YES;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return self.viewModel.room.state == TVIRoomStateConnected;
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    [self.view setNeedsUpdateConstraints];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [UIApplication sharedApplication].idleTimerDisabled = YES;

    [self.viewModel.localMediaController addDelegate:self];

    self.audioToggleButton.selected = !self.viewModel.localMediaController.localAudioTrack;
    self.videoToggleButton.selected = !self.viewModel.localMediaController.localVideoTrack;
    self.flipCameraButton.enabled = (self.viewModel.localMediaController.localVideoTrack != nil);

    [self updateMainParticipant];
}

- (void)viewWillDisappear:(BOOL)animated {
    [UIApplication sharedApplication].idleTimerDisabled = NO;

    // I am not sure the best approach here yet... I wonder what will happen as we have other participant video showing on the main stage...
    [self.viewModel.localMediaController removeDelegate:self];

    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [self.viewModel.localMediaController.localVideoTrack removeRenderer:self.largeVideoView];

    [super viewDidDisappear:animated];
}

- (void)dismissViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)toggleAudioPressed:(id)sender {
    if (self.viewModel.localMediaController.localAudioTrack) {
        [self.viewModel.localMediaController destroyLocalAudioTrack];
        [self refreshLocalParticipantVideoView];
    } else {
        [self.viewModel.localMediaController createLocalAudioTrack];
    }

    self.audioToggleButton.selected = !self.viewModel.localMediaController.localAudioTrack;
}

- (IBAction)toggleVideoPressed:(id)sender {
    if (self.viewModel.localMediaController.localVideoTrack) {
        [self.viewModel.localMediaController destroyLocalVideoTrack];
        self.flipCameraButton.enabled = NO;
        [self refreshLocalParticipantVideoView];
    } else {
        [self.viewModel.localMediaController createLocalVideoTrack];
        self.flipCameraButton.enabled = YES;
    }

    self.videoToggleButton.selected = !self.viewModel.localMediaController.localVideoTrack;

    [self updateMainParticipant];
}

- (IBAction)hangupPressed:(id)sender {
    self.statsViewController.room = nil;

    if (self.viewModel.room) {
        [self.viewModel.room disconnect];
    } else {
        [self dismissViewController];
    }
}

- (IBAction)flipCameraPressed:(id)sender {
    [self.viewModel.localMediaController flipCamera];
}

- (void)refreshLocalParticipantVideoView {
    // Our local Participant is always first.
    [self.videoCollectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
}

- (void)refreshParticipantVideoViews:(TVIParticipant *)participant {
    NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray new];

    for (VideoCollectionViewCell *cell in self.videoCollectionView.visibleCells) {
        if ([cell.remoteParticipantUIModel.remoteParticipant isEqual:participant]) {
            NSIndexPath *indexPath = [self.videoCollectionView indexPathForCell:cell];

            if (indexPath) {
                [indexPaths addObject:indexPath];
            }
        }
    }

    if (indexPaths.count > 0) {
        [self.videoCollectionView reloadItemsAtIndexPaths:indexPaths];
    }
}

- (void)refreshVideoViews {
    [self.videoCollectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
}

- (void)updateVideoUIForSelectedParticipantUIModel:(RemoteParticipantUIModel *)selectedParticipantUIModel {
    RemoteParticipantUIModel *previouslySelectedParticipantUIModel = self.viewModel.selectedParticipantUIModel;

    if (previouslySelectedParticipantUIModel != selectedParticipantUIModel) {
        // Remove the big view from the previous participant's list of renderers
        if (previouslySelectedParticipantUIModel == nil) {
            [self.viewModel.localMediaController.localVideoTrack removeRenderer:self.largeVideoView];
        } else {
            [previouslySelectedParticipantUIModel.remoteVideoTrack removeRenderer:self.largeVideoView];
        }
    }

    self.viewModel.selectedParticipantUIModel = selectedParticipantUIModel;

    NSString *identity = nil;
    TVIVideoTrack *videoTrack = nil;

    BOOL shouldMirror = NO;

    if (selectedParticipantUIModel == nil) {
        // We selected the local participant
        identity = @"You";
        videoTrack = self.viewModel.localMediaController.localVideoTrack;
        shouldMirror = self.viewModel.localMediaController.shouldMirrorLocalVideoView;
    } else {
        identity = selectedParticipantUIModel.remoteParticipant.identity;
        videoTrack = selectedParticipantUIModel.remoteVideoTrack;
    }

    self.noVideoParticipantLabel.text = identity;

    BOOL videoEnabled = videoTrack.isEnabled;

    [videoTrack addRenderer:self.largeVideoView];

    self.largeVideoView.mirror = shouldMirror;
    self.largeVideoView.hidden = !videoEnabled;
    // Ensure that we can see local and remote camera / screen content.
    self.largeVideoView.contentMode = UIViewContentModeScaleAspectFit;
    self.noVideoParticipantLabel.hidden = videoEnabled;
    self.noVideoImageView.hidden = videoEnabled;

    [self updateRemoteParticipantView:self.viewModel.selectedParticipantUIModel.remoteParticipant];

    if (videoEnabled && self.viewModel.selectedParticipantUIModel != nil) {
        self.remoteParticipantLabelView.hidden = NO;
    } else {
        self.remoteParticipantLabelView.hidden = YES;
    }
}

- (void)updateRemoteParticipantView:(TVIParticipant *)participant {
    NSMutableString *initials = [NSMutableString new];
    NSArray *splitItems = [participant.identity componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    for (NSString *item in splitItems) {
        if ([item length] > 0) {
            [initials appendString:[[item substringToIndex:1] uppercaseString]];
        }

        if ([initials length] == 2) {
            break;
        }
    }

    self.remoteParticipantLabel.text = initials;

    if (self.viewModel.dominantSpeaker == participant) {
        self.remoteParticipantMutedStateImage.hidden = YES;
        self.remoteParticipantDominantSpeakerIndicatorImage.hidden = NO;
    } else {
        self.remoteParticipantMutedStateImage.hidden = NO;
        self.remoteParticipantDominantSpeakerIndicatorImage.hidden = YES;
        if ([participant.audioTracks firstObject].track.isEnabled) {
            self.remoteParticipantMutedStateImage.image = [UIImage imageNamed:@"audio-unmuted-white"];
        } else {
            self.remoteParticipantMutedStateImage.image = [UIImage imageNamed:@"audio-muted-white"];
        }
    }

    self.remoteParticipantNetworkQualityIndicator.image = [NetworkQualityIndicator networkQualityIndicatorImageForLevel:participant.networkQualityLevel];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.viewModel togglePinAt:indexPath.row];

    for (VideoCollectionViewCell *cell in collectionView.visibleCells) {
        cell.isPinned = self.viewModel.pinnedParticipant == [cell getParticipant];
    }

    [self updateMainParticipant]; // Have view model trigger this with delegate
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.viewModel.remoteParticipantUIModels.count + 1;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    VideoCollectionViewCell *cell = (VideoCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"videoCell" forIndexPath:indexPath];

    if (indexPath.row == 0) {
        // 0th element is always the local participant
        [cell setLocalParticipant:self.viewModel.room.localParticipant isCurrentlySelected:(self.viewModel.selectedParticipantUIModel == nil)];
    } else {
        RemoteParticipantUIModel *remoteParticipantUIModel = self.viewModel.remoteParticipantUIModels[indexPath.row - 1];
        [cell setRemoteParticipantUIModel:remoteParticipantUIModel isDominantSpeaker:(remoteParticipantUIModel.remoteParticipant == self.viewModel.dominantSpeaker)];
    }

    return cell;
}

#pragma mark - LocalMediaControllerDelegate

- (void)localMediaControllerStartedVideoCapture:(LocalMediaController *)localMediaController {
    if (self.viewModel.selectedParticipantUIModel == nil) {
        [self updateVideoUIForSelectedParticipantUIModel:nil];
    }

    [self refreshLocalParticipantVideoView];
}

@end
