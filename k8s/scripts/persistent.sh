#! /bin/bash -x

for node in $@; do
  # For each node, create a pool of small and medium volumes
  vols=$(seq -f pv-$POOL_SIZE_SMALL-%04g 1 $POOL_NUM_SMALL)
  for vol in $vols; do
    NAME=$(echo $node | cut -d . -f 1)-${vol,,} \
      VOLUME_ROOT=$K8S_VOLUMES_PATH/pool-s/$vol VOLUME_ID=$(uuidgen | cut -d - -f 1) \
      VOLUME_SIZE=$POOL_SIZE_SMALL NODENAME=$node GROUP=pool-s \
      make install/persistent-item
  done
  vols=$(seq -f pv-$POOL_SIZE_MEDIUM-%04g 1 $POOL_NUM_MEDIUM)
  for vol in $vols; do
    NAME=$(echo $node | cut -d . -f 1)-${vol,,} \
      VOLUME_ROOT=$K8S_VOLUMES_PATH/pool-m/$vol VOLUME_ID=$(uuidgen | cut -d - -f 1) \
      VOLUME_SIZE=$POOL_SIZE_MEDIUM NODENAME=$node GROUP=pool-m \
      make install/persistent-item
  done

  # Create the named entries: admin, backup, share plus local volumes
  for vol in $NAMED_VOLUMES; do
    ID=$(uuidgen | cut -d - -f 1)
    NAME=$(echo $node | cut -d. -f 1)-$vol
    NAME=$NAME VOLUME_ROOT=$K8S_VOLUMES_PATH/$vol VOLUME_ID=$ID \
      VOLUME_SIZE=$POOL_SIZE_LARGE NODENAME=$node GROUP=$vol \
      make install/persistent-item
  done
done
