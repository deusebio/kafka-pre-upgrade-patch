#!/bin/bash


mkdir -p /var/snap/charmed-zookeeper/common/var/lib/zookeeper-2/data-log
cp -r /var/snap/charmed-zookeeper/common/var/log/zookeeper/version-2 /var/snap/charmed-zookeeper/common/var/lib/zookeeper-2/data-log/version-2

mkdir -p /var/snap/charmed-zookeeper/common/var/lib/zookeeper-2/data
cp -r /var/snap/charmed-zookeeper/common/var/lib/zookeeper/version-2 /var/snap/charmed-zookeeper/common/var/lib/zookeeper-2/data/version-2
cp /var/snap/charmed-zookeeper/common/var/lib/zookeeper/myid /var/snap/charmed-zookeeper/common/var/lib/zookeeper-2/data/myid

