# In place upgrade

This repository is to contain the instructions as well as the test cases to migrate the SF deployment from its current revisions to the latest ones.

## Test cases

The `test-bundles` folder contains some bundle to deploy some environment where to test the upgrade. In particular we provide:

1. A simple TLS-encrypted Zookeeper deployment
2. A full TLS-encrypted Kafka deployment with also client applications to mimic upgrade while having traffic. The deployment contains both a data-integrator, a producer and a consumer. These applications are ready to be related to the Kafka cluster. However, server-client applications have not been created yet, such that different scenario can be tested. 

## Process

The process has been tested both on Juju 2.9.45, Juju 2.9.46 and Juju 3.1.6.

The process involved upgrading both Kafka and Zookeeper. The order should not matter given the cross-compatiility of versions between Kafka and Zookeeper. 

Both upgrades (Kafka and Zookeeper) make use of a *preparatory* revision can make sure that the charm state is patched with the necessary modification to make the use of the proper in-place upgrade feature possible. These charm revisions are provided in the `charms` folder, and are named `kafka_ubuntu-22.04-amd64.charm` and `zookeeper_ubuntu-22.04-amd64.charm`.

While doing the tests, we have also found some small tuning that contributes to make the upgrade process more robust and reliable. Therefore, for the upgrade process to best work (even under limited load), we recommend to bump, after the preparatory charm upgrade, to revision 146+ for Kafka and 112+ for Zookeeper.

For convenience, in the next table we provide a description of the charm files in the `charms` folder and their code-version counterparts:

| File                                     | Link                                                                |
|------------------------------------------|---------------------------------------------------------------------|
| kafka_ubuntu-22.04-amd64.charm           | https://github.com/deusebio/kafka-operator/tree/test-sf-upgrade     |
| zookeeper_ubuntu-22.04-amd64.charm       | https://github.com/deusebio/zookeeper-operator/tree/test-sf-upgrade |

### Upgrade Zookeeper

Unfortunately the deployment currently used by SF is not using external-storage for storing the Zk data. In fact, external storage was added at rev101, that has already slightly refactored the position of the dataDir and dataLogDir into two different folders.

The upgrade process therefore needs to re-organize the content correctly while upgrading. This can create some sync problem if the Zk cluster were to be updated under load, that is NOT supported and in general advised against.

#### Steps

1. Copy some utilities bash scripts into the different Zookeeper units. For each unit, issue the following command

```
juju scp -- -r bin zookeeper/<unit>:. 
```

Substitute the unit number with each Zk unit.


2. Backup the Zk data into a separate directory using the utilities bash script that was uploaded to the units

```
juju exec --application zookeeper -- source /home/ubuntu/bin/copy-files.sh
```

3. Upgrade the charm using the *preparatory* charm provided in the `charms` folder

```
juju refresh zookeeper --path ./charms/zookeeper_ubuntu-22.04-amd64.charm
```

4. After the Zookeeper units have setteld down into active/idle states, we can now start the usual process for upgrading the charm by running the pre-upgrade-check action

```
juju run-action zookeeper/leader pre-upgrade-check --wait
```

5. Once the action has been successfully run, we can now start the upgrade to the latest revision on a given relevant channel

```
juju refresh zookeeper --switch ch:zookeeper --channel 3/edge
```

(make sure you are upgrading to a 112+ revision)

6. Once all the units have upgraded, check that the Zookeeper servers are now running the new version by using

```
echo srvr | nc <IP_ADDRESS> 2181
```


### Upgrade Kafka

The upgrade of the Kafka cluster is considerably easier since there is no need to patch for the storage. The *preparatory* revision is nevertheless needed to prepare the upgrade peer-relation databag to be compliant with the one expected by the in-place upgrade functionality. 


#### Steps

1. Upgrade the charm using the *preparatory* charm provided in the `charms` folder

```
juju refresh kafka --path ./charms/kafka_ubuntu-22.04-amd64.charm
```

2. After the Kafka units have setteld down into active/idle states, we can now start the usual process for upgrading the charm by running the pre-upgrade-check action

```
juju run-action kafka/leader pre-upgrade-check --wait
```

3. Once the action has been successfully run, we can now start the upgrade to the latest revision on a given relevant channel

```
juju refresh kafka --switch ch:kafka --channel 3/edge
```

(make sure you are upgrading to a 146+ revision)

4. Once all the units have upgraded, check that the Kafka servers are now running the new version by using

```
juju ssh kafka/0 sudo -i 'charmed-kafka.configs --bootstrap-server <BOOTSTRAP_SERVERS> --version'
```

Where `<BOOTSTRAP_SERVERS>` can be found using

```
juju exec --unit kafka/0 sudo cat /var/snap/charmed-kafka/current/etc/kafka/client.properties | grep bootstrap.servers | cut -d "=" -f2
```





