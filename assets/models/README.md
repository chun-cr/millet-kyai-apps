Place MediaPipe model files for mobile packaging here.

Required for iOS native face scan:
- face_landmarker.task

This directory is included by Flutter asset packaging. The iOS native loader
looks for the model at:
- flutter_assets/assets/models/face_landmarker.task

After adding the model file, run:
- flutter pub get
- rebuild the iOS app in Xcode or with flutter run
