blkzone report /dev/nullb0 | awk '{print $11" "$12}'
blkzone open /dev/nullb0 
blkzone report /dev/nullb0 | awk '{print $11" "$12}'
blkzone close /dev/nullb0 
blkzone report /dev/nullb0 | awk '{print $11" "$12}'
blkzone finish /dev/nullb0 
blkzone report /dev/nullb0 | awk '{print $11" "$12}'
