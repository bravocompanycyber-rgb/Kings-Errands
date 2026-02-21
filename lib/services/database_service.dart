import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_models.dart';
import 'dart:math';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Generic collection references with converters
  CollectionReference<AppUser> get usersRef =>
      _db.collection('users').withConverter<AppUser>(
            fromFirestore: AppUser.fromFirestore,
            toFirestore: (user, _) => user.toFirestore(),
          );

  CollectionReference<Wallet> get walletsRef =>
      _db.collection('wallets').withConverter<Wallet>(
            fromFirestore: Wallet.fromFirestore,
            toFirestore: (wallet, _) => wallet.toFirestore(),
          );

  CollectionReference<Errand> get errandsRef =>
      _db.collection('errands').withConverter<Errand>(
            fromFirestore: Errand.fromFirestore,
            toFirestore: (errand, _) => errand.toFirestore(),
          );

  CollectionReference<LocationRate> get locationRatesRef =>
      _db.collection('location_rates').withConverter<LocationRate>(
            fromFirestore: LocationRate.fromFirestore,
            toFirestore: (rate, _) => rate.toFirestore(),
          );

  CollectionReference<ServiceRate> get serviceRatesRef =>
      _db.collection('service_rates').withConverter<ServiceRate>(
            fromFirestore: ServiceRate.fromFirestore,
            toFirestore: (rate, _) => rate.toFirestore(),
          );

  CollectionReference<PricingAddon> get pricingAddonsRef =>
      _db.collection('pricing_addons').withConverter<PricingAddon>(
            fromFirestore: PricingAddon.fromFirestore,
            toFirestore: (addon, _) => addon.toFirestore(),
          );

  CollectionReference<AuditLog> get auditLogsRef =>
      _db.collection('audit_logs').withConverter<AuditLog>(
            fromFirestore: AuditLog.fromFirestore,
            toFirestore: (log, _) => log.toFirestore(),
          );

  CollectionReference<AppTransaction> get transactionsRef =>
      _db.collection('transactions').withConverter<AppTransaction>(
            fromFirestore: AppTransaction.fromFirestore,
            toFirestore: (tx, _) => tx.toFirestore(),
          );

  CollectionReference<NotificationModel> get notificationsRef =>
      _db.collection('notifications').withConverter<NotificationModel>(
            fromFirestore: NotificationModel.fromFirestore,
            toFirestore: (n, _) => n.toFirestore(),
          );

  CollectionReference<RunnerStatus> get runnerStatusRef =>
      _db.collection('runner_status').withConverter<RunnerStatus>(
            fromFirestore: RunnerStatus.fromFirestore,
            toFirestore: (rs, _) => rs.toFirestore(),
          );

  CollectionReference<Review> get reviewsRef =>
      _db.collection('reviews').withConverter<Review>(
            fromFirestore: Review.fromFirestore,
            toFirestore: (r, _) => r.toFirestore(),
          );

  CollectionReference<FAQ> get faqsRef =>
      _db.collection('faq').withConverter<FAQ>(
            fromFirestore: FAQ.fromFirestore,
            toFirestore: (faq, _) => faq.toFirestore(),
          );

  CollectionReference<Statistics> get statisticsRef =>
      _db.collection('statistics').withConverter<Statistics>(
            fromFirestore: Statistics.fromFirestore,
            toFirestore: (s, _) => s.toFirestore(),
          );

  // For backward compatibility in some screens
  CollectionReference<PromoCode> get promoCodesRef =>
      _db.collection('pricing_addons').withConverter<PromoCode>(
            fromFirestore: PromoCode.fromFirestore,
            toFirestore: (pc, _) => pc.toFirestore(),
          );

  CollectionReference<Map<String, dynamic>> collection(String name) => _db.collection(name);

  // Helper functions
  Future<void> logAction(String errandId, String action, {String adminId = '', String details = ''}) async {
    await auditLogsRef.add(AuditLog(
      id: '',
      errandId: errandId,
      adminId: adminId,
      action: action,
      timestamp: DateTime.now(),
      details: details,
    ));
  }

  String _generateVerificationCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<void> postErrand({
    required String customerId,
    required String title,
    required String description,
    required String pickupLocation,
    required String deliveryLocation,
    required double estimatedPrice,
    String? stopOverLocation,
    String? alternativeContact,
    bool hasStopOver = false,
    bool isBulky = false,
    String? promoCodeUsed,
    DateTime? scheduledAt,
    String paymentType = 'pay_later',
    String? mpesaCode,
  }) async {
    final vCode = _generateVerificationCode();
    final newErrand = Errand(
      id: '',
      customerId: customerId,
      status: paymentType == 'pay_now' ? 'awaiting_payment' : 'broadcasted',
      pickupLocation: pickupLocation,
      deliveryLocation: deliveryLocation,
      estimatedPrice: estimatedPrice,
      createdAt: DateTime.now(),
      title: title,
      description: description,
      stopOverLocation: stopOverLocation,
      alternativeContact: alternativeContact,
      hasStopOver: hasStopOver,
      isBulky: hasStopOver, // logic was slightly mixed up in previous model, ensuring consistency
      promoCodeUsed: promoCodeUsed,
      scheduledAt: scheduledAt,
      paymentType: paymentType,
      isPaymentApproved: paymentType == 'pay_later',
      mpesaCode: mpesaCode,
      verificationCode: vCode,
    );

    final docRef = await errandsRef.add(newErrand);
    await logAction(docRef.id, 'Errand created. Verification Code: $vCode');
  }

  Future<String> postErrandReturnId({
    required String customerId,
    required String title,
    required String description,
    required String pickupLocation,
    required String deliveryLocation,
    required double estimatedPrice,
    String? stopOverLocation,
    String? alternativeContact,
    bool hasStopOver = false,
    bool isBulky = false,
    String? promoCodeUsed,
    DateTime? scheduledAt,
    String paymentType = 'pay_later',
    String? mpesaCode,
  }) async {
    final vCode = _generateVerificationCode();
    final newErrand = Errand(
      id: '',
      customerId: customerId,
      status: paymentType == 'pay_now' ? 'awaiting_payment' : 'broadcasted',
      pickupLocation: pickupLocation,
      deliveryLocation: deliveryLocation,
      estimatedPrice: estimatedPrice,
      createdAt: DateTime.now(),
      title: title,
      description: description,
      stopOverLocation: stopOverLocation,
      alternativeContact: alternativeContact,
      hasStopOver: hasStopOver,
      isBulky: isBulky,
      promoCodeUsed: promoCodeUsed,
      scheduledAt: scheduledAt,
      paymentType: paymentType,
      isPaymentApproved: paymentType == 'pay_later',
      mpesaCode: mpesaCode,
      verificationCode: vCode,
    );

    final docRef = await errandsRef.add(newErrand);
    await logAction(docRef.id, 'Errand created. Verification Code: $vCode');
    return docRef.id;
  }

  Future<void> approvePayment(String errandId, String mpesaCode, String adminId) async {
    final errandDoc = await errandsRef.doc(errandId).get();
    final errand = errandDoc.data();
    
    await errandsRef.doc(errandId).update({
      'status': 'broadcasted',
      'isPaymentApproved': true,
      'mpesaCode': mpesaCode,
    });

    if (errand != null) {
      await notificationsRef.add(NotificationModel(
        id: '',
        receiverId: errand.customerId,
        title: 'Payment Approved!',
        body: 'Payment for your errand "${errand.title}" has been verified. We are now finding a Runner.',
        isRead: false,
        timestamp: DateTime.now(),
      ));
    }

    await logAction(errandId, 'Admin verified Payment', adminId: adminId, details: 'M-Pesa Code: $mpesaCode');
  }

  Future<void> completeErrand(String errandId, String runnerId, String vCode, double receivedAmount) async {
    final doc = await errandsRef.doc(errandId).get();
    final errand = doc.data();
    
    if (errand == null || errand.verificationCode != vCode) {
       throw Exception('Invalid verification code. Please ask the customer for the correct code.');
    }

    await errandsRef.doc(errandId).update({
      'status': 'completed',
    });

    await runnerStatusRef.doc(runnerId).update({
      'isOnline': true,
      'activeErrandId': FieldValue.delete(),
    });

    await notificationsRef.add(NotificationModel(
      id: '',
      receiverId: errand.customerId,
      title: 'Errand Completed!',
      body: 'Your errand "${errand.title}" is done. Please leave a review for your Runner.',
      isRead: false,
      timestamp: DateTime.now(),
    ));
    
    await logAction(errandId, 'Errand completed', details: 'Runner confirmed receiving KES $receivedAmount.');
    await cleanupOldData(); 
  }

  Future<void> releasePayout(String errandId, String runnerId, String adminId) async {
    final doc = await errandsRef.doc(errandId).get();
    final errand = doc.data();
    if (errand == null || errand.isPaidOut) return;

    // Fetch commission percentage from system configs
    final configDoc = await _db.collection('system_configs').doc('settings').get();
    final commissionPercent = (configDoc.data()?['runnerCommissionPercentage'] ?? 80.0).toDouble();

    final totalAmount = errand.estimatedPrice;
    final runnerShare = totalAmount * (commissionPercent / 100);

    await walletsRef.doc(runnerId).set(
      Wallet(userId: runnerId, balance: 0, lastUpdated: DateTime.now()),
      SetOptions(merge: true),
    );
    
    await walletsRef.doc(runnerId).update({
      'balance': FieldValue.increment(runnerShare),
      'lastUpdated': DateTime.now(),
    });

    await errandsRef.doc(errandId).update({'isPaidOut': true});

    // Update global statistics
    await statisticsRef.doc('global').set(
      Statistics(totalRevenue: 0, totalErrandsCount: 0, totalUsersCount: 0, dailyActiveRunners: 0),
      SetOptions(merge: true),
    );
    await statisticsRef.doc('global').update({
      'totalRevenue': FieldValue.increment(totalAmount),
      'totalErrandsCount': FieldValue.increment(1),
    });

    await transactionsRef.add(AppTransaction(
      id: '',
      errandId: errandId,
      userId: runnerId,
      mpesaCode: 'PAYOUT-${doc.id}',
      status: 'approved',
      amount: runnerShare,
      createdAt: DateTime.now(),
    ));

    await logAction(
      errandId, 
      'Payout released', 
      adminId: adminId, 
      details: 'Total: $totalAmount, Runner Share: $runnerShare ($commissionPercent%)'
    );
  }

  Stream<SystemConfig> streamSystemConfig() {
    return _db.collection('system_configs').doc('settings').snapshots().map((s) => SystemConfig.fromFirestore(s, null));
  }

  Future<void> updateSystemConfig(SystemConfig config) async {
    await _db.collection('system_configs').doc('settings').set(config.toFirestore(), SetOptions(merge: true));
  }

  Future<void> cleanupOldData() async {
    final oldDate = DateTime.now().subtract(const Duration(days: 30));
    final oldNotifs = await notificationsRef
        .where('timestamp', isLessThan: Timestamp.fromDate(oldDate))
        .get();
        
    final batch = _db.batch();
    for (var doc in oldNotifs.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> updateUserDebt(String userId, double newDebt) async {
    await usersRef.doc(userId).update({'debt': newDebt});
  }

  Future<void> clearAuditLogs() async {
    final logs = await auditLogsRef.get();
    final batch = _db.batch();
    for (var doc in logs.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> updateEULA(String text) async {
    await _db.collection('system_configs').doc('settings').set({'eulaText': text}, SetOptions(merge: true));
  }

  // Errand streams
  Stream<List<Errand>> streamCustomerErrands(String customerId) {
    return errandsRef
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<Errand>> streamRunnerErrands() {
    return errandsRef
        .where('status', isEqualTo: 'broadcasted')
        .where('isPaymentApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<Errand?> getActiveErrand(String runnerId) {
    return errandsRef
        .where('runnerId', isEqualTo: runnerId)
        .where('status', isEqualTo: 'accepted')
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isEmpty ? null : snapshot.docs.first.data());
  }

  Future<void> acceptErrand(String errandId, String runnerId) async {
    await errandsRef.doc(errandId).update({
      'status': 'accepted',
      'runnerId': runnerId,
    });
    
    await runnerStatusRef.doc(runnerId).update({
      'isOnline': false,
      'activeErrandId': errandId,
    });

    await logAction(errandId, 'Runner $runnerId accepted errand');
  }

  Future<void> postponeErrand(String errandId, String reason) async {
    await errandsRef.doc(errandId).update({
      'status': 'postponed',
      'postponedReason': reason,
    });
  }

  Future<void> reportBulkyErrand(String errandId, String evidenceImageUrl, double surcharge) async {
    await errandsRef.doc(errandId).update({
      'isBulky': true,
      'evidenceImageUrl': evidenceImageUrl,
      'surcharge': surcharge,
      'price': FieldValue.increment(surcharge),
    });
  }

  Future<void> updateRunnerStatus(String runnerId, bool isOnline, {double lat = 0, double long = 0, String? activeErrandId}) async {
    final rs = RunnerStatus(
      runnerId: runnerId,
      isOnline: isOnline,
      latitude: lat,
      longitude: long,
      activeErrandId: activeErrandId,
    );
    await runnerStatusRef.doc(runnerId).set(rs);
  }

  Stream<Statistics?> streamStatistics() {
    return statisticsRef.doc('global').snapshots().map((s) => s.data());
  }

  // Users
  Future<AppUser?> getUser(String userId) async {
    final doc = await usersRef.doc(userId).get();
    return doc.data();
  }

  Stream<List<AppUser>> streamUsers() {
    return usersRef.snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    await usersRef.doc(userId).update({'role': newRole});
  }

  Future<void> updateUserBlockedStatus(String userId, bool isBlocked) async {
    await usersRef.doc(userId).update({'isBlocked': isBlocked});
  }

  Future<void> deleteUser(String userId) async {
    await usersRef.doc(userId).delete();
  }

  // Rates
  Future<void> addLocationRate(String area, String category, double rate, {double extraKmRate = 0.0}) async {
    final lr = LocationRate(id: area, area: area, category: category, rate: rate, extraKmRate: extraKmRate);
    await locationRatesRef.doc(area).set(lr);
  }

  Future<void> updateLocationRate(String id, String area, String category, double rate, {double extraKmRate = 0.0}) async {
    await locationRatesRef.doc(id).set(LocationRate(
      id: id,
      area: area,
      category: category,
      rate: rate,
      extraKmRate: extraKmRate,
    ));
  }

  Future<void> deleteLocationRate(String id) async {
    await locationRatesRef.doc(id).delete();
  }

  // FAQ
  Stream<List<FAQ>> streamFAQs(String category) {
    return faqsRef
        .where('category', isEqualTo: category)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<void> addFAQ(String question, String answer, String category) async {
    await faqsRef.add(FAQ(id: '', question: question, answer: answer, category: category));
  }

  Future<void> updateFAQ(String id, String question, String answer, String category) async {
    await faqsRef.doc(id).update({'question': question, 'answer': answer, 'category': category});
  }

  Future<void> deleteFAQ(String id) async {
    await faqsRef.doc(id).delete();
  }

  // Promo
  Future<void> sendPromoCode({
    required String code,
    required double discountAmount,
    required DateTime expiryDate,
  }) async {
    final promo = PromoCode(
      id: '',
      code: code,
      discountAmount: discountAmount,
      expiryDate: expiryDate,
      isActive: true,
    );
    await _db.collection('pricing_addons').add(promo.toFirestore());
  }

  // Reviews
  Future<void> addReview(String errandId, String runnerId, int rating, String comment) async {
    final review = Review(id: '', errandId: errandId, runnerId: runnerId, rating: rating, comment: comment);
    await reviewsRef.add(review);
  }

  Stream<List<Review>> streamRunnerReviews(String runnerId) {
    return reviewsRef
        .where('runnerId', isEqualTo: runnerId)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  // Generic DB helpers
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection(String collectionName) {
    return _db.collection(collectionName).snapshots();
  }

  Future<void> deleteDocument(String collectionName, String docId) async {
    await _db.collection(collectionName).doc(docId).delete();
  }

  Future<void> updateDocument(String collectionName, String docId, Map<String, dynamic> data) async {
    await _db.collection(collectionName).doc(docId).update(data);
  }

  Future<PromoCode?> verifyPromoCode(String code) async {
     final snapshot = await _db.collection('pricing_addons')
        .where('code', isEqualTo: code)
        .where('isActive', isEqualTo: true)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return PromoCode.fromFirestore(snapshot.docs.first, null);
  }
}
