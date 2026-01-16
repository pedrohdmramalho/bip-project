import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_ad.dart';

class ProjectAdsRemoteDataSource {
  final FirebaseFirestore firestore;

  ProjectAdsRemoteDataSource(this.firestore);

  Future<void> createAd(ProjectAd ad) async {
    await firestore.collection('project_ads').doc(ad.id).set(ad.toMap());
  }
}
