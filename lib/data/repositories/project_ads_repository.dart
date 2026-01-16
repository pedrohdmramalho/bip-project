import 'package:starteu/data/datasource/project_ads_remote_ds.dart';
import '../models/project_ad.dart';

class ProjectAdsRepository {
  final ProjectAdsRemoteDataSource remote;
  ProjectAdsRepository(this.remote);
  Future<void> createAd(ProjectAd ad) => remote.createAd(ad);
}
