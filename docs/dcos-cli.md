# DCOS CLI

The [dcos-cli](https://github.com/mesosphere/dcos-cli) is used to install DCOS services and marathon apps from package repositories.

## Universe

The dcos-cli by default uses the [Mesosphere Universe package repository](https://github.com/mesosphere/universe).

## Multiverse

The dcos-cli can also use additional universe-like package repositories. The primary one is the [Mesosphere Multiverse package repository](https://github.com/mesosphere/multiverse).

In [dcos-cli 0.4.0](https://github.com/mesosphere/dcos-cli/releases/tag/0.4.0) (DCOS 1.6.1), how to add remote repositories changed. Follow the instructions appropriate to the version you have installed.

- DCOS >= 1.6.1 (>= dcos-cli 0.4.0, universe schema 2.x)

    ```
    dcos package repo add multiverse https://github.com/mesosphere/multiverse/archive/version-2.x.zip
    ```
- DCOS <= 1.6.0 (<= dcos-cli 0.3.x, universe schema 1.x)

    ```
    dcos config prepend package.sources https://github.com/mesosphere/multiverse/archive/version-1.x.zip
    dcos package update --validate
    ```
