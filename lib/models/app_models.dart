import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String role; // admin/runner/customer
  final bool isBlocked;
  final DateTime createdAt;
  final double debt; // Kept for logic compatibility

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.isBlocked,
    required this.createdAt,
    this.debt = 0.0,
  });

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return AppUser(
      id: snapshot.id,
      name: data?['name'] ?? '',
      email: data?['email'] ?? '',
      phoneNumber: data?['phone'] ?? data?['phoneNumber'] ?? '', // Handle both schemas
      role: data?['role'] ?? 'customer',
      isBlocked: data?['isBlocked'] ?? false,
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      debt: (data?['debt'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phoneNumber,
      'role': role,
      'isBlocked': isBlocked,
      'createdAt': createdAt,
      'debt': debt,
    };
  }
}

class Wallet {
  final String userId;
  final double balance;
  final DateTime lastUpdated;
  final String currency;

  Wallet({
    required this.userId,
    required this.balance,
    required this.lastUpdated,
    this.currency = 'KES',
  });

  factory Wallet.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return Wallet(
      userId: snapshot.id,
      balance: (data?['balance'] ?? 0).toDouble(),
      lastUpdated: (data?['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      currency: data?['currency'] ?? 'KES',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'balance': balance,
      'lastUpdated': lastUpdated,
      'currency': currency,
    };
  }
}

class Errand {
  final String id;
  final String customerId;
  final String? runnerId;
  final String status; // pending/accepted/done/in progress/postponed/completed
  final String pickupLocation;
  final String deliveryLocation;
  final double estimatedPrice;
  final DateTime createdAt;
  
  // UI/Logic specific fields (kept for backward compatibility)
  final String title;
  final String description;
  final String? stopOverLocation;
  final String? alternativeContact;
  final bool hasStopOver;
  final bool isBulky;
  final double surcharge;
  final String? evidenceImageUrl;
  final String? promoCodeUsed;
  final DateTime? scheduledAt;
  final String paymentType; 
  final bool isPaymentApproved;
  final String? mpesaCode;
  final String? verificationCode;
  final bool isPaidOut;
  final bool runnerPaymentConfirmation;
  final double amountConfirmedByRunner;
  final String? postponedReason;

  Errand({
    required this.id,
    required this.customerId,
    this.runnerId,
    required this.status,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.estimatedPrice,
    required this.createdAt,
    this.title = '',
    this.description = '',
    this.stopOverLocation,
    this.alternativeContact,
    this.hasStopOver = false,
    this.isBulky = false,
    this.surcharge = 0.0,
    this.evidenceImageUrl,
    this.promoCodeUsed,
    this.scheduledAt,
    this.paymentType = 'pay_later',
    this.isPaymentApproved = false,
    this.mpesaCode,
    this.verificationCode,
    this.isPaidOut = false,
    this.runnerPaymentConfirmation = false,
    this.amountConfirmedByRunner = 0.0,
    this.postponedReason,
  });

  factory Errand.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return Errand(
      id: snapshot.id,
      customerId: data?['customerId'] ?? '',
      runnerId: data?['runnerId'],
      status: data?['status'] ?? 'pending',
      pickupLocation: data?['pickup'] ?? data?['pickupLocation'] ?? '',
      deliveryLocation: data?['dropoff'] ?? data?['deliveryLocation'] ?? '',
      estimatedPrice: (data?['price'] ?? data?['estimatedPrice'] ?? 0).toDouble(),
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      title: data?['title'] ?? '',
      description: data?['description'] ?? '',
      stopOverLocation: data?['stopOverLocation'],
      alternativeContact: data?['alternativeContact'],
      hasStopOver: data?['hasStopOver'] ?? false,
      isBulky: data?['isBulky'] ?? false,
      surcharge: (data?['surcharge'] ?? 0.0).toDouble(),
      evidenceImageUrl: data?['evidenceImageUrl'],
      promoCodeUsed: data?['promoCodeUsed'],
      scheduledAt: (data?['scheduledAt'] as Timestamp?)?.toDate(),
      paymentType: data?['paymentType'] ?? 'pay_later',
      isPaymentApproved: data?['isPaymentApproved'] ?? false,
      mpesaCode: data?['mpesaCode'],
      verificationCode: data?['verificationCode'],
      isPaidOut: data?['isPaidOut'] ?? false,
      runnerPaymentConfirmation: data?['runnerPaymentConfirmation'] ?? false,
      amountConfirmedByRunner: (data?['amountConfirmedByRunner'] ?? 0.0).toDouble(),
      postponedReason: data?['postponedReason'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'runnerId': runnerId,
      'status': status,
      'pickup': pickupLocation,
      'dropoff': deliveryLocation,
      'price': estimatedPrice,
      'createdAt': createdAt,
      'title': title,
      'description': description,
      'stopOverLocation': stopOverLocation,
      'alternativeContact': alternativeContact,
      'hasStopOver': hasStopOver,
      'isBulky': isBulky,
      'surcharge': surcharge,
      'evidenceImageUrl': evidenceImageUrl,
      'promoCodeUsed': promoCodeUsed,
      'scheduledAt': scheduledAt,
      'paymentType': paymentType,
      'isPaymentApproved': isPaymentApproved,
      'mpesaCode': mpesaCode,
      'verificationCode': verificationCode,
      'isPaidOut': isPaidOut,
      'runnerPaymentConfirmation': runnerPaymentConfirmation,
      'amountConfirmedByRunner': amountConfirmedByRunner,
      'postponedReason': postponedReason,
    };
  }
}

class LocationRate {
  final String id;
  final String area;
  final String category;
  final double rate;
  final double extraKmRate;

