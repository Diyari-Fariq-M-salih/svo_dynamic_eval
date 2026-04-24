## scripts.sh were created to streamline the testing process
- use the scripts with docker and roscore active
- any new scripts need to be made executable, via chmod +x "script path"

### current list of scripts for testing:
#### RGB_bonn data
- run_bonn_svo_batch_no_align.sh 
- run_bonn_svo_batch.sh 

#### Vicon_room data
room 1 script includes GT conversion to TUM should it not be available
- run_euroc_vicon_room1_no_align.sh
- run_euroc_vicon_room1.sh
- run_euroc_vicon_room2_no_align.sh
- run_euroc_vicon_room2.sh

####