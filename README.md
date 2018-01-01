# ChildPhotoSensor

Child pornography photo detector written for iOS with CoreML. Child Photo Sensor is an iOS project written in Swift that checks if an uploaded image is child pornography using Vision and CoreML. All images that do not contain faces are automatically determined as safe(does not contain child pornography).

## Getting Started

Fork this GitHub project for a sample project that can be used for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

Please make sure you have installed XCode 9 or above and your testing device is running iOS 11.0+.

## Deployment

1. Copy the ChildPhotoSensor.swift file and all models in the CoreML folder found in this repository into your project.

2. Construct a ChildPhotoSensor object with the uploaded image:
```
let photoSensor = ChildPhotoSensor(image: pickedImage)
```
3. Check if the photo is safe(does not contain child pornography):
```
let safe  = photoSensor.safe!
```
## Built With

* [Nudity](https://drive.google.com/file/d/0B5TjkH3njRqncDJpdDB1Tkl2S2s/vie) - The CoreML model used to check nudity in images.
* [AgeNet](https://drive.google.com/file/d/0B1ghKa_MYL6mT1J3T1BEeWx4TWc/view) - The CoreML model used to check a subject's age.

## Known Issues
* Questionable accuracy of AgeNet - will be replaced soon with specific CoreML model for detecting images of minors

## Authors

* **Ari Sokolov** - *Initial work*

## License

This project is licensed under the MIT License.

## Disclaimer
This project has not been tested with actual pornographic images of children.
