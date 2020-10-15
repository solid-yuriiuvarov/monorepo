# Configurations

## TL;DR
Adding a new source, or a new destination requires adding new configurations that stores the necessary source or destination-related data, such as access tokens keys, project names, workflow identifiers, etc. The purpose of this document is to describe how to add new configurations. 

## Scope
This document describes the process of adding new configurations.

## Non-scope
Details of adding new integrations are out of scope of this document.

## References
* [Github Actions source Configuration Template](https://github.com/platform-platform/monorepo/tree/master/metrics/ci_integrations/docs/source/github_actions/config/github_actions_source.yaml)
* [Jenkins Source Configuration Template](https://github.com/platform-platform/monorepo/tree/master/metrics/ci_integrations/docs/source/jenkins/config/jenkins_source.yaml)
* [Firestore Destination Configuration Template](https://github.com/platform-platform/monorepo/tree/master/metrics/ci_integrations/docs/destination/firestore/config/firestore_destination.yaml)

## Adding new configuration
To add a new configuration, copy one of the given templates and fill all its necessary parameters.

## Usage
You can use the newly created configuration using the sync command. 
To use the newly created config, use the `--config-file=` flag and specify the path to the configuration file.