  LocationRate({
    required this.id, 
    required this.area, 
    required this.category,
    required this.rate,
    this.extraKmRate = 0.0,
  });

  factory LocationRate.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return LocationRate(
      id: snapshot.id,
      area: data?['area'] ?? data?['locationName'] ?? data?['name'] ?? '',
      category: data?['category'] ?? 'Uncategorized',
      rate: (data?['rate'] ?? data?['baseFee'] ?? data?['distanceFee'] ?? 0).toDouble(),
      extraKmRate: (data?['extraKmRate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'area': area,
      'category': category,
      'rate': rate,
      'extraKmRate': extraKmRate,
    };
  }
}

class ServiceRate {
  final String id;
  final String name;
  final double flatRate;

  ServiceRate({required this.id, required this.name, required this.flatRate});

  factory ServiceRate.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return ServiceRate(
      id: snapshot.id,
      name: data?['serviceName'] ?? data?['name'] ?? '',
      flatRate: (data?['flatRate'] ?? data?['basePrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'serviceName': name,
      'flatRate': flatRate,
    };
  }
}

class PricingAddon {
  final String id;
  final String addonName;
  final double additionalCost;

  PricingAddon({required this.id, required this.addonName, required this.additionalCost});

  factory PricingAddon.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return PricingAddon(
      id: snapshot.id,
      addonName: data?['addonName'] ?? '',
      additionalCost: (data?['additionalCost'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'addonName': addonName,
      'additionalCost': additionalCost,
    };
  }
}

class AppTransaction {
  final String id;
  final String errandId;
  final String userId;
  final String mpesaCode;
  final String status; // pending/approved/payout_released
  final double amount;
  final DateTime createdAt;

  AppTransaction({
    required this.id,
    required this.errandId,
    required this.userId,
    required this.mpesaCode,
    required this.status,
    required this.amount,
    required this.createdAt,
  });

  factory AppTransaction.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return AppTransaction(
      id: snapshot.id,
      errandId: data?['errandId'] ?? '',
      userId: data?['userId'] ?? '',
      mpesaCode: data?['mpesaCode'] ?? '',
      status: data?['status'] ?? 'pending',
      amount: (data?['amount'] ?? 0).toDouble(),
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'errandId': errandId,
      'userId': userId,
      'mpesaCode': mpesaCode,
      'status': status,
      'amount': amount,
      'createdAt': createdAt,
    };
  }
}

class AuditLog {
  final String id;
  final String errandId; // Kept for logic compatibility
  final String adminId;
  final String action;
  final DateTime timestamp;
  final String details;

  AuditLog({
    required this.id,
    this.errandId = '',
    this.adminId = '',
    required this.action,
    required this.timestamp,
    this.details = '',
  });

  factory AuditLog.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return AuditLog(
      id: snapshot.id,
      errandId: data?['errandId'] ?? '',
      adminId: data?['adminId'] ?? '',
      action: data?['action'] ?? '',
      timestamp: (data?['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      details: data?['details'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'errandId': errandId,
      'adminId': adminId,
      'action': action,
      'timestamp': timestamp,
      'details': details,
    };
  }
}

class NotificationModel {
  final String id;
  final String receiverId;
  final String title;
  final String body;
  final bool isRead;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.receiverId,
    required this.title,
    required this.body,
    required this.isRead,
    required this.timestamp,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return NotificationModel(
      id: snapshot.id,
      receiverId: data?['receiverId'] ?? data?['userId'] ?? '',
      title: data?['title'] ?? '',
      body: data?['body'] ?? data?['message'] ?? '',
      isRead: data?['isRead'] ?? false,
      timestamp: (data?['timestamp'] as Timestamp?)?.toDate() ?? (data?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'receiverId': receiverId,
      'title': title,
      'body': body,
      'isRead': isRead,
      'timestamp': timestamp,
    };
  }
}

class RunnerStatus {
  final String runnerId;
  final bool isOnline;
  final double latitude;
  final double longitude;
  final String? activeErrandId;

