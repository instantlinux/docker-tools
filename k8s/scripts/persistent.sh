#! /bin/bash -x
for node in $@; do
  vols=$(seq -f pv-$VOL_SIZE_SMALL-%04g 1 $VOL_NUM_SMALL)
  for vol in $vols; do
    NAME=$(echo $node | cut -d. -f 1)-${vol,,} VOLUME_NAME=$vol \
      VOLUME_SIZE=$VOL_SIZE_SMALL NODENAME=$node make install/persistent-volumes
  done
  vols=$(seq -f pv-$VOL_SIZE_MEDIUM-%04g 1 $VOL_NUM_MEDIUM)
  for vol in $vols; do
    NAME=$(echo $node | cut -d. -f 1)-${vol,,} VOLUME_NAME=$vol \
      VOLUME_SIZE=$VOL_SIZE_MEDIUM NODENAME=$node make install/persistent-volumes
  done
done
