// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalOrganizationsTable extends LocalOrganizations
    with TableInfo<$LocalOrganizationsTable, LocalOrganization> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalOrganizationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _businessTypeMeta =
      const VerificationMeta('businessType');
  @override
  late final GeneratedColumn<String> businessType = GeneratedColumn<String>(
      'business_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerNameMeta =
      const VerificationMeta('ownerName');
  @override
  late final GeneratedColumn<String> ownerName = GeneratedColumn<String>(
      'owner_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneNumberMeta =
      const VerificationMeta('phoneNumber');
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
      'phone_number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _planMeta = const VerificationMeta('plan');
  @override
  late final GeneratedColumn<String> plan = GeneratedColumn<String>(
      'plan', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('trial'));
  static const VerificationMeta _billingStatusMeta =
      const VerificationMeta('billingStatus');
  @override
  late final GeneratedColumn<String> billingStatus = GeneratedColumn<String>(
      'billing_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _licenseKeyMeta =
      const VerificationMeta('licenseKey');
  @override
  late final GeneratedColumn<String> licenseKey = GeneratedColumn<String>(
      'license_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _trialEndsAtMeta =
      const VerificationMeta('trialEndsAt');
  @override
  late final GeneratedColumn<DateTime> trialEndsAt = GeneratedColumn<DateTime>(
      'trial_ends_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        businessType,
        ownerName,
        phoneNumber,
        plan,
        billingStatus,
        licenseKey,
        trialEndsAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_organizations';
  @override
  VerificationContext validateIntegrity(Insertable<LocalOrganization> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('business_type')) {
      context.handle(
          _businessTypeMeta,
          businessType.isAcceptableOrUnknown(
              data['business_type']!, _businessTypeMeta));
    } else if (isInserting) {
      context.missing(_businessTypeMeta);
    }
    if (data.containsKey('owner_name')) {
      context.handle(_ownerNameMeta,
          ownerName.isAcceptableOrUnknown(data['owner_name']!, _ownerNameMeta));
    } else if (isInserting) {
      context.missing(_ownerNameMeta);
    }
    if (data.containsKey('phone_number')) {
      context.handle(
          _phoneNumberMeta,
          phoneNumber.isAcceptableOrUnknown(
              data['phone_number']!, _phoneNumberMeta));
    } else if (isInserting) {
      context.missing(_phoneNumberMeta);
    }
    if (data.containsKey('plan')) {
      context.handle(
          _planMeta, plan.isAcceptableOrUnknown(data['plan']!, _planMeta));
    }
    if (data.containsKey('billing_status')) {
      context.handle(
          _billingStatusMeta,
          billingStatus.isAcceptableOrUnknown(
              data['billing_status']!, _billingStatusMeta));
    }
    if (data.containsKey('license_key')) {
      context.handle(
          _licenseKeyMeta,
          licenseKey.isAcceptableOrUnknown(
              data['license_key']!, _licenseKeyMeta));
    }
    if (data.containsKey('trial_ends_at')) {
      context.handle(
          _trialEndsAtMeta,
          trialEndsAt.isAcceptableOrUnknown(
              data['trial_ends_at']!, _trialEndsAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalOrganization map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalOrganization(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      businessType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}business_type'])!,
      ownerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_name'])!,
      phoneNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone_number'])!,
      plan: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan'])!,
      billingStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}billing_status'])!,
      licenseKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}license_key']),
      trialEndsAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}trial_ends_at']),
    );
  }

  @override
  $LocalOrganizationsTable createAlias(String alias) {
    return $LocalOrganizationsTable(attachedDatabase, alias);
  }
}

class LocalOrganization extends DataClass
    implements Insertable<LocalOrganization> {
  final String id;
  final String name;
  final String businessType;
  final String ownerName;
  final String phoneNumber;
  final String plan;
  final String billingStatus;
  final String? licenseKey;
  final DateTime? trialEndsAt;
  const LocalOrganization(
      {required this.id,
      required this.name,
      required this.businessType,
      required this.ownerName,
      required this.phoneNumber,
      required this.plan,
      required this.billingStatus,
      this.licenseKey,
      this.trialEndsAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['business_type'] = Variable<String>(businessType);
    map['owner_name'] = Variable<String>(ownerName);
    map['phone_number'] = Variable<String>(phoneNumber);
    map['plan'] = Variable<String>(plan);
    map['billing_status'] = Variable<String>(billingStatus);
    if (!nullToAbsent || licenseKey != null) {
      map['license_key'] = Variable<String>(licenseKey);
    }
    if (!nullToAbsent || trialEndsAt != null) {
      map['trial_ends_at'] = Variable<DateTime>(trialEndsAt);
    }
    return map;
  }

  LocalOrganizationsCompanion toCompanion(bool nullToAbsent) {
    return LocalOrganizationsCompanion(
      id: Value(id),
      name: Value(name),
      businessType: Value(businessType),
      ownerName: Value(ownerName),
      phoneNumber: Value(phoneNumber),
      plan: Value(plan),
      billingStatus: Value(billingStatus),
      licenseKey: licenseKey == null && nullToAbsent
          ? const Value.absent()
          : Value(licenseKey),
      trialEndsAt: trialEndsAt == null && nullToAbsent
          ? const Value.absent()
          : Value(trialEndsAt),
    );
  }

  factory LocalOrganization.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalOrganization(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      businessType: serializer.fromJson<String>(json['businessType']),
      ownerName: serializer.fromJson<String>(json['ownerName']),
      phoneNumber: serializer.fromJson<String>(json['phoneNumber']),
      plan: serializer.fromJson<String>(json['plan']),
      billingStatus: serializer.fromJson<String>(json['billingStatus']),
      licenseKey: serializer.fromJson<String?>(json['licenseKey']),
      trialEndsAt: serializer.fromJson<DateTime?>(json['trialEndsAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'businessType': serializer.toJson<String>(businessType),
      'ownerName': serializer.toJson<String>(ownerName),
      'phoneNumber': serializer.toJson<String>(phoneNumber),
      'plan': serializer.toJson<String>(plan),
      'billingStatus': serializer.toJson<String>(billingStatus),
      'licenseKey': serializer.toJson<String?>(licenseKey),
      'trialEndsAt': serializer.toJson<DateTime?>(trialEndsAt),
    };
  }

  LocalOrganization copyWith(
          {String? id,
          String? name,
          String? businessType,
          String? ownerName,
          String? phoneNumber,
          String? plan,
          String? billingStatus,
          Value<String?> licenseKey = const Value.absent(),
          Value<DateTime?> trialEndsAt = const Value.absent()}) =>
      LocalOrganization(
        id: id ?? this.id,
        name: name ?? this.name,
        businessType: businessType ?? this.businessType,
        ownerName: ownerName ?? this.ownerName,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        plan: plan ?? this.plan,
        billingStatus: billingStatus ?? this.billingStatus,
        licenseKey: licenseKey.present ? licenseKey.value : this.licenseKey,
        trialEndsAt: trialEndsAt.present ? trialEndsAt.value : this.trialEndsAt,
      );
  LocalOrganization copyWithCompanion(LocalOrganizationsCompanion data) {
    return LocalOrganization(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      businessType: data.businessType.present
          ? data.businessType.value
          : this.businessType,
      ownerName: data.ownerName.present ? data.ownerName.value : this.ownerName,
      phoneNumber:
          data.phoneNumber.present ? data.phoneNumber.value : this.phoneNumber,
      plan: data.plan.present ? data.plan.value : this.plan,
      billingStatus: data.billingStatus.present
          ? data.billingStatus.value
          : this.billingStatus,
      licenseKey:
          data.licenseKey.present ? data.licenseKey.value : this.licenseKey,
      trialEndsAt:
          data.trialEndsAt.present ? data.trialEndsAt.value : this.trialEndsAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalOrganization(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('businessType: $businessType, ')
          ..write('ownerName: $ownerName, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('plan: $plan, ')
          ..write('billingStatus: $billingStatus, ')
          ..write('licenseKey: $licenseKey, ')
          ..write('trialEndsAt: $trialEndsAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, businessType, ownerName,
      phoneNumber, plan, billingStatus, licenseKey, trialEndsAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalOrganization &&
          other.id == this.id &&
          other.name == this.name &&
          other.businessType == this.businessType &&
          other.ownerName == this.ownerName &&
          other.phoneNumber == this.phoneNumber &&
          other.plan == this.plan &&
          other.billingStatus == this.billingStatus &&
          other.licenseKey == this.licenseKey &&
          other.trialEndsAt == this.trialEndsAt);
}

class LocalOrganizationsCompanion extends UpdateCompanion<LocalOrganization> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> businessType;
  final Value<String> ownerName;
  final Value<String> phoneNumber;
  final Value<String> plan;
  final Value<String> billingStatus;
  final Value<String?> licenseKey;
  final Value<DateTime?> trialEndsAt;
  final Value<int> rowid;
  const LocalOrganizationsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.businessType = const Value.absent(),
    this.ownerName = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.plan = const Value.absent(),
    this.billingStatus = const Value.absent(),
    this.licenseKey = const Value.absent(),
    this.trialEndsAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalOrganizationsCompanion.insert({
    required String id,
    required String name,
    required String businessType,
    required String ownerName,
    required String phoneNumber,
    this.plan = const Value.absent(),
    this.billingStatus = const Value.absent(),
    this.licenseKey = const Value.absent(),
    this.trialEndsAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        businessType = Value(businessType),
        ownerName = Value(ownerName),
        phoneNumber = Value(phoneNumber);
  static Insertable<LocalOrganization> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? businessType,
    Expression<String>? ownerName,
    Expression<String>? phoneNumber,
    Expression<String>? plan,
    Expression<String>? billingStatus,
    Expression<String>? licenseKey,
    Expression<DateTime>? trialEndsAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (businessType != null) 'business_type': businessType,
      if (ownerName != null) 'owner_name': ownerName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (plan != null) 'plan': plan,
      if (billingStatus != null) 'billing_status': billingStatus,
      if (licenseKey != null) 'license_key': licenseKey,
      if (trialEndsAt != null) 'trial_ends_at': trialEndsAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalOrganizationsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? businessType,
      Value<String>? ownerName,
      Value<String>? phoneNumber,
      Value<String>? plan,
      Value<String>? billingStatus,
      Value<String?>? licenseKey,
      Value<DateTime?>? trialEndsAt,
      Value<int>? rowid}) {
    return LocalOrganizationsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      businessType: businessType ?? this.businessType,
      ownerName: ownerName ?? this.ownerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      plan: plan ?? this.plan,
      billingStatus: billingStatus ?? this.billingStatus,
      licenseKey: licenseKey ?? this.licenseKey,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (businessType.present) {
      map['business_type'] = Variable<String>(businessType.value);
    }
    if (ownerName.present) {
      map['owner_name'] = Variable<String>(ownerName.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (plan.present) {
      map['plan'] = Variable<String>(plan.value);
    }
    if (billingStatus.present) {
      map['billing_status'] = Variable<String>(billingStatus.value);
    }
    if (licenseKey.present) {
      map['license_key'] = Variable<String>(licenseKey.value);
    }
    if (trialEndsAt.present) {
      map['trial_ends_at'] = Variable<DateTime>(trialEndsAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalOrganizationsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('businessType: $businessType, ')
          ..write('ownerName: $ownerName, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('plan: $plan, ')
          ..write('billingStatus: $billingStatus, ')
          ..write('licenseKey: $licenseKey, ')
          ..write('trialEndsAt: $trialEndsAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalBranchesTable extends LocalBranches
    with TableInfo<$LocalBranchesTable, LocalBranche> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalBranchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _organizationIdMeta =
      const VerificationMeta('organizationId');
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
      'organization_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _locationMeta =
      const VerificationMeta('location');
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
      'location', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tillNumberMeta =
      const VerificationMeta('tillNumber');
  @override
  late final GeneratedColumn<String> tillNumber = GeneratedColumn<String>(
      'till_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns =>
      [id, organizationId, name, location, tillNumber, isActive];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_branches';
  @override
  VerificationContext validateIntegrity(Insertable<LocalBranche> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('organization_id')) {
      context.handle(
          _organizationIdMeta,
          organizationId.isAcceptableOrUnknown(
              data['organization_id']!, _organizationIdMeta));
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('location')) {
      context.handle(_locationMeta,
          location.isAcceptableOrUnknown(data['location']!, _locationMeta));
    }
    if (data.containsKey('till_number')) {
      context.handle(
          _tillNumberMeta,
          tillNumber.isAcceptableOrUnknown(
              data['till_number']!, _tillNumberMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalBranche map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalBranche(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      organizationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}organization_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      location: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location']),
      tillNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}till_number']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
    );
  }

  @override
  $LocalBranchesTable createAlias(String alias) {
    return $LocalBranchesTable(attachedDatabase, alias);
  }
}

class LocalBranche extends DataClass implements Insertable<LocalBranche> {
  final String id;
  final String organizationId;
  final String name;
  final String? location;
  final String? tillNumber;
  final bool isActive;
  const LocalBranche(
      {required this.id,
      required this.organizationId,
      required this.name,
      this.location,
      this.tillNumber,
      required this.isActive});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['organization_id'] = Variable<String>(organizationId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || tillNumber != null) {
      map['till_number'] = Variable<String>(tillNumber);
    }
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  LocalBranchesCompanion toCompanion(bool nullToAbsent) {
    return LocalBranchesCompanion(
      id: Value(id),
      organizationId: Value(organizationId),
      name: Value(name),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      tillNumber: tillNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(tillNumber),
      isActive: Value(isActive),
    );
  }

  factory LocalBranche.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalBranche(
      id: serializer.fromJson<String>(json['id']),
      organizationId: serializer.fromJson<String>(json['organizationId']),
      name: serializer.fromJson<String>(json['name']),
      location: serializer.fromJson<String?>(json['location']),
      tillNumber: serializer.fromJson<String?>(json['tillNumber']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'organizationId': serializer.toJson<String>(organizationId),
      'name': serializer.toJson<String>(name),
      'location': serializer.toJson<String?>(location),
      'tillNumber': serializer.toJson<String?>(tillNumber),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  LocalBranche copyWith(
          {String? id,
          String? organizationId,
          String? name,
          Value<String?> location = const Value.absent(),
          Value<String?> tillNumber = const Value.absent(),
          bool? isActive}) =>
      LocalBranche(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        name: name ?? this.name,
        location: location.present ? location.value : this.location,
        tillNumber: tillNumber.present ? tillNumber.value : this.tillNumber,
        isActive: isActive ?? this.isActive,
      );
  LocalBranche copyWithCompanion(LocalBranchesCompanion data) {
    return LocalBranche(
      id: data.id.present ? data.id.value : this.id,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      name: data.name.present ? data.name.value : this.name,
      location: data.location.present ? data.location.value : this.location,
      tillNumber:
          data.tillNumber.present ? data.tillNumber.value : this.tillNumber,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalBranche(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('name: $name, ')
          ..write('location: $location, ')
          ..write('tillNumber: $tillNumber, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, organizationId, name, location, tillNumber, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalBranche &&
          other.id == this.id &&
          other.organizationId == this.organizationId &&
          other.name == this.name &&
          other.location == this.location &&
          other.tillNumber == this.tillNumber &&
          other.isActive == this.isActive);
}

class LocalBranchesCompanion extends UpdateCompanion<LocalBranche> {
  final Value<String> id;
  final Value<String> organizationId;
  final Value<String> name;
  final Value<String?> location;
  final Value<String?> tillNumber;
  final Value<bool> isActive;
  final Value<int> rowid;
  const LocalBranchesCompanion({
    this.id = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.name = const Value.absent(),
    this.location = const Value.absent(),
    this.tillNumber = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalBranchesCompanion.insert({
    required String id,
    required String organizationId,
    required String name,
    this.location = const Value.absent(),
    this.tillNumber = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        organizationId = Value(organizationId),
        name = Value(name);
  static Insertable<LocalBranche> custom({
    Expression<String>? id,
    Expression<String>? organizationId,
    Expression<String>? name,
    Expression<String>? location,
    Expression<String>? tillNumber,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (organizationId != null) 'organization_id': organizationId,
      if (name != null) 'name': name,
      if (location != null) 'location': location,
      if (tillNumber != null) 'till_number': tillNumber,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalBranchesCompanion copyWith(
      {Value<String>? id,
      Value<String>? organizationId,
      Value<String>? name,
      Value<String?>? location,
      Value<String?>? tillNumber,
      Value<bool>? isActive,
      Value<int>? rowid}) {
    return LocalBranchesCompanion(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      location: location ?? this.location,
      tillNumber: tillNumber ?? this.tillNumber,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (tillNumber.present) {
      map['till_number'] = Variable<String>(tillNumber.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalBranchesCompanion(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('name: $name, ')
          ..write('location: $location, ')
          ..write('tillNumber: $tillNumber, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalBranchModulesTable extends LocalBranchModules
    with TableInfo<$LocalBranchModulesTable, LocalBranchModule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalBranchModulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _moduleKeyMeta =
      const VerificationMeta('moduleKey');
  @override
  late final GeneratedColumn<String> moduleKey = GeneratedColumn<String>(
      'module_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isEnabledMeta =
      const VerificationMeta('isEnabled');
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
      'is_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _configMeta = const VerificationMeta('config');
  @override
  late final GeneratedColumn<String> config = GeneratedColumn<String>(
      'config', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  @override
  List<GeneratedColumn> get $columns =>
      [branchId, moduleKey, isEnabled, config];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_branch_modules';
  @override
  VerificationContext validateIntegrity(Insertable<LocalBranchModule> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('module_key')) {
      context.handle(_moduleKeyMeta,
          moduleKey.isAcceptableOrUnknown(data['module_key']!, _moduleKeyMeta));
    } else if (isInserting) {
      context.missing(_moduleKeyMeta);
    }
    if (data.containsKey('is_enabled')) {
      context.handle(_isEnabledMeta,
          isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta));
    }
    if (data.containsKey('config')) {
      context.handle(_configMeta,
          config.isAcceptableOrUnknown(data['config']!, _configMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {branchId, moduleKey};
  @override
  LocalBranchModule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalBranchModule(
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch_id'])!,
      moduleKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}module_key'])!,
      isEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_enabled'])!,
      config: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}config'])!,
    );
  }

  @override
  $LocalBranchModulesTable createAlias(String alias) {
    return $LocalBranchModulesTable(attachedDatabase, alias);
  }
}

class LocalBranchModule extends DataClass
    implements Insertable<LocalBranchModule> {
  final String branchId;
  final String moduleKey;
  final bool isEnabled;
  final String config;
  const LocalBranchModule(
      {required this.branchId,
      required this.moduleKey,
      required this.isEnabled,
      required this.config});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['branch_id'] = Variable<String>(branchId);
    map['module_key'] = Variable<String>(moduleKey);
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['config'] = Variable<String>(config);
    return map;
  }

  LocalBranchModulesCompanion toCompanion(bool nullToAbsent) {
    return LocalBranchModulesCompanion(
      branchId: Value(branchId),
      moduleKey: Value(moduleKey),
      isEnabled: Value(isEnabled),
      config: Value(config),
    );
  }

  factory LocalBranchModule.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalBranchModule(
      branchId: serializer.fromJson<String>(json['branchId']),
      moduleKey: serializer.fromJson<String>(json['moduleKey']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      config: serializer.fromJson<String>(json['config']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'branchId': serializer.toJson<String>(branchId),
      'moduleKey': serializer.toJson<String>(moduleKey),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'config': serializer.toJson<String>(config),
    };
  }

  LocalBranchModule copyWith(
          {String? branchId,
          String? moduleKey,
          bool? isEnabled,
          String? config}) =>
      LocalBranchModule(
        branchId: branchId ?? this.branchId,
        moduleKey: moduleKey ?? this.moduleKey,
        isEnabled: isEnabled ?? this.isEnabled,
        config: config ?? this.config,
      );
  LocalBranchModule copyWithCompanion(LocalBranchModulesCompanion data) {
    return LocalBranchModule(
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      moduleKey: data.moduleKey.present ? data.moduleKey.value : this.moduleKey,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      config: data.config.present ? data.config.value : this.config,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalBranchModule(')
          ..write('branchId: $branchId, ')
          ..write('moduleKey: $moduleKey, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('config: $config')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(branchId, moduleKey, isEnabled, config);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalBranchModule &&
          other.branchId == this.branchId &&
          other.moduleKey == this.moduleKey &&
          other.isEnabled == this.isEnabled &&
          other.config == this.config);
}

class LocalBranchModulesCompanion extends UpdateCompanion<LocalBranchModule> {
  final Value<String> branchId;
  final Value<String> moduleKey;
  final Value<bool> isEnabled;
  final Value<String> config;
  final Value<int> rowid;
  const LocalBranchModulesCompanion({
    this.branchId = const Value.absent(),
    this.moduleKey = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.config = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalBranchModulesCompanion.insert({
    required String branchId,
    required String moduleKey,
    this.isEnabled = const Value.absent(),
    this.config = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : branchId = Value(branchId),
        moduleKey = Value(moduleKey);
  static Insertable<LocalBranchModule> custom({
    Expression<String>? branchId,
    Expression<String>? moduleKey,
    Expression<bool>? isEnabled,
    Expression<String>? config,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (branchId != null) 'branch_id': branchId,
      if (moduleKey != null) 'module_key': moduleKey,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (config != null) 'config': config,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalBranchModulesCompanion copyWith(
      {Value<String>? branchId,
      Value<String>? moduleKey,
      Value<bool>? isEnabled,
      Value<String>? config,
      Value<int>? rowid}) {
    return LocalBranchModulesCompanion(
      branchId: branchId ?? this.branchId,
      moduleKey: moduleKey ?? this.moduleKey,
      isEnabled: isEnabled ?? this.isEnabled,
      config: config ?? this.config,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (moduleKey.present) {
      map['module_key'] = Variable<String>(moduleKey.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (config.present) {
      map['config'] = Variable<String>(config.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalBranchModulesCompanion(')
          ..write('branchId: $branchId, ')
          ..write('moduleKey: $moduleKey, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('config: $config, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCategoriesTable extends LocalCategories
    with TableInfo<$LocalCategoriesTable, LocalCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _organizationIdMeta =
      const VerificationMeta('organizationId');
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
      'organization_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('#2563EB'));
  @override
  List<GeneratedColumn> get $columns => [id, organizationId, name, color];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_categories';
  @override
  VerificationContext validateIntegrity(Insertable<LocalCategory> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('organization_id')) {
      context.handle(
          _organizationIdMeta,
          organizationId.isAcceptableOrUnknown(
              data['organization_id']!, _organizationIdMeta));
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCategory(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      organizationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}organization_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color'])!,
    );
  }

  @override
  $LocalCategoriesTable createAlias(String alias) {
    return $LocalCategoriesTable(attachedDatabase, alias);
  }
}

class LocalCategory extends DataClass implements Insertable<LocalCategory> {
  final String id;
  final String organizationId;
  final String name;
  final String color;
  const LocalCategory(
      {required this.id,
      required this.organizationId,
      required this.name,
      required this.color});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['organization_id'] = Variable<String>(organizationId);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<String>(color);
    return map;
  }

  LocalCategoriesCompanion toCompanion(bool nullToAbsent) {
    return LocalCategoriesCompanion(
      id: Value(id),
      organizationId: Value(organizationId),
      name: Value(name),
      color: Value(color),
    );
  }

  factory LocalCategory.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCategory(
      id: serializer.fromJson<String>(json['id']),
      organizationId: serializer.fromJson<String>(json['organizationId']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'organizationId': serializer.toJson<String>(organizationId),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String>(color),
    };
  }

  LocalCategory copyWith(
          {String? id, String? organizationId, String? name, String? color}) =>
      LocalCategory(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        name: name ?? this.name,
        color: color ?? this.color,
      );
  LocalCategory copyWithCompanion(LocalCategoriesCompanion data) {
    return LocalCategory(
      id: data.id.present ? data.id.value : this.id,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCategory(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('name: $name, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, organizationId, name, color);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCategory &&
          other.id == this.id &&
          other.organizationId == this.organizationId &&
          other.name == this.name &&
          other.color == this.color);
}

class LocalCategoriesCompanion extends UpdateCompanion<LocalCategory> {
  final Value<String> id;
  final Value<String> organizationId;
  final Value<String> name;
  final Value<String> color;
  final Value<int> rowid;
  const LocalCategoriesCompanion({
    this.id = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCategoriesCompanion.insert({
    required String id,
    required String organizationId,
    required String name,
    this.color = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        organizationId = Value(organizationId),
        name = Value(name);
  static Insertable<LocalCategory> custom({
    Expression<String>? id,
    Expression<String>? organizationId,
    Expression<String>? name,
    Expression<String>? color,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (organizationId != null) 'organization_id': organizationId,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCategoriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? organizationId,
      Value<String>? name,
      Value<String>? color,
      Value<int>? rowid}) {
    return LocalCategoriesCompanion(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      color: color ?? this.color,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalProductsTable extends LocalProducts
    with TableInfo<$LocalProductsTable, LocalProduct> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _organizationIdMeta =
      const VerificationMeta('organizationId');
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
      'organization_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
      'sku', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _costPriceMeta =
      const VerificationMeta('costPrice');
  @override
  late final GeneratedColumn<double> costPrice = GeneratedColumn<double>(
      'cost_price', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _sellingPriceMeta =
      const VerificationMeta('sellingPrice');
  @override
  late final GeneratedColumn<double> sellingPrice = GeneratedColumn<double>(
      'selling_price', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _taxRateMeta =
      const VerificationMeta('taxRate');
  @override
  late final GeneratedColumn<double> taxRate = GeneratedColumn<double>(
      'tax_rate', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(16.0));
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pcs'));
  static const VerificationMeta _currentStockMeta =
      const VerificationMeta('currentStock');
  @override
  late final GeneratedColumn<double> currentStock = GeneratedColumn<double>(
      'current_stock', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        organizationId,
        categoryId,
        name,
        sku,
        barcode,
        costPrice,
        sellingPrice,
        taxRate,
        unit,
        currentStock,
        isActive
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_products';
  @override
  VerificationContext validateIntegrity(Insertable<LocalProduct> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('organization_id')) {
      context.handle(
          _organizationIdMeta,
          organizationId.isAcceptableOrUnknown(
              data['organization_id']!, _organizationIdMeta));
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
          _skuMeta, sku.isAcceptableOrUnknown(data['sku']!, _skuMeta));
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    }
    if (data.containsKey('cost_price')) {
      context.handle(_costPriceMeta,
          costPrice.isAcceptableOrUnknown(data['cost_price']!, _costPriceMeta));
    }
    if (data.containsKey('selling_price')) {
      context.handle(
          _sellingPriceMeta,
          sellingPrice.isAcceptableOrUnknown(
              data['selling_price']!, _sellingPriceMeta));
    }
    if (data.containsKey('tax_rate')) {
      context.handle(_taxRateMeta,
          taxRate.isAcceptableOrUnknown(data['tax_rate']!, _taxRateMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('current_stock')) {
      context.handle(
          _currentStockMeta,
          currentStock.isAcceptableOrUnknown(
              data['current_stock']!, _currentStockMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalProduct map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalProduct(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      organizationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}organization_id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sku: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sku']),
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode']),
      costPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cost_price'])!,
      sellingPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}selling_price'])!,
      taxRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tax_rate'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      currentStock: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}current_stock'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
    );
  }

  @override
  $LocalProductsTable createAlias(String alias) {
    return $LocalProductsTable(attachedDatabase, alias);
  }
}

class LocalProduct extends DataClass implements Insertable<LocalProduct> {
  final String id;
  final String organizationId;
  final String? categoryId;
  final String name;
  final String? sku;
  final String? barcode;
  final double costPrice;
  final double sellingPrice;
  final double taxRate;
  final String unit;
  final double currentStock;
  final bool isActive;
  const LocalProduct(
      {required this.id,
      required this.organizationId,
      this.categoryId,
      required this.name,
      this.sku,
      this.barcode,
      required this.costPrice,
      required this.sellingPrice,
      required this.taxRate,
      required this.unit,
      required this.currentStock,
      required this.isActive});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['organization_id'] = Variable<String>(organizationId);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['cost_price'] = Variable<double>(costPrice);
    map['selling_price'] = Variable<double>(sellingPrice);
    map['tax_rate'] = Variable<double>(taxRate);
    map['unit'] = Variable<String>(unit);
    map['current_stock'] = Variable<double>(currentStock);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  LocalProductsCompanion toCompanion(bool nullToAbsent) {
    return LocalProductsCompanion(
      id: Value(id),
      organizationId: Value(organizationId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      name: Value(name),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      costPrice: Value(costPrice),
      sellingPrice: Value(sellingPrice),
      taxRate: Value(taxRate),
      unit: Value(unit),
      currentStock: Value(currentStock),
      isActive: Value(isActive),
    );
  }

  factory LocalProduct.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalProduct(
      id: serializer.fromJson<String>(json['id']),
      organizationId: serializer.fromJson<String>(json['organizationId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
      sku: serializer.fromJson<String?>(json['sku']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      costPrice: serializer.fromJson<double>(json['costPrice']),
      sellingPrice: serializer.fromJson<double>(json['sellingPrice']),
      taxRate: serializer.fromJson<double>(json['taxRate']),
      unit: serializer.fromJson<String>(json['unit']),
      currentStock: serializer.fromJson<double>(json['currentStock']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'organizationId': serializer.toJson<String>(organizationId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'name': serializer.toJson<String>(name),
      'sku': serializer.toJson<String?>(sku),
      'barcode': serializer.toJson<String?>(barcode),
      'costPrice': serializer.toJson<double>(costPrice),
      'sellingPrice': serializer.toJson<double>(sellingPrice),
      'taxRate': serializer.toJson<double>(taxRate),
      'unit': serializer.toJson<String>(unit),
      'currentStock': serializer.toJson<double>(currentStock),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  LocalProduct copyWith(
          {String? id,
          String? organizationId,
          Value<String?> categoryId = const Value.absent(),
          String? name,
          Value<String?> sku = const Value.absent(),
          Value<String?> barcode = const Value.absent(),
          double? costPrice,
          double? sellingPrice,
          double? taxRate,
          String? unit,
          double? currentStock,
          bool? isActive}) =>
      LocalProduct(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        name: name ?? this.name,
        sku: sku.present ? sku.value : this.sku,
        barcode: barcode.present ? barcode.value : this.barcode,
        costPrice: costPrice ?? this.costPrice,
        sellingPrice: sellingPrice ?? this.sellingPrice,
        taxRate: taxRate ?? this.taxRate,
        unit: unit ?? this.unit,
        currentStock: currentStock ?? this.currentStock,
        isActive: isActive ?? this.isActive,
      );
  LocalProduct copyWithCompanion(LocalProductsCompanion data) {
    return LocalProduct(
      id: data.id.present ? data.id.value : this.id,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
      sku: data.sku.present ? data.sku.value : this.sku,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      costPrice: data.costPrice.present ? data.costPrice.value : this.costPrice,
      sellingPrice: data.sellingPrice.present
          ? data.sellingPrice.value
          : this.sellingPrice,
      taxRate: data.taxRate.present ? data.taxRate.value : this.taxRate,
      unit: data.unit.present ? data.unit.value : this.unit,
      currentStock: data.currentStock.present
          ? data.currentStock.value
          : this.currentStock,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalProduct(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('costPrice: $costPrice, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('taxRate: $taxRate, ')
          ..write('unit: $unit, ')
          ..write('currentStock: $currentStock, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, organizationId, categoryId, name, sku,
      barcode, costPrice, sellingPrice, taxRate, unit, currentStock, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalProduct &&
          other.id == this.id &&
          other.organizationId == this.organizationId &&
          other.categoryId == this.categoryId &&
          other.name == this.name &&
          other.sku == this.sku &&
          other.barcode == this.barcode &&
          other.costPrice == this.costPrice &&
          other.sellingPrice == this.sellingPrice &&
          other.taxRate == this.taxRate &&
          other.unit == this.unit &&
          other.currentStock == this.currentStock &&
          other.isActive == this.isActive);
}

class LocalProductsCompanion extends UpdateCompanion<LocalProduct> {
  final Value<String> id;
  final Value<String> organizationId;
  final Value<String?> categoryId;
  final Value<String> name;
  final Value<String?> sku;
  final Value<String?> barcode;
  final Value<double> costPrice;
  final Value<double> sellingPrice;
  final Value<double> taxRate;
  final Value<String> unit;
  final Value<double> currentStock;
  final Value<bool> isActive;
  final Value<int> rowid;
  const LocalProductsCompanion({
    this.id = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.sellingPrice = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.unit = const Value.absent(),
    this.currentStock = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalProductsCompanion.insert({
    required String id,
    required String organizationId,
    this.categoryId = const Value.absent(),
    required String name,
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.sellingPrice = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.unit = const Value.absent(),
    this.currentStock = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        organizationId = Value(organizationId),
        name = Value(name);
  static Insertable<LocalProduct> custom({
    Expression<String>? id,
    Expression<String>? organizationId,
    Expression<String>? categoryId,
    Expression<String>? name,
    Expression<String>? sku,
    Expression<String>? barcode,
    Expression<double>? costPrice,
    Expression<double>? sellingPrice,
    Expression<double>? taxRate,
    Expression<String>? unit,
    Expression<double>? currentStock,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (organizationId != null) 'organization_id': organizationId,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
      if (costPrice != null) 'cost_price': costPrice,
      if (sellingPrice != null) 'selling_price': sellingPrice,
      if (taxRate != null) 'tax_rate': taxRate,
      if (unit != null) 'unit': unit,
      if (currentStock != null) 'current_stock': currentStock,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalProductsCompanion copyWith(
      {Value<String>? id,
      Value<String>? organizationId,
      Value<String?>? categoryId,
      Value<String>? name,
      Value<String?>? sku,
      Value<String?>? barcode,
      Value<double>? costPrice,
      Value<double>? sellingPrice,
      Value<double>? taxRate,
      Value<String>? unit,
      Value<double>? currentStock,
      Value<bool>? isActive,
      Value<int>? rowid}) {
    return LocalProductsCompanion(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      taxRate: taxRate ?? this.taxRate,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (costPrice.present) {
      map['cost_price'] = Variable<double>(costPrice.value);
    }
    if (sellingPrice.present) {
      map['selling_price'] = Variable<double>(sellingPrice.value);
    }
    if (taxRate.present) {
      map['tax_rate'] = Variable<double>(taxRate.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (currentStock.present) {
      map['current_stock'] = Variable<double>(currentStock.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalProductsCompanion(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('costPrice: $costPrice, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('taxRate: $taxRate, ')
          ..write('unit: $unit, ')
          ..write('currentStock: $currentStock, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSalesTable extends LocalSales
    with TableInfo<$LocalSalesTable, LocalSale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _organizationIdMeta =
      const VerificationMeta('organizationId');
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
      'organization_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _receiptNumberMeta =
      const VerificationMeta('receiptNumber');
  @override
  late final GeneratedColumn<String> receiptNumber = GeneratedColumn<String>(
      'receipt_number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cashierIdMeta =
      const VerificationMeta('cashierId');
  @override
  late final GeneratedColumn<String> cashierId = GeneratedColumn<String>(
      'cashier_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customerNameMeta =
      const VerificationMeta('customerName');
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
      'customer_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customerPhoneMeta =
      const VerificationMeta('customerPhone');
  @override
  late final GeneratedColumn<String> customerPhone = GeneratedColumn<String>(
      'customer_phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _subtotalMeta =
      const VerificationMeta('subtotal');
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
      'subtotal', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _discountMeta =
      const VerificationMeta('discount');
  @override
  late final GeneratedColumn<double> discount = GeneratedColumn<double>(
      'discount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _taxAmountMeta =
      const VerificationMeta('taxAmount');
  @override
  late final GeneratedColumn<double> taxAmount = GeneratedColumn<double>(
      'tax_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _totalAmountMeta =
      const VerificationMeta('totalAmount');
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
      'total_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _paymentMethodMeta =
      const VerificationMeta('paymentMethod');
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
      'payment_method', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('cash'));
  static const VerificationMeta _mpesaReceiptNumberMeta =
      const VerificationMeta('mpesaReceiptNumber');
  @override
  late final GeneratedColumn<String> mpesaReceiptNumber =
      GeneratedColumn<String>('mpesa_receipt_number', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _paymentStatusMeta =
      const VerificationMeta('paymentStatus');
  @override
  late final GeneratedColumn<String> paymentStatus = GeneratedColumn<String>(
      'payment_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('completed'));
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('synced'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        organizationId,
        branchId,
        receiptNumber,
        cashierId,
        customerName,
        customerPhone,
        subtotal,
        discount,
        taxAmount,
        totalAmount,
        paymentMethod,
        mpesaReceiptNumber,
        paymentStatus,
        syncStatus,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sales';
  @override
  VerificationContext validateIntegrity(Insertable<LocalSale> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('organization_id')) {
      context.handle(
          _organizationIdMeta,
          organizationId.isAcceptableOrUnknown(
              data['organization_id']!, _organizationIdMeta));
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('receipt_number')) {
      context.handle(
          _receiptNumberMeta,
          receiptNumber.isAcceptableOrUnknown(
              data['receipt_number']!, _receiptNumberMeta));
    } else if (isInserting) {
      context.missing(_receiptNumberMeta);
    }
    if (data.containsKey('cashier_id')) {
      context.handle(_cashierIdMeta,
          cashierId.isAcceptableOrUnknown(data['cashier_id']!, _cashierIdMeta));
    }
    if (data.containsKey('customer_name')) {
      context.handle(
          _customerNameMeta,
          customerName.isAcceptableOrUnknown(
              data['customer_name']!, _customerNameMeta));
    }
    if (data.containsKey('customer_phone')) {
      context.handle(
          _customerPhoneMeta,
          customerPhone.isAcceptableOrUnknown(
              data['customer_phone']!, _customerPhoneMeta));
    }
    if (data.containsKey('subtotal')) {
      context.handle(_subtotalMeta,
          subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta));
    }
    if (data.containsKey('discount')) {
      context.handle(_discountMeta,
          discount.isAcceptableOrUnknown(data['discount']!, _discountMeta));
    }
    if (data.containsKey('tax_amount')) {
      context.handle(_taxAmountMeta,
          taxAmount.isAcceptableOrUnknown(data['tax_amount']!, _taxAmountMeta));
    }
    if (data.containsKey('total_amount')) {
      context.handle(
          _totalAmountMeta,
          totalAmount.isAcceptableOrUnknown(
              data['total_amount']!, _totalAmountMeta));
    }
    if (data.containsKey('payment_method')) {
      context.handle(
          _paymentMethodMeta,
          paymentMethod.isAcceptableOrUnknown(
              data['payment_method']!, _paymentMethodMeta));
    }
    if (data.containsKey('mpesa_receipt_number')) {
      context.handle(
          _mpesaReceiptNumberMeta,
          mpesaReceiptNumber.isAcceptableOrUnknown(
              data['mpesa_receipt_number']!, _mpesaReceiptNumberMeta));
    }
    if (data.containsKey('payment_status')) {
      context.handle(
          _paymentStatusMeta,
          paymentStatus.isAcceptableOrUnknown(
              data['payment_status']!, _paymentStatusMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSale(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      organizationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}organization_id'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch_id'])!,
      receiptNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}receipt_number'])!,
      cashierId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cashier_id']),
      customerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_name']),
      customerPhone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_phone']),
      subtotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}subtotal'])!,
      discount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}discount'])!,
      taxAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tax_amount'])!,
      totalAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_amount'])!,
      paymentMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_method'])!,
      mpesaReceiptNumber: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}mpesa_receipt_number']),
      paymentStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_status'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $LocalSalesTable createAlias(String alias) {
    return $LocalSalesTable(attachedDatabase, alias);
  }
}

class LocalSale extends DataClass implements Insertable<LocalSale> {
  final String id;
  final String organizationId;
  final String branchId;
  final String receiptNumber;
  final String? cashierId;
  final String? customerName;
  final String? customerPhone;
  final double subtotal;
  final double discount;
  final double taxAmount;
  final double totalAmount;
  final String paymentMethod;
  final String? mpesaReceiptNumber;
  final String paymentStatus;
  final String syncStatus;
  final DateTime createdAt;
  const LocalSale(
      {required this.id,
      required this.organizationId,
      required this.branchId,
      required this.receiptNumber,
      this.cashierId,
      this.customerName,
      this.customerPhone,
      required this.subtotal,
      required this.discount,
      required this.taxAmount,
      required this.totalAmount,
      required this.paymentMethod,
      this.mpesaReceiptNumber,
      required this.paymentStatus,
      required this.syncStatus,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['organization_id'] = Variable<String>(organizationId);
    map['branch_id'] = Variable<String>(branchId);
    map['receipt_number'] = Variable<String>(receiptNumber);
    if (!nullToAbsent || cashierId != null) {
      map['cashier_id'] = Variable<String>(cashierId);
    }
    if (!nullToAbsent || customerName != null) {
      map['customer_name'] = Variable<String>(customerName);
    }
    if (!nullToAbsent || customerPhone != null) {
      map['customer_phone'] = Variable<String>(customerPhone);
    }
    map['subtotal'] = Variable<double>(subtotal);
    map['discount'] = Variable<double>(discount);
    map['tax_amount'] = Variable<double>(taxAmount);
    map['total_amount'] = Variable<double>(totalAmount);
    map['payment_method'] = Variable<String>(paymentMethod);
    if (!nullToAbsent || mpesaReceiptNumber != null) {
      map['mpesa_receipt_number'] = Variable<String>(mpesaReceiptNumber);
    }
    map['payment_status'] = Variable<String>(paymentStatus);
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalSalesCompanion toCompanion(bool nullToAbsent) {
    return LocalSalesCompanion(
      id: Value(id),
      organizationId: Value(organizationId),
      branchId: Value(branchId),
      receiptNumber: Value(receiptNumber),
      cashierId: cashierId == null && nullToAbsent
          ? const Value.absent()
          : Value(cashierId),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      customerPhone: customerPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(customerPhone),
      subtotal: Value(subtotal),
      discount: Value(discount),
      taxAmount: Value(taxAmount),
      totalAmount: Value(totalAmount),
      paymentMethod: Value(paymentMethod),
      mpesaReceiptNumber: mpesaReceiptNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(mpesaReceiptNumber),
      paymentStatus: Value(paymentStatus),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
    );
  }

  factory LocalSale.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSale(
      id: serializer.fromJson<String>(json['id']),
      organizationId: serializer.fromJson<String>(json['organizationId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      receiptNumber: serializer.fromJson<String>(json['receiptNumber']),
      cashierId: serializer.fromJson<String?>(json['cashierId']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      customerPhone: serializer.fromJson<String?>(json['customerPhone']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      discount: serializer.fromJson<double>(json['discount']),
      taxAmount: serializer.fromJson<double>(json['taxAmount']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      mpesaReceiptNumber:
          serializer.fromJson<String?>(json['mpesaReceiptNumber']),
      paymentStatus: serializer.fromJson<String>(json['paymentStatus']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'organizationId': serializer.toJson<String>(organizationId),
      'branchId': serializer.toJson<String>(branchId),
      'receiptNumber': serializer.toJson<String>(receiptNumber),
      'cashierId': serializer.toJson<String?>(cashierId),
      'customerName': serializer.toJson<String?>(customerName),
      'customerPhone': serializer.toJson<String?>(customerPhone),
      'subtotal': serializer.toJson<double>(subtotal),
      'discount': serializer.toJson<double>(discount),
      'taxAmount': serializer.toJson<double>(taxAmount),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'mpesaReceiptNumber': serializer.toJson<String?>(mpesaReceiptNumber),
      'paymentStatus': serializer.toJson<String>(paymentStatus),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalSale copyWith(
          {String? id,
          String? organizationId,
          String? branchId,
          String? receiptNumber,
          Value<String?> cashierId = const Value.absent(),
          Value<String?> customerName = const Value.absent(),
          Value<String?> customerPhone = const Value.absent(),
          double? subtotal,
          double? discount,
          double? taxAmount,
          double? totalAmount,
          String? paymentMethod,
          Value<String?> mpesaReceiptNumber = const Value.absent(),
          String? paymentStatus,
          String? syncStatus,
          DateTime? createdAt}) =>
      LocalSale(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        branchId: branchId ?? this.branchId,
        receiptNumber: receiptNumber ?? this.receiptNumber,
        cashierId: cashierId.present ? cashierId.value : this.cashierId,
        customerName:
            customerName.present ? customerName.value : this.customerName,
        customerPhone:
            customerPhone.present ? customerPhone.value : this.customerPhone,
        subtotal: subtotal ?? this.subtotal,
        discount: discount ?? this.discount,
        taxAmount: taxAmount ?? this.taxAmount,
        totalAmount: totalAmount ?? this.totalAmount,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        mpesaReceiptNumber: mpesaReceiptNumber.present
            ? mpesaReceiptNumber.value
            : this.mpesaReceiptNumber,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
      );
  LocalSale copyWithCompanion(LocalSalesCompanion data) {
    return LocalSale(
      id: data.id.present ? data.id.value : this.id,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      receiptNumber: data.receiptNumber.present
          ? data.receiptNumber.value
          : this.receiptNumber,
      cashierId: data.cashierId.present ? data.cashierId.value : this.cashierId,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      customerPhone: data.customerPhone.present
          ? data.customerPhone.value
          : this.customerPhone,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      discount: data.discount.present ? data.discount.value : this.discount,
      taxAmount: data.taxAmount.present ? data.taxAmount.value : this.taxAmount,
      totalAmount:
          data.totalAmount.present ? data.totalAmount.value : this.totalAmount,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      mpesaReceiptNumber: data.mpesaReceiptNumber.present
          ? data.mpesaReceiptNumber.value
          : this.mpesaReceiptNumber,
      paymentStatus: data.paymentStatus.present
          ? data.paymentStatus.value
          : this.paymentStatus,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSale(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('branchId: $branchId, ')
          ..write('receiptNumber: $receiptNumber, ')
          ..write('cashierId: $cashierId, ')
          ..write('customerName: $customerName, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('subtotal: $subtotal, ')
          ..write('discount: $discount, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('mpesaReceiptNumber: $mpesaReceiptNumber, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      organizationId,
      branchId,
      receiptNumber,
      cashierId,
      customerName,
      customerPhone,
      subtotal,
      discount,
      taxAmount,
      totalAmount,
      paymentMethod,
      mpesaReceiptNumber,
      paymentStatus,
      syncStatus,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSale &&
          other.id == this.id &&
          other.organizationId == this.organizationId &&
          other.branchId == this.branchId &&
          other.receiptNumber == this.receiptNumber &&
          other.cashierId == this.cashierId &&
          other.customerName == this.customerName &&
          other.customerPhone == this.customerPhone &&
          other.subtotal == this.subtotal &&
          other.discount == this.discount &&
          other.taxAmount == this.taxAmount &&
          other.totalAmount == this.totalAmount &&
          other.paymentMethod == this.paymentMethod &&
          other.mpesaReceiptNumber == this.mpesaReceiptNumber &&
          other.paymentStatus == this.paymentStatus &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt);
}

class LocalSalesCompanion extends UpdateCompanion<LocalSale> {
  final Value<String> id;
  final Value<String> organizationId;
  final Value<String> branchId;
  final Value<String> receiptNumber;
  final Value<String?> cashierId;
  final Value<String?> customerName;
  final Value<String?> customerPhone;
  final Value<double> subtotal;
  final Value<double> discount;
  final Value<double> taxAmount;
  final Value<double> totalAmount;
  final Value<String> paymentMethod;
  final Value<String?> mpesaReceiptNumber;
  final Value<String> paymentStatus;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalSalesCompanion({
    this.id = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.receiptNumber = const Value.absent(),
    this.cashierId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerPhone = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.discount = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.mpesaReceiptNumber = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSalesCompanion.insert({
    required String id,
    required String organizationId,
    required String branchId,
    required String receiptNumber,
    this.cashierId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerPhone = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.discount = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.mpesaReceiptNumber = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        organizationId = Value(organizationId),
        branchId = Value(branchId),
        receiptNumber = Value(receiptNumber),
        createdAt = Value(createdAt);
  static Insertable<LocalSale> custom({
    Expression<String>? id,
    Expression<String>? organizationId,
    Expression<String>? branchId,
    Expression<String>? receiptNumber,
    Expression<String>? cashierId,
    Expression<String>? customerName,
    Expression<String>? customerPhone,
    Expression<double>? subtotal,
    Expression<double>? discount,
    Expression<double>? taxAmount,
    Expression<double>? totalAmount,
    Expression<String>? paymentMethod,
    Expression<String>? mpesaReceiptNumber,
    Expression<String>? paymentStatus,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (organizationId != null) 'organization_id': organizationId,
      if (branchId != null) 'branch_id': branchId,
      if (receiptNumber != null) 'receipt_number': receiptNumber,
      if (cashierId != null) 'cashier_id': cashierId,
      if (customerName != null) 'customer_name': customerName,
      if (customerPhone != null) 'customer_phone': customerPhone,
      if (subtotal != null) 'subtotal': subtotal,
      if (discount != null) 'discount': discount,
      if (taxAmount != null) 'tax_amount': taxAmount,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (mpesaReceiptNumber != null)
        'mpesa_receipt_number': mpesaReceiptNumber,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSalesCompanion copyWith(
      {Value<String>? id,
      Value<String>? organizationId,
      Value<String>? branchId,
      Value<String>? receiptNumber,
      Value<String?>? cashierId,
      Value<String?>? customerName,
      Value<String?>? customerPhone,
      Value<double>? subtotal,
      Value<double>? discount,
      Value<double>? taxAmount,
      Value<double>? totalAmount,
      Value<String>? paymentMethod,
      Value<String?>? mpesaReceiptNumber,
      Value<String>? paymentStatus,
      Value<String>? syncStatus,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return LocalSalesCompanion(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      branchId: branchId ?? this.branchId,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      cashierId: cashierId ?? this.cashierId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      mpesaReceiptNumber: mpesaReceiptNumber ?? this.mpesaReceiptNumber,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (receiptNumber.present) {
      map['receipt_number'] = Variable<String>(receiptNumber.value);
    }
    if (cashierId.present) {
      map['cashier_id'] = Variable<String>(cashierId.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (customerPhone.present) {
      map['customer_phone'] = Variable<String>(customerPhone.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (discount.present) {
      map['discount'] = Variable<double>(discount.value);
    }
    if (taxAmount.present) {
      map['tax_amount'] = Variable<double>(taxAmount.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (mpesaReceiptNumber.present) {
      map['mpesa_receipt_number'] = Variable<String>(mpesaReceiptNumber.value);
    }
    if (paymentStatus.present) {
      map['payment_status'] = Variable<String>(paymentStatus.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSalesCompanion(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('branchId: $branchId, ')
          ..write('receiptNumber: $receiptNumber, ')
          ..write('cashierId: $cashierId, ')
          ..write('customerName: $customerName, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('subtotal: $subtotal, ')
          ..write('discount: $discount, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('mpesaReceiptNumber: $mpesaReceiptNumber, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalExpensesTable extends LocalExpenses
    with TableInfo<$LocalExpensesTable, LocalExpense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _organizationIdMeta =
      const VerificationMeta('organizationId');
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
      'organization_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _paymentMethodMeta =
      const VerificationMeta('paymentMethod');
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
      'payment_method', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('cash'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        organizationId,
        branchId,
        category,
        description,
        amount,
        paymentMethod,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_expenses';
  @override
  VerificationContext validateIntegrity(Insertable<LocalExpense> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('organization_id')) {
      context.handle(
          _organizationIdMeta,
          organizationId.isAcceptableOrUnknown(
              data['organization_id']!, _organizationIdMeta));
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
          _paymentMethodMeta,
          paymentMethod.isAcceptableOrUnknown(
              data['payment_method']!, _paymentMethodMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalExpense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalExpense(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      organizationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}organization_id'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch_id'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      paymentMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_method'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $LocalExpensesTable createAlias(String alias) {
    return $LocalExpensesTable(attachedDatabase, alias);
  }
}

class LocalExpense extends DataClass implements Insertable<LocalExpense> {
  final String id;
  final String organizationId;
  final String branchId;
  final String category;
  final String description;
  final double amount;
  final String paymentMethod;
  final DateTime createdAt;
  const LocalExpense(
      {required this.id,
      required this.organizationId,
      required this.branchId,
      required this.category,
      required this.description,
      required this.amount,
      required this.paymentMethod,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['organization_id'] = Variable<String>(organizationId);
    map['branch_id'] = Variable<String>(branchId);
    map['category'] = Variable<String>(category);
    map['description'] = Variable<String>(description);
    map['amount'] = Variable<double>(amount);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalExpensesCompanion toCompanion(bool nullToAbsent) {
    return LocalExpensesCompanion(
      id: Value(id),
      organizationId: Value(organizationId),
      branchId: Value(branchId),
      category: Value(category),
      description: Value(description),
      amount: Value(amount),
      paymentMethod: Value(paymentMethod),
      createdAt: Value(createdAt),
    );
  }

  factory LocalExpense.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalExpense(
      id: serializer.fromJson<String>(json['id']),
      organizationId: serializer.fromJson<String>(json['organizationId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      category: serializer.fromJson<String>(json['category']),
      description: serializer.fromJson<String>(json['description']),
      amount: serializer.fromJson<double>(json['amount']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'organizationId': serializer.toJson<String>(organizationId),
      'branchId': serializer.toJson<String>(branchId),
      'category': serializer.toJson<String>(category),
      'description': serializer.toJson<String>(description),
      'amount': serializer.toJson<double>(amount),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalExpense copyWith(
          {String? id,
          String? organizationId,
          String? branchId,
          String? category,
          String? description,
          double? amount,
          String? paymentMethod,
          DateTime? createdAt}) =>
      LocalExpense(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        branchId: branchId ?? this.branchId,
        category: category ?? this.category,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        createdAt: createdAt ?? this.createdAt,
      );
  LocalExpense copyWithCompanion(LocalExpensesCompanion data) {
    return LocalExpense(
      id: data.id.present ? data.id.value : this.id,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      category: data.category.present ? data.category.value : this.category,
      description:
          data.description.present ? data.description.value : this.description,
      amount: data.amount.present ? data.amount.value : this.amount,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalExpense(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('branchId: $branchId, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('amount: $amount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, organizationId, branchId, category,
      description, amount, paymentMethod, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalExpense &&
          other.id == this.id &&
          other.organizationId == this.organizationId &&
          other.branchId == this.branchId &&
          other.category == this.category &&
          other.description == this.description &&
          other.amount == this.amount &&
          other.paymentMethod == this.paymentMethod &&
          other.createdAt == this.createdAt);
}

class LocalExpensesCompanion extends UpdateCompanion<LocalExpense> {
  final Value<String> id;
  final Value<String> organizationId;
  final Value<String> branchId;
  final Value<String> category;
  final Value<String> description;
  final Value<double> amount;
  final Value<String> paymentMethod;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalExpensesCompanion({
    this.id = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.amount = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalExpensesCompanion.insert({
    required String id,
    required String organizationId,
    required String branchId,
    required String category,
    required String description,
    required double amount,
    this.paymentMethod = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        organizationId = Value(organizationId),
        branchId = Value(branchId),
        category = Value(category),
        description = Value(description),
        amount = Value(amount),
        createdAt = Value(createdAt);
  static Insertable<LocalExpense> custom({
    Expression<String>? id,
    Expression<String>? organizationId,
    Expression<String>? branchId,
    Expression<String>? category,
    Expression<String>? description,
    Expression<double>? amount,
    Expression<String>? paymentMethod,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (organizationId != null) 'organization_id': organizationId,
      if (branchId != null) 'branch_id': branchId,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (amount != null) 'amount': amount,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalExpensesCompanion copyWith(
      {Value<String>? id,
      Value<String>? organizationId,
      Value<String>? branchId,
      Value<String>? category,
      Value<String>? description,
      Value<double>? amount,
      Value<String>? paymentMethod,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return LocalExpensesCompanion(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      branchId: branchId ?? this.branchId,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalExpensesCompanion(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('branchId: $branchId, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('amount: $amount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalTablesTable extends LocalTables
    with TableInfo<$LocalTablesTable, LocalTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTablesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _organizationIdMeta =
      const VerificationMeta('organizationId');
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
      'organization_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tableNumberMeta =
      const VerificationMeta('tableNumber');
  @override
  late final GeneratedColumn<String> tableNumber = GeneratedColumn<String>(
      'table_number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _capacityMeta =
      const VerificationMeta('capacity');
  @override
  late final GeneratedColumn<int> capacity = GeneratedColumn<int>(
      'capacity', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(4));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('available'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, organizationId, branchId, tableNumber, capacity, status];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_tables';
  @override
  VerificationContext validateIntegrity(Insertable<LocalTable> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('organization_id')) {
      context.handle(
          _organizationIdMeta,
          organizationId.isAcceptableOrUnknown(
              data['organization_id']!, _organizationIdMeta));
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('table_number')) {
      context.handle(
          _tableNumberMeta,
          tableNumber.isAcceptableOrUnknown(
              data['table_number']!, _tableNumberMeta));
    } else if (isInserting) {
      context.missing(_tableNumberMeta);
    }
    if (data.containsKey('capacity')) {
      context.handle(_capacityMeta,
          capacity.isAcceptableOrUnknown(data['capacity']!, _capacityMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTable(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      organizationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}organization_id'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch_id'])!,
      tableNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}table_number'])!,
      capacity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}capacity'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
    );
  }

  @override
  $LocalTablesTable createAlias(String alias) {
    return $LocalTablesTable(attachedDatabase, alias);
  }
}

class LocalTable extends DataClass implements Insertable<LocalTable> {
  final String id;
  final String organizationId;
  final String branchId;
  final String tableNumber;
  final int capacity;
  final String status;
  const LocalTable(
      {required this.id,
      required this.organizationId,
      required this.branchId,
      required this.tableNumber,
      required this.capacity,
      required this.status});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['organization_id'] = Variable<String>(organizationId);
    map['branch_id'] = Variable<String>(branchId);
    map['table_number'] = Variable<String>(tableNumber);
    map['capacity'] = Variable<int>(capacity);
    map['status'] = Variable<String>(status);
    return map;
  }

  LocalTablesCompanion toCompanion(bool nullToAbsent) {
    return LocalTablesCompanion(
      id: Value(id),
      organizationId: Value(organizationId),
      branchId: Value(branchId),
      tableNumber: Value(tableNumber),
      capacity: Value(capacity),
      status: Value(status),
    );
  }

  factory LocalTable.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTable(
      id: serializer.fromJson<String>(json['id']),
      organizationId: serializer.fromJson<String>(json['organizationId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      tableNumber: serializer.fromJson<String>(json['tableNumber']),
      capacity: serializer.fromJson<int>(json['capacity']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'organizationId': serializer.toJson<String>(organizationId),
      'branchId': serializer.toJson<String>(branchId),
      'tableNumber': serializer.toJson<String>(tableNumber),
      'capacity': serializer.toJson<int>(capacity),
      'status': serializer.toJson<String>(status),
    };
  }

  LocalTable copyWith(
          {String? id,
          String? organizationId,
          String? branchId,
          String? tableNumber,
          int? capacity,
          String? status}) =>
      LocalTable(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        branchId: branchId ?? this.branchId,
        tableNumber: tableNumber ?? this.tableNumber,
        capacity: capacity ?? this.capacity,
        status: status ?? this.status,
      );
  LocalTable copyWithCompanion(LocalTablesCompanion data) {
    return LocalTable(
      id: data.id.present ? data.id.value : this.id,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      tableNumber:
          data.tableNumber.present ? data.tableNumber.value : this.tableNumber,
      capacity: data.capacity.present ? data.capacity.value : this.capacity,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTable(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('branchId: $branchId, ')
          ..write('tableNumber: $tableNumber, ')
          ..write('capacity: $capacity, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, organizationId, branchId, tableNumber, capacity, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTable &&
          other.id == this.id &&
          other.organizationId == this.organizationId &&
          other.branchId == this.branchId &&
          other.tableNumber == this.tableNumber &&
          other.capacity == this.capacity &&
          other.status == this.status);
}

class LocalTablesCompanion extends UpdateCompanion<LocalTable> {
  final Value<String> id;
  final Value<String> organizationId;
  final Value<String> branchId;
  final Value<String> tableNumber;
  final Value<int> capacity;
  final Value<String> status;
  final Value<int> rowid;
  const LocalTablesCompanion({
    this.id = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.tableNumber = const Value.absent(),
    this.capacity = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTablesCompanion.insert({
    required String id,
    required String organizationId,
    required String branchId,
    required String tableNumber,
    this.capacity = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        organizationId = Value(organizationId),
        branchId = Value(branchId),
        tableNumber = Value(tableNumber);
  static Insertable<LocalTable> custom({
    Expression<String>? id,
    Expression<String>? organizationId,
    Expression<String>? branchId,
    Expression<String>? tableNumber,
    Expression<int>? capacity,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (organizationId != null) 'organization_id': organizationId,
      if (branchId != null) 'branch_id': branchId,
      if (tableNumber != null) 'table_number': tableNumber,
      if (capacity != null) 'capacity': capacity,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTablesCompanion copyWith(
      {Value<String>? id,
      Value<String>? organizationId,
      Value<String>? branchId,
      Value<String>? tableNumber,
      Value<int>? capacity,
      Value<String>? status,
      Value<int>? rowid}) {
    return LocalTablesCompanion(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      branchId: branchId ?? this.branchId,
      tableNumber: tableNumber ?? this.tableNumber,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (tableNumber.present) {
      map['table_number'] = Variable<String>(tableNumber.value);
    }
    if (capacity.present) {
      map['capacity'] = Variable<int>(capacity.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTablesCompanion(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('branchId: $branchId, ')
          ..write('tableNumber: $tableNumber, ')
          ..write('capacity: $capacity, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalUsersTable extends LocalUsers
    with TableInfo<$LocalUsersTable, LocalUser> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalUsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _organizationIdMeta =
      const VerificationMeta('organizationId');
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
      'organization_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
      'branch_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fullNameMeta =
      const VerificationMeta('fullName');
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
      'full_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pinCodeMeta =
      const VerificationMeta('pinCode');
  @override
  late final GeneratedColumn<String> pinCode = GeneratedColumn<String>(
      'pin_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns =>
      [id, organizationId, branchId, email, fullName, pinCode, role, isActive];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_users';
  @override
  VerificationContext validateIntegrity(Insertable<LocalUser> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('organization_id')) {
      context.handle(
          _organizationIdMeta,
          organizationId.isAcceptableOrUnknown(
              data['organization_id']!, _organizationIdMeta));
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(_fullNameMeta,
          fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta));
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('pin_code')) {
      context.handle(_pinCodeMeta,
          pinCode.isAcceptableOrUnknown(data['pin_code']!, _pinCodeMeta));
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalUser map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalUser(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      organizationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}organization_id'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch_id']),
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      fullName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}full_name'])!,
      pinCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pin_code']),
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
    );
  }

  @override
  $LocalUsersTable createAlias(String alias) {
    return $LocalUsersTable(attachedDatabase, alias);
  }
}

class LocalUser extends DataClass implements Insertable<LocalUser> {
  final String id;
  final String organizationId;
  final String? branchId;
  final String email;
  final String fullName;
  final String? pinCode;
  final String role;
  final bool isActive;
  const LocalUser(
      {required this.id,
      required this.organizationId,
      this.branchId,
      required this.email,
      required this.fullName,
      this.pinCode,
      required this.role,
      required this.isActive});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['organization_id'] = Variable<String>(organizationId);
    if (!nullToAbsent || branchId != null) {
      map['branch_id'] = Variable<String>(branchId);
    }
    map['email'] = Variable<String>(email);
    map['full_name'] = Variable<String>(fullName);
    if (!nullToAbsent || pinCode != null) {
      map['pin_code'] = Variable<String>(pinCode);
    }
    map['role'] = Variable<String>(role);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  LocalUsersCompanion toCompanion(bool nullToAbsent) {
    return LocalUsersCompanion(
      id: Value(id),
      organizationId: Value(organizationId),
      branchId: branchId == null && nullToAbsent
          ? const Value.absent()
          : Value(branchId),
      email: Value(email),
      fullName: Value(fullName),
      pinCode: pinCode == null && nullToAbsent
          ? const Value.absent()
          : Value(pinCode),
      role: Value(role),
      isActive: Value(isActive),
    );
  }

  factory LocalUser.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalUser(
      id: serializer.fromJson<String>(json['id']),
      organizationId: serializer.fromJson<String>(json['organizationId']),
      branchId: serializer.fromJson<String?>(json['branchId']),
      email: serializer.fromJson<String>(json['email']),
      fullName: serializer.fromJson<String>(json['fullName']),
      pinCode: serializer.fromJson<String?>(json['pinCode']),
      role: serializer.fromJson<String>(json['role']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'organizationId': serializer.toJson<String>(organizationId),
      'branchId': serializer.toJson<String?>(branchId),
      'email': serializer.toJson<String>(email),
      'fullName': serializer.toJson<String>(fullName),
      'pinCode': serializer.toJson<String?>(pinCode),
      'role': serializer.toJson<String>(role),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  LocalUser copyWith(
          {String? id,
          String? organizationId,
          Value<String?> branchId = const Value.absent(),
          String? email,
          String? fullName,
          Value<String?> pinCode = const Value.absent(),
          String? role,
          bool? isActive}) =>
      LocalUser(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        branchId: branchId.present ? branchId.value : this.branchId,
        email: email ?? this.email,
        fullName: fullName ?? this.fullName,
        pinCode: pinCode.present ? pinCode.value : this.pinCode,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
      );
  LocalUser copyWithCompanion(LocalUsersCompanion data) {
    return LocalUser(
      id: data.id.present ? data.id.value : this.id,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      email: data.email.present ? data.email.value : this.email,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      pinCode: data.pinCode.present ? data.pinCode.value : this.pinCode,
      role: data.role.present ? data.role.value : this.role,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalUser(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('branchId: $branchId, ')
          ..write('email: $email, ')
          ..write('fullName: $fullName, ')
          ..write('pinCode: $pinCode, ')
          ..write('role: $role, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, organizationId, branchId, email, fullName, pinCode, role, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalUser &&
          other.id == this.id &&
          other.organizationId == this.organizationId &&
          other.branchId == this.branchId &&
          other.email == this.email &&
          other.fullName == this.fullName &&
          other.pinCode == this.pinCode &&
          other.role == this.role &&
          other.isActive == this.isActive);
}

class LocalUsersCompanion extends UpdateCompanion<LocalUser> {
  final Value<String> id;
  final Value<String> organizationId;
  final Value<String?> branchId;
  final Value<String> email;
  final Value<String> fullName;
  final Value<String?> pinCode;
  final Value<String> role;
  final Value<bool> isActive;
  final Value<int> rowid;
  const LocalUsersCompanion({
    this.id = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.email = const Value.absent(),
    this.fullName = const Value.absent(),
    this.pinCode = const Value.absent(),
    this.role = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalUsersCompanion.insert({
    required String id,
    required String organizationId,
    this.branchId = const Value.absent(),
    required String email,
    required String fullName,
    this.pinCode = const Value.absent(),
    required String role,
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        organizationId = Value(organizationId),
        email = Value(email),
        fullName = Value(fullName),
        role = Value(role);
  static Insertable<LocalUser> custom({
    Expression<String>? id,
    Expression<String>? organizationId,
    Expression<String>? branchId,
    Expression<String>? email,
    Expression<String>? fullName,
    Expression<String>? pinCode,
    Expression<String>? role,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (organizationId != null) 'organization_id': organizationId,
      if (branchId != null) 'branch_id': branchId,
      if (email != null) 'email': email,
      if (fullName != null) 'full_name': fullName,
      if (pinCode != null) 'pin_code': pinCode,
      if (role != null) 'role': role,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalUsersCompanion copyWith(
      {Value<String>? id,
      Value<String>? organizationId,
      Value<String?>? branchId,
      Value<String>? email,
      Value<String>? fullName,
      Value<String?>? pinCode,
      Value<String>? role,
      Value<bool>? isActive,
      Value<int>? rowid}) {
    return LocalUsersCompanion(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      branchId: branchId ?? this.branchId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      pinCode: pinCode ?? this.pinCode,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (pinCode.present) {
      map['pin_code'] = Variable<String>(pinCode.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalUsersCompanion(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('branchId: $branchId, ')
          ..write('email: $email, ')
          ..write('fullName: $fullName, ')
          ..write('pinCode: $pinCode, ')
          ..write('role: $role, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalOrganizationsTable localOrganizations =
      $LocalOrganizationsTable(this);
  late final $LocalBranchesTable localBranches = $LocalBranchesTable(this);
  late final $LocalBranchModulesTable localBranchModules =
      $LocalBranchModulesTable(this);
  late final $LocalCategoriesTable localCategories =
      $LocalCategoriesTable(this);
  late final $LocalProductsTable localProducts = $LocalProductsTable(this);
  late final $LocalSalesTable localSales = $LocalSalesTable(this);
  late final $LocalExpensesTable localExpenses = $LocalExpensesTable(this);
  late final $LocalTablesTable localTables = $LocalTablesTable(this);
  late final $LocalUsersTable localUsers = $LocalUsersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        localOrganizations,
        localBranches,
        localBranchModules,
        localCategories,
        localProducts,
        localSales,
        localExpenses,
        localTables,
        localUsers
      ];
}

typedef $$LocalOrganizationsTableCreateCompanionBuilder
    = LocalOrganizationsCompanion Function({
  required String id,
  required String name,
  required String businessType,
  required String ownerName,
  required String phoneNumber,
  Value<String> plan,
  Value<String> billingStatus,
  Value<String?> licenseKey,
  Value<DateTime?> trialEndsAt,
  Value<int> rowid,
});
typedef $$LocalOrganizationsTableUpdateCompanionBuilder
    = LocalOrganizationsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> businessType,
  Value<String> ownerName,
  Value<String> phoneNumber,
  Value<String> plan,
  Value<String> billingStatus,
  Value<String?> licenseKey,
  Value<DateTime?> trialEndsAt,
  Value<int> rowid,
});

class $$LocalOrganizationsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalOrganizationsTable> {
  $$LocalOrganizationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get businessType => $composableBuilder(
      column: $table.businessType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerName => $composableBuilder(
      column: $table.ownerName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get plan => $composableBuilder(
      column: $table.plan, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get billingStatus => $composableBuilder(
      column: $table.billingStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get licenseKey => $composableBuilder(
      column: $table.licenseKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get trialEndsAt => $composableBuilder(
      column: $table.trialEndsAt, builder: (column) => ColumnFilters(column));
}

class $$LocalOrganizationsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalOrganizationsTable> {
  $$LocalOrganizationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get businessType => $composableBuilder(
      column: $table.businessType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerName => $composableBuilder(
      column: $table.ownerName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get plan => $composableBuilder(
      column: $table.plan, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get billingStatus => $composableBuilder(
      column: $table.billingStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get licenseKey => $composableBuilder(
      column: $table.licenseKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get trialEndsAt => $composableBuilder(
      column: $table.trialEndsAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalOrganizationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalOrganizationsTable> {
  $$LocalOrganizationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get businessType => $composableBuilder(
      column: $table.businessType, builder: (column) => column);

  GeneratedColumn<String> get ownerName =>
      $composableBuilder(column: $table.ownerName, builder: (column) => column);

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => column);

  GeneratedColumn<String> get plan =>
      $composableBuilder(column: $table.plan, builder: (column) => column);

  GeneratedColumn<String> get billingStatus => $composableBuilder(
      column: $table.billingStatus, builder: (column) => column);

  GeneratedColumn<String> get licenseKey => $composableBuilder(
      column: $table.licenseKey, builder: (column) => column);

  GeneratedColumn<DateTime> get trialEndsAt => $composableBuilder(
      column: $table.trialEndsAt, builder: (column) => column);
}

class $$LocalOrganizationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalOrganizationsTable,
    LocalOrganization,
    $$LocalOrganizationsTableFilterComposer,
    $$LocalOrganizationsTableOrderingComposer,
    $$LocalOrganizationsTableAnnotationComposer,
    $$LocalOrganizationsTableCreateCompanionBuilder,
    $$LocalOrganizationsTableUpdateCompanionBuilder,
    (
      LocalOrganization,
      BaseReferences<_$AppDatabase, $LocalOrganizationsTable, LocalOrganization>
    ),
    LocalOrganization,
    PrefetchHooks Function()> {
  $$LocalOrganizationsTableTableManager(
      _$AppDatabase db, $LocalOrganizationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalOrganizationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalOrganizationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalOrganizationsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> businessType = const Value.absent(),
            Value<String> ownerName = const Value.absent(),
            Value<String> phoneNumber = const Value.absent(),
            Value<String> plan = const Value.absent(),
            Value<String> billingStatus = const Value.absent(),
            Value<String?> licenseKey = const Value.absent(),
            Value<DateTime?> trialEndsAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalOrganizationsCompanion(
            id: id,
            name: name,
            businessType: businessType,
            ownerName: ownerName,
            phoneNumber: phoneNumber,
            plan: plan,
            billingStatus: billingStatus,
            licenseKey: licenseKey,
            trialEndsAt: trialEndsAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String businessType,
            required String ownerName,
            required String phoneNumber,
            Value<String> plan = const Value.absent(),
            Value<String> billingStatus = const Value.absent(),
            Value<String?> licenseKey = const Value.absent(),
            Value<DateTime?> trialEndsAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalOrganizationsCompanion.insert(
            id: id,
            name: name,
            businessType: businessType,
            ownerName: ownerName,
            phoneNumber: phoneNumber,
            plan: plan,
            billingStatus: billingStatus,
            licenseKey: licenseKey,
            trialEndsAt: trialEndsAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalOrganizationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalOrganizationsTable,
    LocalOrganization,
    $$LocalOrganizationsTableFilterComposer,
    $$LocalOrganizationsTableOrderingComposer,
    $$LocalOrganizationsTableAnnotationComposer,
    $$LocalOrganizationsTableCreateCompanionBuilder,
    $$LocalOrganizationsTableUpdateCompanionBuilder,
    (
      LocalOrganization,
      BaseReferences<_$AppDatabase, $LocalOrganizationsTable, LocalOrganization>
    ),
    LocalOrganization,
    PrefetchHooks Function()>;
typedef $$LocalBranchesTableCreateCompanionBuilder = LocalBranchesCompanion
    Function({
  required String id,
  required String organizationId,
  required String name,
  Value<String?> location,
  Value<String?> tillNumber,
  Value<bool> isActive,
  Value<int> rowid,
});
typedef $$LocalBranchesTableUpdateCompanionBuilder = LocalBranchesCompanion
    Function({
  Value<String> id,
  Value<String> organizationId,
  Value<String> name,
  Value<String?> location,
  Value<String?> tillNumber,
  Value<bool> isActive,
  Value<int> rowid,
});

class $$LocalBranchesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalBranchesTable> {
  $$LocalBranchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get organizationId => $composableBuilder(
      column: $table.organizationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tillNumber => $composableBuilder(
      column: $table.tillNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));
}

class $$LocalBranchesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalBranchesTable> {
  $$LocalBranchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get organizationId => $composableBuilder(
      column: $table.organizationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tillNumber => $composableBuilder(
      column: $table.tillNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));
}

class $$LocalBranchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalBranchesTable> {
  $$LocalBranchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get organizationId => $composableBuilder(
      column: $table.organizationId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get tillNumber => $composableBuilder(
      column: $table.tillNumber, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$LocalBranchesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalBranchesTable,
    LocalBranche,
    $$LocalBranchesTableFilterComposer,
    $$LocalBranchesTableOrderingComposer,
    $$LocalBranchesTableAnnotationComposer,
    $$LocalBranchesTableCreateCompanionBuilder,
    $$LocalBranchesTableUpdateCompanionBuilder,
    (
      LocalBranche,
      BaseReferences<_$AppDatabase, $LocalBranchesTable, LocalBranche>
    ),
    LocalBranche,
    PrefetchHooks Function()> {
  $$LocalBranchesTableTableManager(_$AppDatabase db, $LocalBranchesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalBranchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalBranchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalBranchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> organizationId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<String?> tillNumber = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalBranchesCompanion(
            id: id,
            organizationId: organizationId,
            name: name,
            location: location,
            tillNumber: tillNumber,
            isActive: isActive,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String organizationId,
            required String name,
            Value<String?> location = const Value.absent(),
            Value<String?> tillNumber = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalBranchesCompanion.insert(
            id: id,
            organizationId: organizationId,
            name: name,
            location: location,
            tillNumber: tillNumber,
            isActive: isActive,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalBranchesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalBranchesTable,
    LocalBranche,
    $$LocalBranchesTableFilterComposer,
    $$LocalBranchesTableOrderingComposer,
    $$LocalBranchesTableAnnotationComposer,
    $$LocalBranchesTableCreateCompanionBuilder,
    $$LocalBranchesTableUpdateCompanionBuilder,
    (
      LocalBranche,
      BaseReferences<_$AppDatabase, $LocalBranchesTable, LocalBranche>
    ),
    LocalBranche,
    PrefetchHooks Function()>;
typedef $$LocalBranchModulesTableCreateCompanionBuilder
    = LocalBranchModulesCompanion Function({
  required String branchId,
  required String moduleKey,
  Value<bool> isEnabled,
  Value<String> config,
  Value<int> rowid,
});
typedef $$LocalBranchModulesTableUpdateCompanionBuilder
    = LocalBranchModulesCompanion Function({
  Value<String> branchId,
  Value<String> moduleKey,
  Value<bool> isEnabled,
  Value<String> config,
  Value<int> rowid,
});

class $$LocalBranchModulesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalBranchModulesTable> {
  $$LocalBranchModulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get moduleKey => $composableBuilder(
      column: $table.moduleKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isEnabled => $composableBuilder(
      column: $table.isEnabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get config => $composableBuilder(
      column: $table.config, builder: (column) => ColumnFilters(column));
}

class $$LocalBranchModulesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalBranchModulesTable> {
  $$LocalBranchModulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get moduleKey => $composableBuilder(
      column: $table.moduleKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
      column: $table.isEnabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get config => $composableBuilder(
      column: $table.config, builder: (column) => ColumnOrderings(column));
}

class $$LocalBranchModulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalBranchModulesTable> {
  $$LocalBranchModulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get moduleKey =>
      $composableBuilder(column: $table.moduleKey, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<String> get config =>
      $composableBuilder(column: $table.config, builder: (column) => column);
}

class $$LocalBranchModulesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalBranchModulesTable,
    LocalBranchModule,
    $$LocalBranchModulesTableFilterComposer,
    $$LocalBranchModulesTableOrderingComposer,
    $$LocalBranchModulesTableAnnotationComposer,
    $$LocalBranchModulesTableCreateCompanionBuilder,
    $$LocalBranchModulesTableUpdateCompanionBuilder,
    (
      LocalBranchModule,
      BaseReferences<_$AppDatabase, $LocalBranchModulesTable, LocalBranchModule>
    ),
    LocalBranchModule,
    PrefetchHooks Function()> {
  $$LocalBranchModulesTableTableManager(
      _$AppDatabase db, $LocalBranchModulesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalBranchModulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalBranchModulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalBranchModulesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> branchId = const Value.absent(),
            Value<String> moduleKey = const Value.absent(),
            Value<bool> isEnabled = const Value.absent(),
            Value<String> config = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalBranchModulesCompanion(
            branchId: branchId,
            moduleKey: moduleKey,
            isEnabled: isEnabled,
            config: config,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String branchId,
            required String moduleKey,
            Value<bool> isEnabled = const Value.absent(),
            Value<String> config = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalBranchModulesCompanion.insert(
            branchId: branchId,
            moduleKey: moduleKey,
            isEnabled: isEnabled,
            config: config,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalBranchModulesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalBranchModulesTable,
    LocalBranchModule,
    $$LocalBranchModulesTableFilterComposer,
    $$LocalBranchModulesTableOrderingComposer,
    $$LocalBranchModulesTableAnnotationComposer,
    $$LocalBranchModulesTableCreateCompanionBuilder,
    $$LocalBranchModulesTableUpdateCompanionBuilder,
    (
      LocalBranchModule,
      BaseReferences<_$AppDatabase, $LocalBranchModulesTable, LocalBranchModule>
    ),
    LocalBranchModule,
    PrefetchHooks Function()>;
typedef $$LocalCategoriesTableCreateCompanionBuilder = LocalCategoriesCompanion
    Function({
  required String id,
  required String organizationId,
  required String name,
  Value<String> color,
  Value<int> rowid,
});
typedef $$LocalCategoriesTableUpdateCompanionBuilder = LocalCategoriesCompanion
    Function({
  Value<String> id,
  Value<String> organizationId,
  Value<String> name,
  Value<String> color,
  Value<int> rowid,
});

class $$LocalCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCategoriesTable> {
  $$LocalCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get organizationId => $composableBuilder(
      column: $table.organizationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));
}

class $$LocalCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCategoriesTable> {
  $$LocalCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get organizationId => $composableBuilder(
      column: $table.organizationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));
}

class $$LocalCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCategoriesTable> {
  $$LocalCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get organizationId => $composableBuilder(
      column: $table.organizationId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);
}

class $$LocalCategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalCategoriesTable,
    LocalCategory,
    $$LocalCategoriesTableFilterComposer,
    $$LocalCategoriesTableOrderingComposer,
    $$LocalCategoriesTableAnnotationComposer,
    $$LocalCategoriesTableCreateCompanionBuilder,
    $$LocalCategoriesTableUpdateCompanionBuilder,
    (
      LocalCategory,
      BaseReferences<_$AppDatabase, $LocalCategoriesTable, LocalCategory>
    ),
    LocalCategory,
    PrefetchHooks Function()> {
  $$LocalCategoriesTableTableManager(
      _$AppDatabase db, $LocalCategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> organizationId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> color = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalCategoriesCompanion(
            id: id,
            organizationId: organizationId,
            name: name,
            color: color,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String organizationId,
            required String name,
            Value<String> color = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalCategoriesCompanion.insert(
            id: id,
            organizationId: organizationId,
            name: name,
            color: color,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalCategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalCategoriesTable,
    LocalCategory,
    $$LocalCategoriesTableFilterComposer,
    $$LocalCategoriesTableOrderingComposer,
    $$LocalCategoriesTableAnnotationComposer,
    $$LocalCategoriesTableCreateCompanionBuilder,
    $$LocalCategoriesTableUpdateCompanionBuilder,
    (
      LocalCategory,
      BaseReferences<_$AppDatabase, $LocalCategoriesTable, LocalCategory>
    ),
    LocalCategory,
    PrefetchHooks Function()>;
typedef $$LocalProductsTableCreateCompanionBuilder = LocalProductsCompanion
    Function({
  required String id,
  required String organizationId,
  Value<String?> categoryId,
  required String name,
  Value<String?> sku,
  Value<String?> barcode,
  Value<double> costPrice,
  Value<double> sellingPrice,
  Value<double> taxRate,
  Value<String> unit,
  Value<double> currentStock,
  Value<bool> isActive,
  Value<int> rowid,
});
typedef $$LocalProductsTableUpdateCompanionBuilder = LocalProductsCompanion
    Function({
  Value<String> id,
  Value<String> organizationId,
  Value<String?> categoryId,
  Value<String> name,
  Value<String?> sku,
  Value<String?> barcode,
  Value<double> costPrice,
  Value<double> sellingPrice,
  Value<double> taxRate,
  Value<String> unit,
  Value<double> currentStock,
  Value<bool> isActive,
  Value<int> rowid,
});

class $$LocalProductsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalProductsTable> {
  $$LocalProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get organizationId => $composableBuilder(
      column: $table.organizationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get costPrice => $composableBuilder(
      column: $table.costPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get sellingPrice => $composableBuilder(
      column: $table.sellingPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get taxRate => $composableBuilder(
      column: $table.taxRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get currentStock => $composableBuilder(
      column: $table.currentStock, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));
}

class $$LocalProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalProductsTable> {
  $$LocalProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get organizationId => $composableBuilder(
      column: $table.organizationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get costPrice => $composableBuilder(
      column: $table.costPrice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get sellingPrice => $composableBuilder(
      column: $table.sellingPrice,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get taxRate => $composableBuilder(
      column: $table.taxRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get currentStock => $composableBuilder(
      column: $table.currentStock,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));
}

class $$LocalProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalProductsTable> {
  $$LocalProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get organizationId => $composableBuilder(
      column: $table.organizationId, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<double> get costPrice =>
      $composableBuilder(column: $table.costPrice, builder: (column) => column);

  GeneratedColumn<double> get sellingPrice => $composableBuilder(
      column: $table.sellingPrice, builder: (column) => column);

  GeneratedColumn<double> get taxRate =>
      $composableBuilder(column: $table.taxRate, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get currentStock => $composableBuilder(
      column: $table.currentStock, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$LocalProductsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalProductsTable,
    LocalProduct,
    $$LocalProductsTableFilterComposer,
    $$LocalProductsTableOrderingComposer,
    $$LocalProductsTableAnnotationComposer,
    $$LocalProductsTableCreateCompanionBuilder,
    $$LocalProductsTableUpdateCompanionBuilder,
    (
      LocalProduct,
      BaseReferences<_$AppDatabase, $LocalProductsTable, LocalProduct>
    ),
    LocalProduct,
    PrefetchHooks Function()> {
  $$LocalProductsTableTableManager(_$AppDatabase db, $LocalProductsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> organizationId = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> sku = const Value.absent(),
            Value<String?> barcode = const Value.absent(),
            Value<double> costPrice = const Value.absent(),
            Value<double> sellingPrice = const Value.absent(),
            Value<double> taxRate = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<double> currentStock = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalProductsCompanion(
            id: id,
            organizationId: organizationId,
            categoryId: categoryId,
            name: name,
            sku: sku,
            barcode: barcode,
            costPrice: costPrice,
            sellingPrice: sellingPrice,
            taxRate: taxRate,
            unit: unit,
            currentStock: currentStock,
            isActive: isActive,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String organizationId,
            Value<String?> categoryId = const Value.absent(),
            required String name,
            Value<String?> sku = const Value.absent(),
            Value<String?> barcode = const Value.absent(),
            Value<double> costPrice = const Value.absent(),
            Value<double> sellingPrice = const Value.absent(),
            Value<double> taxRate = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<double> currentStock = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalProductsCompanion.insert(
            id: id,
            organizationId: organizationId,
            categoryId: categoryId,
            name: name,
            sku: sku,
            barcode: barcode,
            costPrice: costPrice,
            sellingPrice: sellingPrice,
            taxRate: taxRate,
            unit: unit,
            currentStock: currentStock,
            isActive: isActive,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalProductsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalProductsTable,
    LocalProduct,
    $$LocalProductsTableFilterComposer,
    $$LocalProductsTableOrderingComposer,
    $$LocalProductsTableAnnotationComposer,
    $$LocalProductsTableCreateCompanionBuilder,
    $$LocalProductsTableUpdateCompanionBuilder,
    (
      LocalProduct,
      BaseReferences<_$AppDatabase, $LocalProductsTable, LocalProduct>
    ),
    LocalProduct,
    PrefetchHooks Function()>;
typedef $$LocalSalesTableCreateCompanionBuilder = LocalSalesCompanion Function({
  required String id,
  required String organizationId,
  required String branchId,
  required String receiptNumber,
  Value<String?> cashierId,
  Value<String?> customerName,
  Value<String?> customerPhone,
  Value<double> subtotal,
  Value<double> discount,
  Value<double> taxAmount,
  Value<double> totalAmount,
  Value<String> paymentMethod,
  Value<String?> mpesaReceiptNumber,
  Value<String> paymentStatus,
  Value<String> syncStatus,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$LocalSalesTableUpdateCompanionBuilder = LocalSalesCompanion Function({
  Value<String> id,
  Value<String> organizationId,
  Value<String> branchId,
  Value<String> receiptNumber,
  Value<String?> cashierId,
  Value<String?> customerName,
  Value<String?> customerPhone,
  Value<double> subtotal,
  Value<double> discount,
  Value<double> taxAmount,
  Value<double> totalAmount,
  Value<String> paymentMethod,
  Value<String?> mpesaReceiptNumber,
  Value<String> paymentStatus,
  Value<String> syncStatus,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$LocalSalesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSalesTable> {
  $$LocalSalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get organizationId => $composableBuilder(
      column: $table.organizationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get receiptNumber => $composableBuilder(
      column: $table.receiptNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cashierId => $composableBuilder(
      column: $table.cashierId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerName => $composableBuilder(
      column: $table.customerName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerPhone => $composableBuilder(
      column: $table.customerPhone, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get subtotal => $composableBuilder(
      column: $table.subtotal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get discount => $composableBuilder(
      column: $table.discount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get taxAmount => $composableBuilder(
      column: $table.taxAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mpesaReceiptNumber => $composableBuilder(
      column: $table.mpesaReceiptNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentStatus => $composableBuilder(
      column: $table.paymentStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$LocalSalesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSalesTable> {
  $$LocalSalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get organizationId => $composableBuilder(
      column: $table.organizationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get receiptNumber => $composableBuilder(
      column: $table.receiptNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cashierId => $composableBuilder(
      column: $table.cashierId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerName => $composableBuilder(
      column: $table.customerName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerPhone => $composableBuilder(
      column: $table.customerPhone,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get subtotal => $composableBuilder(
      column: $table.subtotal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get discount => $composableBuilder(
      column: $table.discount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get taxAmount => $composableBuilder(
      column: $table.taxAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mpesaReceiptNumber => $composableBuilder(
      column: $table.mpesaReceiptNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentStatus => $composableBuilder(
      column: $table.paymentStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalSalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSalesTable> {
  $$LocalSalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get organizationId => $composableBuilder(
      column: $table.organizationId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get receiptNumber => $composableBuilder(
      column: $table.receiptNumber, builder: (column) => column);

  GeneratedColumn<String> get cashierId =>
      $composableBuilder(column: $table.cashierId, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
      column: $table.customerName, builder: (column) => column);

  GeneratedColumn<String> get customerPhone => $composableBuilder(
      column: $table.customerPhone, builder: (column) => column);

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<double> get discount =>
      $composableBuilder(column: $table.discount, builder: (column) => column);

  GeneratedColumn<double> get taxAmount =>
      $composableBuilder(column: $table.taxAmount, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => column);

  GeneratedColumn<String> get mpesaReceiptNumber => $composableBuilder(
      column: $table.mpesaReceiptNumber, builder: (column) => column);

  GeneratedColumn<String> get paymentStatus => $composableBuilder(
      column: $table.paymentStatus, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalSalesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalSalesTable,
    LocalSale,
    $$LocalSalesTableFilterComposer,
    $$LocalSalesTableOrderingComposer,
    $$LocalSalesTableAnnotationComposer,
    $$LocalSalesTableCreateCompanionBuilder,
    $$LocalSalesTableUpdateCompanionBuilder,
    (LocalSale, BaseReferences<_$AppDatabase, $LocalSalesTable, LocalSale>),
    LocalSale,
    PrefetchHooks Function()> {
  $$LocalSalesTableTableManager(_$AppDatabase db, $LocalSalesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> organizationId = const Value.absent(),
            Value<String> branchId = const Value.absent(),
            Value<String> receiptNumber = const Value.absent(),
            Value<String?> cashierId = const Value.absent(),
            Value<String?> customerName = const Value.absent(),
            Value<String?> customerPhone = const Value.absent(),
            Value<double> subtotal = const Value.absent(),
            Value<double> discount = const Value.absent(),
            Value<double> taxAmount = const Value.absent(),
            Value<double> totalAmount = const Value.absent(),
            Value<String> paymentMethod = const Value.absent(),
            Value<String?> mpesaReceiptNumber = const Value.absent(),
            Value<String> paymentStatus = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalSalesCompanion(
            id: id,
            organizationId: organizationId,
            branchId: branchId,
            receiptNumber: receiptNumber,
            cashierId: cashierId,
            customerName: customerName,
            customerPhone: customerPhone,
            subtotal: subtotal,
            discount: discount,
            taxAmount: taxAmount,
            totalAmount: totalAmount,
            paymentMethod: paymentMethod,
            mpesaReceiptNumber: mpesaReceiptNumber,
            paymentStatus: paymentStatus,
            syncStatus: syncStatus,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String organizationId,
            required String branchId,
            required String receiptNumber,
            Value<String?> cashierId = const Value.absent(),
            Value<String?> customerName = const Value.absent(),
            Value<String?> customerPhone = const Value.absent(),
            Value<double> subtotal = const Value.absent(),
            Value<double> discount = const Value.absent(),
            Value<double> taxAmount = const Value.absent(),
            Value<double> totalAmount = const Value.absent(),
            Value<String> paymentMethod = const Value.absent(),
            Value<String?> mpesaReceiptNumber = const Value.absent(),
            Value<String> paymentStatus = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalSalesCompanion.insert(
            id: id,
            organizationId: organizationId,
            branchId: branchId,
            receiptNumber: receiptNumber,
            cashierId: cashierId,
            customerName: customerName,
            customerPhone: customerPhone,
            subtotal: subtotal,
            discount: discount,
            taxAmount: taxAmount,
            totalAmount: totalAmount,
            paymentMethod: paymentMethod,
            mpesaReceiptNumber: mpesaReceiptNumber,
            paymentStatus: paymentStatus,
            syncStatus: syncStatus,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalSalesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalSalesTable,
    LocalSale,
    $$LocalSalesTableFilterComposer,
    $$LocalSalesTableOrderingComposer,
    $$LocalSalesTableAnnotationComposer,
    $$LocalSalesTableCreateCompanionBuilder,
    $$LocalSalesTableUpdateCompanionBuilder,
    (LocalSale, BaseReferences<_$AppDatabase, $LocalSalesTable, LocalSale>),
    LocalSale,
    PrefetchHooks Function()>;
typedef $$LocalExpensesTableCreateCompanionBuilder = LocalExpensesCompanion
    Function({
  required String id,
  required String organizationId,
  required String branchId,
  required String category,
  required String description,
  required double amount,
  Value<String> paymentMethod,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$LocalExpensesTableUpdateCompanionBuilder = LocalExpensesCompanion
    Function({
  Value<String> id,
  Value<String> organizationId,
  Value<String> branchId,
  Value<String> category,
  Value<String> description,
  Value<double> amount,
  Value<String> paymentMethod,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$LocalExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalExpensesTable> {
  $$LocalExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get organizationId => $composableBuilder(
      column: $table.organizationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$LocalExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalExpensesTable> {
  $$LocalExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get organizationId => $composableBuilder(
      column: $table.organizationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalExpensesTable> {
  $$LocalExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get organizationId => $composableBuilder(
      column: $table.organizationId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalExpensesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalExpensesTable,
    LocalExpense,
    $$LocalExpensesTableFilterComposer,
    $$LocalExpensesTableOrderingComposer,
    $$LocalExpensesTableAnnotationComposer,
    $$LocalExpensesTableCreateCompanionBuilder,
    $$LocalExpensesTableUpdateCompanionBuilder,
    (
      LocalExpense,
      BaseReferences<_$AppDatabase, $LocalExpensesTable, LocalExpense>
    ),
    LocalExpense,
    PrefetchHooks Function()> {
  $$LocalExpensesTableTableManager(_$AppDatabase db, $LocalExpensesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> organizationId = const Value.absent(),
            Value<String> branchId = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> paymentMethod = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalExpensesCompanion(
            id: id,
            organizationId: organizationId,
            branchId: branchId,
            category: category,
            description: description,
            amount: amount,
            paymentMethod: paymentMethod,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String organizationId,
            required String branchId,
            required String category,
            required String description,
            required double amount,
            Value<String> paymentMethod = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalExpensesCompanion.insert(
            id: id,
            organizationId: organizationId,
            branchId: branchId,
            category: category,
            description: description,
            amount: amount,
            paymentMethod: paymentMethod,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalExpensesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalExpensesTable,
    LocalExpense,
    $$LocalExpensesTableFilterComposer,
    $$LocalExpensesTableOrderingComposer,
    $$LocalExpensesTableAnnotationComposer,
    $$LocalExpensesTableCreateCompanionBuilder,
    $$LocalExpensesTableUpdateCompanionBuilder,
    (
      LocalExpense,
      BaseReferences<_$AppDatabase, $LocalExpensesTable, LocalExpense>
    ),
    LocalExpense,
    PrefetchHooks Function()>;
typedef $$LocalTablesTableCreateCompanionBuilder = LocalTablesCompanion
    Function({
  required String id,
  required String organizationId,
  required String branchId,
  required String tableNumber,
  Value<int> capacity,
  Value<String> status,
  Value<int> rowid,
});
typedef $$LocalTablesTableUpdateCompanionBuilder = LocalTablesCompanion
    Function({
  Value<String> id,
  Value<String> organizationId,
  Value<String> branchId,
  Value<String> tableNumber,
  Value<int> capacity,
  Value<String> status,
  Value<int> rowid,
});

class $$LocalTablesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalTablesTable> {
  $$LocalTablesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get organizationId => $composableBuilder(
      column: $table.organizationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tableNumber => $composableBuilder(
      column: $table.tableNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get capacity => $composableBuilder(
      column: $table.capacity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));
}

class $$LocalTablesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalTablesTable> {
  $$LocalTablesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get organizationId => $composableBuilder(
      column: $table.organizationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tableNumber => $composableBuilder(
      column: $table.tableNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get capacity => $composableBuilder(
      column: $table.capacity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));
}

class $$LocalTablesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalTablesTable> {
  $$LocalTablesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get organizationId => $composableBuilder(
      column: $table.organizationId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get tableNumber => $composableBuilder(
      column: $table.tableNumber, builder: (column) => column);

  GeneratedColumn<int> get capacity =>
      $composableBuilder(column: $table.capacity, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$LocalTablesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalTablesTable,
    LocalTable,
    $$LocalTablesTableFilterComposer,
    $$LocalTablesTableOrderingComposer,
    $$LocalTablesTableAnnotationComposer,
    $$LocalTablesTableCreateCompanionBuilder,
    $$LocalTablesTableUpdateCompanionBuilder,
    (LocalTable, BaseReferences<_$AppDatabase, $LocalTablesTable, LocalTable>),
    LocalTable,
    PrefetchHooks Function()> {
  $$LocalTablesTableTableManager(_$AppDatabase db, $LocalTablesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTablesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTablesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTablesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> organizationId = const Value.absent(),
            Value<String> branchId = const Value.absent(),
            Value<String> tableNumber = const Value.absent(),
            Value<int> capacity = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalTablesCompanion(
            id: id,
            organizationId: organizationId,
            branchId: branchId,
            tableNumber: tableNumber,
            capacity: capacity,
            status: status,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String organizationId,
            required String branchId,
            required String tableNumber,
            Value<int> capacity = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalTablesCompanion.insert(
            id: id,
            organizationId: organizationId,
            branchId: branchId,
            tableNumber: tableNumber,
            capacity: capacity,
            status: status,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalTablesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalTablesTable,
    LocalTable,
    $$LocalTablesTableFilterComposer,
    $$LocalTablesTableOrderingComposer,
    $$LocalTablesTableAnnotationComposer,
    $$LocalTablesTableCreateCompanionBuilder,
    $$LocalTablesTableUpdateCompanionBuilder,
    (LocalTable, BaseReferences<_$AppDatabase, $LocalTablesTable, LocalTable>),
    LocalTable,
    PrefetchHooks Function()>;
typedef $$LocalUsersTableCreateCompanionBuilder = LocalUsersCompanion Function({
  required String id,
  required String organizationId,
  Value<String?> branchId,
  required String email,
  required String fullName,
  Value<String?> pinCode,
  required String role,
  Value<bool> isActive,
  Value<int> rowid,
});
typedef $$LocalUsersTableUpdateCompanionBuilder = LocalUsersCompanion Function({
  Value<String> id,
  Value<String> organizationId,
  Value<String?> branchId,
  Value<String> email,
  Value<String> fullName,
  Value<String?> pinCode,
  Value<String> role,
  Value<bool> isActive,
  Value<int> rowid,
});

class $$LocalUsersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalUsersTable> {
  $$LocalUsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get organizationId => $composableBuilder(
      column: $table.organizationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fullName => $composableBuilder(
      column: $table.fullName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pinCode => $composableBuilder(
      column: $table.pinCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));
}

class $$LocalUsersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalUsersTable> {
  $$LocalUsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get organizationId => $composableBuilder(
      column: $table.organizationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fullName => $composableBuilder(
      column: $table.fullName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pinCode => $composableBuilder(
      column: $table.pinCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));
}

class $$LocalUsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalUsersTable> {
  $$LocalUsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get organizationId => $composableBuilder(
      column: $table.organizationId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get pinCode =>
      $composableBuilder(column: $table.pinCode, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$LocalUsersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalUsersTable,
    LocalUser,
    $$LocalUsersTableFilterComposer,
    $$LocalUsersTableOrderingComposer,
    $$LocalUsersTableAnnotationComposer,
    $$LocalUsersTableCreateCompanionBuilder,
    $$LocalUsersTableUpdateCompanionBuilder,
    (LocalUser, BaseReferences<_$AppDatabase, $LocalUsersTable, LocalUser>),
    LocalUser,
    PrefetchHooks Function()> {
  $$LocalUsersTableTableManager(_$AppDatabase db, $LocalUsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalUsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalUsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalUsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> organizationId = const Value.absent(),
            Value<String?> branchId = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<String> fullName = const Value.absent(),
            Value<String?> pinCode = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalUsersCompanion(
            id: id,
            organizationId: organizationId,
            branchId: branchId,
            email: email,
            fullName: fullName,
            pinCode: pinCode,
            role: role,
            isActive: isActive,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String organizationId,
            Value<String?> branchId = const Value.absent(),
            required String email,
            required String fullName,
            Value<String?> pinCode = const Value.absent(),
            required String role,
            Value<bool> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalUsersCompanion.insert(
            id: id,
            organizationId: organizationId,
            branchId: branchId,
            email: email,
            fullName: fullName,
            pinCode: pinCode,
            role: role,
            isActive: isActive,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalUsersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalUsersTable,
    LocalUser,
    $$LocalUsersTableFilterComposer,
    $$LocalUsersTableOrderingComposer,
    $$LocalUsersTableAnnotationComposer,
    $$LocalUsersTableCreateCompanionBuilder,
    $$LocalUsersTableUpdateCompanionBuilder,
    (LocalUser, BaseReferences<_$AppDatabase, $LocalUsersTable, LocalUser>),
    LocalUser,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalOrganizationsTableTableManager get localOrganizations =>
      $$LocalOrganizationsTableTableManager(_db, _db.localOrganizations);
  $$LocalBranchesTableTableManager get localBranches =>
      $$LocalBranchesTableTableManager(_db, _db.localBranches);
  $$LocalBranchModulesTableTableManager get localBranchModules =>
      $$LocalBranchModulesTableTableManager(_db, _db.localBranchModules);
  $$LocalCategoriesTableTableManager get localCategories =>
      $$LocalCategoriesTableTableManager(_db, _db.localCategories);
  $$LocalProductsTableTableManager get localProducts =>
      $$LocalProductsTableTableManager(_db, _db.localProducts);
  $$LocalSalesTableTableManager get localSales =>
      $$LocalSalesTableTableManager(_db, _db.localSales);
  $$LocalExpensesTableTableManager get localExpenses =>
      $$LocalExpensesTableTableManager(_db, _db.localExpenses);
  $$LocalTablesTableTableManager get localTables =>
      $$LocalTablesTableTableManager(_db, _db.localTables);
  $$LocalUsersTableTableManager get localUsers =>
      $$LocalUsersTableTableManager(_db, _db.localUsers);
}