  RunnerStatus({
    required this.runnerId,
    required this.isOnline,
    required this.latitude,
    required this.longitude,
    this.activeErrandId,
  });

  factory RunnerStatus.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return RunnerStatus(
      runnerId: snapshot.id,
      isOnline: data?['isOnline'] ?? false,
      latitude: (data?['currentLat'] ?? 0.0).toDouble(),
      longitude: (data?['currentLong'] ?? 0.0).toDouble(),
      activeErrandId: data?['activeErrandId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'isOnline': isOnline,
      'currentLat': latitude,
      'currentLong': longitude,
      'activeErrandId': activeErrandId,
    };
  }
}

class Statistics {
  final double totalRevenue;
  final int totalErrandsCount;
  final int totalUsersCount;
  final int dailyActiveRunners;

  Statistics({
    required this.totalRevenue,
    required this.totalErrandsCount,
    required this.totalUsersCount,
    required this.dailyActiveRunners,
  });

  factory Statistics.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return Statistics(
      totalRevenue: (data?['totalRevenue'] ?? 0.0).toDouble(),
      totalErrandsCount: data?['totalErrandsCount'] ?? 0,
      totalUsersCount: data?['totalUsersCount'] ?? 0,
      dailyActiveRunners: data?['dailyActiveRunners'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'totalRevenue': totalRevenue,
      'totalErrandsCount': totalErrandsCount,
      'totalUsersCount': totalUsersCount,
      'dailyActiveRunners': dailyActiveRunners,
    };
  }
}

class Review {
  final String id;
  final String errandId;
  final String runnerId;
  final int rating;
  final String comment;

  Review({
    required this.id,
    required this.errandId,
    required this.runnerId,
    required this.rating,
    required this.comment,
  });

  factory Review.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return Review(
      id: snapshot.id,
      errandId: data?['errandId'] ?? '',
      runnerId: data?['runnerId'] ?? '',
      rating: (data?['rating'] ?? 0).toInt(),
      comment: data?['comment'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'errandId': errandId,
      'runnerId': runnerId,
      'rating': rating,
      'comment': comment,
    };
  }
}

class SystemConfig {
  final String eulaText;
  final String contactEmail;
  final double minWithdrawalAmount;
  final String appVersion;
  final double runnerCommissionPercentage;

  SystemConfig({
    required this.eulaText,
    required this.contactEmail,
    required this.minWithdrawalAmount,
    required this.appVersion,
    this.runnerCommissionPercentage = 80.0,
  });

  factory SystemConfig.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return SystemConfig(
      eulaText: data?['eulaText'] ?? '',
      contactEmail: data?['contactEmail'] ?? '',
      minWithdrawalAmount: (data?['minWithdrawalAmount'] ?? 0.0).toDouble(),
      appVersion: data?['appVersion'] ?? '1.0.0',
      runnerCommissionPercentage: (data?['runnerCommissionPercentage'] ?? 80.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eulaText': eulaText,
      'contactEmail': contactEmail,
      'minWithdrawalAmount': minWithdrawalAmount,
      'appVersion': appVersion,
      'runnerCommissionPercentage': runnerCommissionPercentage,
    };
  }
}

class FAQ {
  final String id;
  final String question;
  final String answer;
  final String category;

  FAQ({required this.id, required this.question, required this.answer, required this.category});

  factory FAQ.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return FAQ(
      id: snapshot.id,
      question: data?['question'] ?? '',
      answer: data?['answer'] ?? '',
      category: data?['category'] ?? data?['role'] ?? 'General',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'question': question,
      'answer': answer,
      'category': category,
    };
  }
}

class PromoCode {
  final String id;
  final String code;
  final double discountAmount;
  final DateTime expiryDate;
  final bool isActive;

  PromoCode({
    required this.id,
    required this.code,
    required this.discountAmount,
    required this.expiryDate,
    required this.isActive,
  });

  factory PromoCode.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return PromoCode(
      id: snapshot.id,
      code: data?['code'] ?? '',
      discountAmount: (data?['discountAmount'] ?? 0.0).toDouble(),
      expiryDate: (data?['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data?['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'discountAmount': discountAmount,
      'expiryDate': expiryDate,
      'isActive': isActive,
    };
  }
}
