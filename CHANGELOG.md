# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), 
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Added an automated testing script which will test the core components of the chaos-monkey [@buehlmannpa](https://github.com/buehlmannpa).
- Added code into the backup script to create a backup from the existing logfile [@buehlmannpa](https://github.com/buehlmannpa).
- Added an empty Readme where the repository will be described [@buehlmannpa](https://github.com/buehlmannpa).
- Added functionality to eliminate pods and log to a defined logfile [@buehlmannpa](https://github.com/buehlmannpa).
- Added the functions to read and interact with the config inputs [@buehlmannpa](https://github.com/buehlmannpa).

### Changed
- Changed the mechanism to prof if the pod is younger than an hour [@buehlmannpa](https://github.com/buehlmannpa).
- Changed the code where deleting the namespaces defined in the config-file from the namespaces on the k8s cluster [@buehlmannpa](https://github.com/buehlmannpa).

### Deleted
- Unused and unnecessary comments deleted [@buehlmannpa](https://github.com/buehlmannpa).
 