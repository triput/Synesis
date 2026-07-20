// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accentArgbMeta = const VerificationMeta(
    'accentArgb',
  );
  @override
  late final GeneratedColumn<int> accentArgb = GeneratedColumn<int>(
    'accent_argb',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerTypeMeta = const VerificationMeta(
    'providerType',
  );
  @override
  late final GeneratedColumn<String> providerType = GeneratedColumn<String>(
    'provider_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (provider_type IN (\'graph\', \'imap\'))',
  );
  static const VerificationMeta _storageTypeMeta = const VerificationMeta(
    'storageType',
  );
  @override
  late final GeneratedColumn<String> storageType = GeneratedColumn<String>(
    'storage_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _focusEnabledMeta = const VerificationMeta(
    'focusEnabled',
  );
  @override
  late final GeneratedColumn<bool> focusEnabled = GeneratedColumn<bool>(
    'focus_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("focus_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _credentialsRefMeta = const VerificationMeta(
    'credentialsRef',
  );
  @override
  late final GeneratedColumn<String> credentialsRef = GeneratedColumn<String>(
    'credentials_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncProfileIdMeta = const VerificationMeta(
    'syncProfileId',
  );
  @override
  late final GeneratedColumn<String> syncProfileId = GeneratedColumn<String>(
    'sync_profile_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retentionDaysOverrideMeta =
      const VerificationMeta('retentionDaysOverride');
  @override
  late final GeneratedColumn<int> retentionDaysOverride = GeneratedColumn<int>(
    'retention_days_override',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    label,
    address,
    accentArgb,
    providerType,
    storageType,
    focusEnabled,
    credentialsRef,
    syncProfileId,
    retentionDaysOverride,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Account> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('accent_argb')) {
      context.handle(
        _accentArgbMeta,
        accentArgb.isAcceptableOrUnknown(data['accent_argb']!, _accentArgbMeta),
      );
    } else if (isInserting) {
      context.missing(_accentArgbMeta);
    }
    if (data.containsKey('provider_type')) {
      context.handle(
        _providerTypeMeta,
        providerType.isAcceptableOrUnknown(
          data['provider_type']!,
          _providerTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_providerTypeMeta);
    }
    if (data.containsKey('storage_type')) {
      context.handle(
        _storageTypeMeta,
        storageType.isAcceptableOrUnknown(
          data['storage_type']!,
          _storageTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_storageTypeMeta);
    }
    if (data.containsKey('focus_enabled')) {
      context.handle(
        _focusEnabledMeta,
        focusEnabled.isAcceptableOrUnknown(
          data['focus_enabled']!,
          _focusEnabledMeta,
        ),
      );
    }
    if (data.containsKey('credentials_ref')) {
      context.handle(
        _credentialsRefMeta,
        credentialsRef.isAcceptableOrUnknown(
          data['credentials_ref']!,
          _credentialsRefMeta,
        ),
      );
    }
    if (data.containsKey('sync_profile_id')) {
      context.handle(
        _syncProfileIdMeta,
        syncProfileId.isAcceptableOrUnknown(
          data['sync_profile_id']!,
          _syncProfileIdMeta,
        ),
      );
    }
    if (data.containsKey('retention_days_override')) {
      context.handle(
        _retentionDaysOverrideMeta,
        retentionDaysOverride.isAcceptableOrUnknown(
          data['retention_days_override']!,
          _retentionDaysOverrideMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      accentArgb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}accent_argb'],
      )!,
      providerType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_type'],
      )!,
      storageType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage_type'],
      )!,
      focusEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}focus_enabled'],
      )!,
      credentialsRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credentials_ref'],
      ),
      syncProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_profile_id'],
      ),
      retentionDaysOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retention_days_override'],
      ),
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final String id;
  final String label;
  final String address;
  final int accentArgb;
  final String providerType;
  final String storageType;
  final bool focusEnabled;
  final String? credentialsRef;
  final String? syncProfileId;
  final int? retentionDaysOverride;
  const Account({
    required this.id,
    required this.label,
    required this.address,
    required this.accentArgb,
    required this.providerType,
    required this.storageType,
    required this.focusEnabled,
    this.credentialsRef,
    this.syncProfileId,
    this.retentionDaysOverride,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    map['address'] = Variable<String>(address);
    map['accent_argb'] = Variable<int>(accentArgb);
    map['provider_type'] = Variable<String>(providerType);
    map['storage_type'] = Variable<String>(storageType);
    map['focus_enabled'] = Variable<bool>(focusEnabled);
    if (!nullToAbsent || credentialsRef != null) {
      map['credentials_ref'] = Variable<String>(credentialsRef);
    }
    if (!nullToAbsent || syncProfileId != null) {
      map['sync_profile_id'] = Variable<String>(syncProfileId);
    }
    if (!nullToAbsent || retentionDaysOverride != null) {
      map['retention_days_override'] = Variable<int>(retentionDaysOverride);
    }
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      label: Value(label),
      address: Value(address),
      accentArgb: Value(accentArgb),
      providerType: Value(providerType),
      storageType: Value(storageType),
      focusEnabled: Value(focusEnabled),
      credentialsRef: credentialsRef == null && nullToAbsent
          ? const Value.absent()
          : Value(credentialsRef),
      syncProfileId: syncProfileId == null && nullToAbsent
          ? const Value.absent()
          : Value(syncProfileId),
      retentionDaysOverride: retentionDaysOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(retentionDaysOverride),
    );
  }

  factory Account.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      address: serializer.fromJson<String>(json['address']),
      accentArgb: serializer.fromJson<int>(json['accentArgb']),
      providerType: serializer.fromJson<String>(json['providerType']),
      storageType: serializer.fromJson<String>(json['storageType']),
      focusEnabled: serializer.fromJson<bool>(json['focusEnabled']),
      credentialsRef: serializer.fromJson<String?>(json['credentialsRef']),
      syncProfileId: serializer.fromJson<String?>(json['syncProfileId']),
      retentionDaysOverride: serializer.fromJson<int?>(
        json['retentionDaysOverride'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'address': serializer.toJson<String>(address),
      'accentArgb': serializer.toJson<int>(accentArgb),
      'providerType': serializer.toJson<String>(providerType),
      'storageType': serializer.toJson<String>(storageType),
      'focusEnabled': serializer.toJson<bool>(focusEnabled),
      'credentialsRef': serializer.toJson<String?>(credentialsRef),
      'syncProfileId': serializer.toJson<String?>(syncProfileId),
      'retentionDaysOverride': serializer.toJson<int?>(retentionDaysOverride),
    };
  }

  Account copyWith({
    String? id,
    String? label,
    String? address,
    int? accentArgb,
    String? providerType,
    String? storageType,
    bool? focusEnabled,
    Value<String?> credentialsRef = const Value.absent(),
    Value<String?> syncProfileId = const Value.absent(),
    Value<int?> retentionDaysOverride = const Value.absent(),
  }) => Account(
    id: id ?? this.id,
    label: label ?? this.label,
    address: address ?? this.address,
    accentArgb: accentArgb ?? this.accentArgb,
    providerType: providerType ?? this.providerType,
    storageType: storageType ?? this.storageType,
    focusEnabled: focusEnabled ?? this.focusEnabled,
    credentialsRef: credentialsRef.present
        ? credentialsRef.value
        : this.credentialsRef,
    syncProfileId: syncProfileId.present
        ? syncProfileId.value
        : this.syncProfileId,
    retentionDaysOverride: retentionDaysOverride.present
        ? retentionDaysOverride.value
        : this.retentionDaysOverride,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      address: data.address.present ? data.address.value : this.address,
      accentArgb: data.accentArgb.present
          ? data.accentArgb.value
          : this.accentArgb,
      providerType: data.providerType.present
          ? data.providerType.value
          : this.providerType,
      storageType: data.storageType.present
          ? data.storageType.value
          : this.storageType,
      focusEnabled: data.focusEnabled.present
          ? data.focusEnabled.value
          : this.focusEnabled,
      credentialsRef: data.credentialsRef.present
          ? data.credentialsRef.value
          : this.credentialsRef,
      syncProfileId: data.syncProfileId.present
          ? data.syncProfileId.value
          : this.syncProfileId,
      retentionDaysOverride: data.retentionDaysOverride.present
          ? data.retentionDaysOverride.value
          : this.retentionDaysOverride,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('address: $address, ')
          ..write('accentArgb: $accentArgb, ')
          ..write('providerType: $providerType, ')
          ..write('storageType: $storageType, ')
          ..write('focusEnabled: $focusEnabled, ')
          ..write('credentialsRef: $credentialsRef, ')
          ..write('syncProfileId: $syncProfileId, ')
          ..write('retentionDaysOverride: $retentionDaysOverride')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    label,
    address,
    accentArgb,
    providerType,
    storageType,
    focusEnabled,
    credentialsRef,
    syncProfileId,
    retentionDaysOverride,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.label == this.label &&
          other.address == this.address &&
          other.accentArgb == this.accentArgb &&
          other.providerType == this.providerType &&
          other.storageType == this.storageType &&
          other.focusEnabled == this.focusEnabled &&
          other.credentialsRef == this.credentialsRef &&
          other.syncProfileId == this.syncProfileId &&
          other.retentionDaysOverride == this.retentionDaysOverride);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<String> id;
  final Value<String> label;
  final Value<String> address;
  final Value<int> accentArgb;
  final Value<String> providerType;
  final Value<String> storageType;
  final Value<bool> focusEnabled;
  final Value<String?> credentialsRef;
  final Value<String?> syncProfileId;
  final Value<int?> retentionDaysOverride;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.address = const Value.absent(),
    this.accentArgb = const Value.absent(),
    this.providerType = const Value.absent(),
    this.storageType = const Value.absent(),
    this.focusEnabled = const Value.absent(),
    this.credentialsRef = const Value.absent(),
    this.syncProfileId = const Value.absent(),
    this.retentionDaysOverride = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String label,
    required String address,
    required int accentArgb,
    required String providerType,
    required String storageType,
    this.focusEnabled = const Value.absent(),
    this.credentialsRef = const Value.absent(),
    this.syncProfileId = const Value.absent(),
    this.retentionDaysOverride = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       label = Value(label),
       address = Value(address),
       accentArgb = Value(accentArgb),
       providerType = Value(providerType),
       storageType = Value(storageType);
  static Insertable<Account> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<String>? address,
    Expression<int>? accentArgb,
    Expression<String>? providerType,
    Expression<String>? storageType,
    Expression<bool>? focusEnabled,
    Expression<String>? credentialsRef,
    Expression<String>? syncProfileId,
    Expression<int>? retentionDaysOverride,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (address != null) 'address': address,
      if (accentArgb != null) 'accent_argb': accentArgb,
      if (providerType != null) 'provider_type': providerType,
      if (storageType != null) 'storage_type': storageType,
      if (focusEnabled != null) 'focus_enabled': focusEnabled,
      if (credentialsRef != null) 'credentials_ref': credentialsRef,
      if (syncProfileId != null) 'sync_profile_id': syncProfileId,
      if (retentionDaysOverride != null)
        'retention_days_override': retentionDaysOverride,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? label,
    Value<String>? address,
    Value<int>? accentArgb,
    Value<String>? providerType,
    Value<String>? storageType,
    Value<bool>? focusEnabled,
    Value<String?>? credentialsRef,
    Value<String?>? syncProfileId,
    Value<int?>? retentionDaysOverride,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      address: address ?? this.address,
      accentArgb: accentArgb ?? this.accentArgb,
      providerType: providerType ?? this.providerType,
      storageType: storageType ?? this.storageType,
      focusEnabled: focusEnabled ?? this.focusEnabled,
      credentialsRef: credentialsRef ?? this.credentialsRef,
      syncProfileId: syncProfileId ?? this.syncProfileId,
      retentionDaysOverride:
          retentionDaysOverride ?? this.retentionDaysOverride,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (accentArgb.present) {
      map['accent_argb'] = Variable<int>(accentArgb.value);
    }
    if (providerType.present) {
      map['provider_type'] = Variable<String>(providerType.value);
    }
    if (storageType.present) {
      map['storage_type'] = Variable<String>(storageType.value);
    }
    if (focusEnabled.present) {
      map['focus_enabled'] = Variable<bool>(focusEnabled.value);
    }
    if (credentialsRef.present) {
      map['credentials_ref'] = Variable<String>(credentialsRef.value);
    }
    if (syncProfileId.present) {
      map['sync_profile_id'] = Variable<String>(syncProfileId.value);
    }
    if (retentionDaysOverride.present) {
      map['retention_days_override'] = Variable<int>(
        retentionDaysOverride.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('address: $address, ')
          ..write('accentArgb: $accentArgb, ')
          ..write('providerType: $providerType, ')
          ..write('storageType: $storageType, ')
          ..write('focusEnabled: $focusEnabled, ')
          ..write('credentialsRef: $credentialsRef, ')
          ..write('syncProfileId: $syncProfileId, ')
          ..write('retentionDaysOverride: $retentionDaysOverride, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FoldersTable extends Folders with TableInfo<$FoldersTable, Folder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentRemoteIdMeta = const VerificationMeta(
    'parentRemoteId',
  );
  @override
  late final GeneratedColumn<String> parentRemoteId = GeneratedColumn<String>(
    'parent_remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
    'unread_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalCountMeta = const VerificationMeta(
    'totalCount',
  );
  @override
  late final GeneratedColumn<int> totalCount = GeneratedColumn<int>(
    'total_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    name,
    role,
    remoteId,
    parentRemoteId,
    unreadCount,
    totalCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Folder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('parent_remote_id')) {
      context.handle(
        _parentRemoteIdMeta,
        parentRemoteId.isAcceptableOrUnknown(
          data['parent_remote_id']!,
          _parentRemoteIdMeta,
        ),
      );
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    }
    if (data.containsKey('total_count')) {
      context.handle(
        _totalCountMeta,
        totalCount.isAcceptableOrUnknown(data['total_count']!, _totalCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Folder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Folder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      )!,
      parentRemoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_remote_id'],
      ),
      unreadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unread_count'],
      ),
      totalCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_count'],
      ),
    );
  }

  @override
  $FoldersTable createAlias(String alias) {
    return $FoldersTable(attachedDatabase, alias);
  }
}

class Folder extends DataClass implements Insertable<Folder> {
  final String id;
  final String accountId;
  final String name;
  final String role;
  final String remoteId;
  final String? parentRemoteId;
  final int? unreadCount;
  final int? totalCount;
  const Folder({
    required this.id,
    required this.accountId,
    required this.name,
    required this.role,
    required this.remoteId,
    this.parentRemoteId,
    this.unreadCount,
    this.totalCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['name'] = Variable<String>(name);
    map['role'] = Variable<String>(role);
    map['remote_id'] = Variable<String>(remoteId);
    if (!nullToAbsent || parentRemoteId != null) {
      map['parent_remote_id'] = Variable<String>(parentRemoteId);
    }
    if (!nullToAbsent || unreadCount != null) {
      map['unread_count'] = Variable<int>(unreadCount);
    }
    if (!nullToAbsent || totalCount != null) {
      map['total_count'] = Variable<int>(totalCount);
    }
    return map;
  }

  FoldersCompanion toCompanion(bool nullToAbsent) {
    return FoldersCompanion(
      id: Value(id),
      accountId: Value(accountId),
      name: Value(name),
      role: Value(role),
      remoteId: Value(remoteId),
      parentRemoteId: parentRemoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentRemoteId),
      unreadCount: unreadCount == null && nullToAbsent
          ? const Value.absent()
          : Value(unreadCount),
      totalCount: totalCount == null && nullToAbsent
          ? const Value.absent()
          : Value(totalCount),
    );
  }

  factory Folder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Folder(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<String>(json['role']),
      remoteId: serializer.fromJson<String>(json['remoteId']),
      parentRemoteId: serializer.fromJson<String?>(json['parentRemoteId']),
      unreadCount: serializer.fromJson<int?>(json['unreadCount']),
      totalCount: serializer.fromJson<int?>(json['totalCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<String>(role),
      'remoteId': serializer.toJson<String>(remoteId),
      'parentRemoteId': serializer.toJson<String?>(parentRemoteId),
      'unreadCount': serializer.toJson<int?>(unreadCount),
      'totalCount': serializer.toJson<int?>(totalCount),
    };
  }

  Folder copyWith({
    String? id,
    String? accountId,
    String? name,
    String? role,
    String? remoteId,
    Value<String?> parentRemoteId = const Value.absent(),
    Value<int?> unreadCount = const Value.absent(),
    Value<int?> totalCount = const Value.absent(),
  }) => Folder(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    name: name ?? this.name,
    role: role ?? this.role,
    remoteId: remoteId ?? this.remoteId,
    parentRemoteId: parentRemoteId.present
        ? parentRemoteId.value
        : this.parentRemoteId,
    unreadCount: unreadCount.present ? unreadCount.value : this.unreadCount,
    totalCount: totalCount.present ? totalCount.value : this.totalCount,
  );
  Folder copyWithCompanion(FoldersCompanion data) {
    return Folder(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      parentRemoteId: data.parentRemoteId.present
          ? data.parentRemoteId.value
          : this.parentRemoteId,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
      totalCount: data.totalCount.present
          ? data.totalCount.value
          : this.totalCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Folder(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('remoteId: $remoteId, ')
          ..write('parentRemoteId: $parentRemoteId, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('totalCount: $totalCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    name,
    role,
    remoteId,
    parentRemoteId,
    unreadCount,
    totalCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Folder &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.name == this.name &&
          other.role == this.role &&
          other.remoteId == this.remoteId &&
          other.parentRemoteId == this.parentRemoteId &&
          other.unreadCount == this.unreadCount &&
          other.totalCount == this.totalCount);
}

class FoldersCompanion extends UpdateCompanion<Folder> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> name;
  final Value<String> role;
  final Value<String> remoteId;
  final Value<String?> parentRemoteId;
  final Value<int?> unreadCount;
  final Value<int?> totalCount;
  final Value<int> rowid;
  const FoldersCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.parentRemoteId = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.totalCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoldersCompanion.insert({
    required String id,
    required String accountId,
    required String name,
    this.role = const Value.absent(),
    required String remoteId,
    this.parentRemoteId = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.totalCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       name = Value(name),
       remoteId = Value(remoteId);
  static Insertable<Folder> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? name,
    Expression<String>? role,
    Expression<String>? remoteId,
    Expression<String>? parentRemoteId,
    Expression<int>? unreadCount,
    Expression<int>? totalCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (remoteId != null) 'remote_id': remoteId,
      if (parentRemoteId != null) 'parent_remote_id': parentRemoteId,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (totalCount != null) 'total_count': totalCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoldersCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? name,
    Value<String>? role,
    Value<String>? remoteId,
    Value<String?>? parentRemoteId,
    Value<int?>? unreadCount,
    Value<int?>? totalCount,
    Value<int>? rowid,
  }) {
    return FoldersCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      name: name ?? this.name,
      role: role ?? this.role,
      remoteId: remoteId ?? this.remoteId,
      parentRemoteId: parentRemoteId ?? this.parentRemoteId,
      unreadCount: unreadCount ?? this.unreadCount,
      totalCount: totalCount ?? this.totalCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (parentRemoteId.present) {
      map['parent_remote_id'] = Variable<String>(parentRemoteId.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (totalCount.present) {
      map['total_count'] = Variable<int>(totalCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoldersCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('remoteId: $remoteId, ')
          ..write('parentRemoteId: $parentRemoteId, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('totalCount: $totalCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
    'folder_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageIdHeaderMeta = const VerificationMeta(
    'messageIdHeader',
  );
  @override
  late final GeneratedColumn<String> messageIdHeader = GeneratedColumn<String>(
    'message_id_header',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromNameMeta = const VerificationMeta(
    'fromName',
  );
  @override
  late final GeneratedColumn<String> fromName = GeneratedColumn<String>(
    'from_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromAddressMeta = const VerificationMeta(
    'fromAddress',
  );
  @override
  late final GeneratedColumn<String> fromAddress = GeneratedColumn<String>(
    'from_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snippetMeta = const VerificationMeta(
    'snippet',
  );
  @override
  late final GeneratedColumn<String> snippet = GeneratedColumn<String>(
    'snippet',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _whenEpochMsMeta = const VerificationMeta(
    'whenEpochMs',
  );
  @override
  late final GeneratedColumn<int> whenEpochMs = GeneratedColumn<int>(
    'when_epoch_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _focusBucketMeta = const VerificationMeta(
    'focusBucket',
  );
  @override
  late final GeneratedColumn<String> focusBucket = GeneratedColumn<String>(
    'focus_bucket',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (focus_bucket IN (\'focused\', \'other\'))',
  );
  static const VerificationMeta _unreadMeta = const VerificationMeta('unread');
  @override
  late final GeneratedColumn<bool> unread = GeneratedColumn<bool>(
    'unread',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("unread" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
    'pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hasAttachmentsMeta = const VerificationMeta(
    'hasAttachments',
  );
  @override
  late final GeneratedColumn<bool> hasAttachments = GeneratedColumn<bool>(
    'has_attachments',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_attachments" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _rawHeadersMeta = const VerificationMeta(
    'rawHeaders',
  );
  @override
  late final GeneratedColumn<String> rawHeaders = GeneratedColumn<String>(
    'raw_headers',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toRecipientsMeta = const VerificationMeta(
    'toRecipients',
  );
  @override
  late final GeneratedColumn<String> toRecipients = GeneratedColumn<String>(
    'to_recipients',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _ccRecipientsMeta = const VerificationMeta(
    'ccRecipients',
  );
  @override
  late final GeneratedColumn<String> ccRecipients = GeneratedColumn<String>(
    'cc_recipients',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _starredMeta = const VerificationMeta(
    'starred',
  );
  @override
  late final GeneratedColumn<bool> starred = GeneratedColumn<bool>(
    'starred',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("starred" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _threadIdMeta = const VerificationMeta(
    'threadId',
  );
  @override
  late final GeneratedColumn<String> threadId = GeneratedColumn<String>(
    'thread_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _snoozedUntilMeta = const VerificationMeta(
    'snoozedUntil',
  );
  @override
  late final GeneratedColumn<int> snoozedUntil = GeneratedColumn<int>(
    'snoozed_until',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trashedAtMeta = const VerificationMeta(
    'trashedAt',
  );
  @override
  late final GeneratedColumn<int> trashedAt = GeneratedColumn<int>(
    'trashed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDraftMeta = const VerificationMeta(
    'isDraft',
  );
  @override
  late final GeneratedColumn<bool> isDraft = GeneratedColumn<bool>(
    'is_draft',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_draft" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _draftSyncProviderIdMeta =
      const VerificationMeta('draftSyncProviderId');
  @override
  late final GeneratedColumn<String> draftSyncProviderId =
      GeneratedColumn<String>(
        'draft_sync_provider_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    folderId,
    providerId,
    messageIdHeader,
    fromName,
    fromAddress,
    subject,
    snippet,
    body,
    whenEpochMs,
    focusBucket,
    unread,
    pinned,
    hasAttachments,
    rawHeaders,
    toRecipients,
    ccRecipients,
    starred,
    threadId,
    snoozedUntil,
    trashedAt,
    isDraft,
    draftSyncProviderId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Message> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_folderIdMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('message_id_header')) {
      context.handle(
        _messageIdHeaderMeta,
        messageIdHeader.isAcceptableOrUnknown(
          data['message_id_header']!,
          _messageIdHeaderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_messageIdHeaderMeta);
    }
    if (data.containsKey('from_name')) {
      context.handle(
        _fromNameMeta,
        fromName.isAcceptableOrUnknown(data['from_name']!, _fromNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fromNameMeta);
    }
    if (data.containsKey('from_address')) {
      context.handle(
        _fromAddressMeta,
        fromAddress.isAcceptableOrUnknown(
          data['from_address']!,
          _fromAddressMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromAddressMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('snippet')) {
      context.handle(
        _snippetMeta,
        snippet.isAcceptableOrUnknown(data['snippet']!, _snippetMeta),
      );
    } else if (isInserting) {
      context.missing(_snippetMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('when_epoch_ms')) {
      context.handle(
        _whenEpochMsMeta,
        whenEpochMs.isAcceptableOrUnknown(
          data['when_epoch_ms']!,
          _whenEpochMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_whenEpochMsMeta);
    }
    if (data.containsKey('focus_bucket')) {
      context.handle(
        _focusBucketMeta,
        focusBucket.isAcceptableOrUnknown(
          data['focus_bucket']!,
          _focusBucketMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_focusBucketMeta);
    }
    if (data.containsKey('unread')) {
      context.handle(
        _unreadMeta,
        unread.isAcceptableOrUnknown(data['unread']!, _unreadMeta),
      );
    }
    if (data.containsKey('pinned')) {
      context.handle(
        _pinnedMeta,
        pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta),
      );
    }
    if (data.containsKey('has_attachments')) {
      context.handle(
        _hasAttachmentsMeta,
        hasAttachments.isAcceptableOrUnknown(
          data['has_attachments']!,
          _hasAttachmentsMeta,
        ),
      );
    }
    if (data.containsKey('raw_headers')) {
      context.handle(
        _rawHeadersMeta,
        rawHeaders.isAcceptableOrUnknown(data['raw_headers']!, _rawHeadersMeta),
      );
    }
    if (data.containsKey('to_recipients')) {
      context.handle(
        _toRecipientsMeta,
        toRecipients.isAcceptableOrUnknown(
          data['to_recipients']!,
          _toRecipientsMeta,
        ),
      );
    }
    if (data.containsKey('cc_recipients')) {
      context.handle(
        _ccRecipientsMeta,
        ccRecipients.isAcceptableOrUnknown(
          data['cc_recipients']!,
          _ccRecipientsMeta,
        ),
      );
    }
    if (data.containsKey('starred')) {
      context.handle(
        _starredMeta,
        starred.isAcceptableOrUnknown(data['starred']!, _starredMeta),
      );
    }
    if (data.containsKey('thread_id')) {
      context.handle(
        _threadIdMeta,
        threadId.isAcceptableOrUnknown(data['thread_id']!, _threadIdMeta),
      );
    }
    if (data.containsKey('snoozed_until')) {
      context.handle(
        _snoozedUntilMeta,
        snoozedUntil.isAcceptableOrUnknown(
          data['snoozed_until']!,
          _snoozedUntilMeta,
        ),
      );
    }
    if (data.containsKey('trashed_at')) {
      context.handle(
        _trashedAtMeta,
        trashedAt.isAcceptableOrUnknown(data['trashed_at']!, _trashedAtMeta),
      );
    }
    if (data.containsKey('is_draft')) {
      context.handle(
        _isDraftMeta,
        isDraft.isAcceptableOrUnknown(data['is_draft']!, _isDraftMeta),
      );
    }
    if (data.containsKey('draft_sync_provider_id')) {
      context.handle(
        _draftSyncProviderIdMeta,
        draftSyncProviderId.isAcceptableOrUnknown(
          data['draft_sync_provider_id']!,
          _draftSyncProviderIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      messageIdHeader: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id_header'],
      )!,
      fromName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_name'],
      )!,
      fromAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_address'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      snippet: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snippet'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      ),
      whenEpochMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}when_epoch_ms'],
      )!,
      focusBucket: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}focus_bucket'],
      )!,
      unread: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}unread'],
      )!,
      pinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pinned'],
      )!,
      hasAttachments: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_attachments'],
      )!,
      rawHeaders: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_headers'],
      ),
      toRecipients: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_recipients'],
      )!,
      ccRecipients: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cc_recipients'],
      )!,
      starred: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}starred'],
      )!,
      threadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thread_id'],
      ),
      snoozedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snoozed_until'],
      ),
      trashedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trashed_at'],
      ),
      isDraft: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_draft'],
      )!,
      draftSyncProviderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}draft_sync_provider_id'],
      ),
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final String id;
  final String accountId;
  final String folderId;
  final String providerId;
  final String messageIdHeader;
  final String fromName;
  final String fromAddress;
  final String subject;
  final String snippet;
  final String? body;
  final int whenEpochMs;
  final String focusBucket;
  final bool unread;
  final bool pinned;
  final bool hasAttachments;
  final String? rawHeaders;
  final String toRecipients;
  final String ccRecipients;
  final bool starred;
  final String? threadId;
  final int? snoozedUntil;
  final int? trashedAt;
  final bool isDraft;
  final String? draftSyncProviderId;
  const Message({
    required this.id,
    required this.accountId,
    required this.folderId,
    required this.providerId,
    required this.messageIdHeader,
    required this.fromName,
    required this.fromAddress,
    required this.subject,
    required this.snippet,
    this.body,
    required this.whenEpochMs,
    required this.focusBucket,
    required this.unread,
    required this.pinned,
    required this.hasAttachments,
    this.rawHeaders,
    required this.toRecipients,
    required this.ccRecipients,
    required this.starred,
    this.threadId,
    this.snoozedUntil,
    this.trashedAt,
    required this.isDraft,
    this.draftSyncProviderId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['folder_id'] = Variable<String>(folderId);
    map['provider_id'] = Variable<String>(providerId);
    map['message_id_header'] = Variable<String>(messageIdHeader);
    map['from_name'] = Variable<String>(fromName);
    map['from_address'] = Variable<String>(fromAddress);
    map['subject'] = Variable<String>(subject);
    map['snippet'] = Variable<String>(snippet);
    if (!nullToAbsent || body != null) {
      map['body'] = Variable<String>(body);
    }
    map['when_epoch_ms'] = Variable<int>(whenEpochMs);
    map['focus_bucket'] = Variable<String>(focusBucket);
    map['unread'] = Variable<bool>(unread);
    map['pinned'] = Variable<bool>(pinned);
    map['has_attachments'] = Variable<bool>(hasAttachments);
    if (!nullToAbsent || rawHeaders != null) {
      map['raw_headers'] = Variable<String>(rawHeaders);
    }
    map['to_recipients'] = Variable<String>(toRecipients);
    map['cc_recipients'] = Variable<String>(ccRecipients);
    map['starred'] = Variable<bool>(starred);
    if (!nullToAbsent || threadId != null) {
      map['thread_id'] = Variable<String>(threadId);
    }
    if (!nullToAbsent || snoozedUntil != null) {
      map['snoozed_until'] = Variable<int>(snoozedUntil);
    }
    if (!nullToAbsent || trashedAt != null) {
      map['trashed_at'] = Variable<int>(trashedAt);
    }
    map['is_draft'] = Variable<bool>(isDraft);
    if (!nullToAbsent || draftSyncProviderId != null) {
      map['draft_sync_provider_id'] = Variable<String>(draftSyncProviderId);
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      accountId: Value(accountId),
      folderId: Value(folderId),
      providerId: Value(providerId),
      messageIdHeader: Value(messageIdHeader),
      fromName: Value(fromName),
      fromAddress: Value(fromAddress),
      subject: Value(subject),
      snippet: Value(snippet),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      whenEpochMs: Value(whenEpochMs),
      focusBucket: Value(focusBucket),
      unread: Value(unread),
      pinned: Value(pinned),
      hasAttachments: Value(hasAttachments),
      rawHeaders: rawHeaders == null && nullToAbsent
          ? const Value.absent()
          : Value(rawHeaders),
      toRecipients: Value(toRecipients),
      ccRecipients: Value(ccRecipients),
      starred: Value(starred),
      threadId: threadId == null && nullToAbsent
          ? const Value.absent()
          : Value(threadId),
      snoozedUntil: snoozedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozedUntil),
      trashedAt: trashedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(trashedAt),
      isDraft: Value(isDraft),
      draftSyncProviderId: draftSyncProviderId == null && nullToAbsent
          ? const Value.absent()
          : Value(draftSyncProviderId),
    );
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      folderId: serializer.fromJson<String>(json['folderId']),
      providerId: serializer.fromJson<String>(json['providerId']),
      messageIdHeader: serializer.fromJson<String>(json['messageIdHeader']),
      fromName: serializer.fromJson<String>(json['fromName']),
      fromAddress: serializer.fromJson<String>(json['fromAddress']),
      subject: serializer.fromJson<String>(json['subject']),
      snippet: serializer.fromJson<String>(json['snippet']),
      body: serializer.fromJson<String?>(json['body']),
      whenEpochMs: serializer.fromJson<int>(json['whenEpochMs']),
      focusBucket: serializer.fromJson<String>(json['focusBucket']),
      unread: serializer.fromJson<bool>(json['unread']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      hasAttachments: serializer.fromJson<bool>(json['hasAttachments']),
      rawHeaders: serializer.fromJson<String?>(json['rawHeaders']),
      toRecipients: serializer.fromJson<String>(json['toRecipients']),
      ccRecipients: serializer.fromJson<String>(json['ccRecipients']),
      starred: serializer.fromJson<bool>(json['starred']),
      threadId: serializer.fromJson<String?>(json['threadId']),
      snoozedUntil: serializer.fromJson<int?>(json['snoozedUntil']),
      trashedAt: serializer.fromJson<int?>(json['trashedAt']),
      isDraft: serializer.fromJson<bool>(json['isDraft']),
      draftSyncProviderId: serializer.fromJson<String?>(
        json['draftSyncProviderId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'folderId': serializer.toJson<String>(folderId),
      'providerId': serializer.toJson<String>(providerId),
      'messageIdHeader': serializer.toJson<String>(messageIdHeader),
      'fromName': serializer.toJson<String>(fromName),
      'fromAddress': serializer.toJson<String>(fromAddress),
      'subject': serializer.toJson<String>(subject),
      'snippet': serializer.toJson<String>(snippet),
      'body': serializer.toJson<String?>(body),
      'whenEpochMs': serializer.toJson<int>(whenEpochMs),
      'focusBucket': serializer.toJson<String>(focusBucket),
      'unread': serializer.toJson<bool>(unread),
      'pinned': serializer.toJson<bool>(pinned),
      'hasAttachments': serializer.toJson<bool>(hasAttachments),
      'rawHeaders': serializer.toJson<String?>(rawHeaders),
      'toRecipients': serializer.toJson<String>(toRecipients),
      'ccRecipients': serializer.toJson<String>(ccRecipients),
      'starred': serializer.toJson<bool>(starred),
      'threadId': serializer.toJson<String?>(threadId),
      'snoozedUntil': serializer.toJson<int?>(snoozedUntil),
      'trashedAt': serializer.toJson<int?>(trashedAt),
      'isDraft': serializer.toJson<bool>(isDraft),
      'draftSyncProviderId': serializer.toJson<String?>(draftSyncProviderId),
    };
  }

  Message copyWith({
    String? id,
    String? accountId,
    String? folderId,
    String? providerId,
    String? messageIdHeader,
    String? fromName,
    String? fromAddress,
    String? subject,
    String? snippet,
    Value<String?> body = const Value.absent(),
    int? whenEpochMs,
    String? focusBucket,
    bool? unread,
    bool? pinned,
    bool? hasAttachments,
    Value<String?> rawHeaders = const Value.absent(),
    String? toRecipients,
    String? ccRecipients,
    bool? starred,
    Value<String?> threadId = const Value.absent(),
    Value<int?> snoozedUntil = const Value.absent(),
    Value<int?> trashedAt = const Value.absent(),
    bool? isDraft,
    Value<String?> draftSyncProviderId = const Value.absent(),
  }) => Message(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    folderId: folderId ?? this.folderId,
    providerId: providerId ?? this.providerId,
    messageIdHeader: messageIdHeader ?? this.messageIdHeader,
    fromName: fromName ?? this.fromName,
    fromAddress: fromAddress ?? this.fromAddress,
    subject: subject ?? this.subject,
    snippet: snippet ?? this.snippet,
    body: body.present ? body.value : this.body,
    whenEpochMs: whenEpochMs ?? this.whenEpochMs,
    focusBucket: focusBucket ?? this.focusBucket,
    unread: unread ?? this.unread,
    pinned: pinned ?? this.pinned,
    hasAttachments: hasAttachments ?? this.hasAttachments,
    rawHeaders: rawHeaders.present ? rawHeaders.value : this.rawHeaders,
    toRecipients: toRecipients ?? this.toRecipients,
    ccRecipients: ccRecipients ?? this.ccRecipients,
    starred: starred ?? this.starred,
    threadId: threadId.present ? threadId.value : this.threadId,
    snoozedUntil: snoozedUntil.present ? snoozedUntil.value : this.snoozedUntil,
    trashedAt: trashedAt.present ? trashedAt.value : this.trashedAt,
    isDraft: isDraft ?? this.isDraft,
    draftSyncProviderId: draftSyncProviderId.present
        ? draftSyncProviderId.value
        : this.draftSyncProviderId,
  );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      messageIdHeader: data.messageIdHeader.present
          ? data.messageIdHeader.value
          : this.messageIdHeader,
      fromName: data.fromName.present ? data.fromName.value : this.fromName,
      fromAddress: data.fromAddress.present
          ? data.fromAddress.value
          : this.fromAddress,
      subject: data.subject.present ? data.subject.value : this.subject,
      snippet: data.snippet.present ? data.snippet.value : this.snippet,
      body: data.body.present ? data.body.value : this.body,
      whenEpochMs: data.whenEpochMs.present
          ? data.whenEpochMs.value
          : this.whenEpochMs,
      focusBucket: data.focusBucket.present
          ? data.focusBucket.value
          : this.focusBucket,
      unread: data.unread.present ? data.unread.value : this.unread,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      hasAttachments: data.hasAttachments.present
          ? data.hasAttachments.value
          : this.hasAttachments,
      rawHeaders: data.rawHeaders.present
          ? data.rawHeaders.value
          : this.rawHeaders,
      toRecipients: data.toRecipients.present
          ? data.toRecipients.value
          : this.toRecipients,
      ccRecipients: data.ccRecipients.present
          ? data.ccRecipients.value
          : this.ccRecipients,
      starred: data.starred.present ? data.starred.value : this.starred,
      threadId: data.threadId.present ? data.threadId.value : this.threadId,
      snoozedUntil: data.snoozedUntil.present
          ? data.snoozedUntil.value
          : this.snoozedUntil,
      trashedAt: data.trashedAt.present ? data.trashedAt.value : this.trashedAt,
      isDraft: data.isDraft.present ? data.isDraft.value : this.isDraft,
      draftSyncProviderId: data.draftSyncProviderId.present
          ? data.draftSyncProviderId.value
          : this.draftSyncProviderId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('folderId: $folderId, ')
          ..write('providerId: $providerId, ')
          ..write('messageIdHeader: $messageIdHeader, ')
          ..write('fromName: $fromName, ')
          ..write('fromAddress: $fromAddress, ')
          ..write('subject: $subject, ')
          ..write('snippet: $snippet, ')
          ..write('body: $body, ')
          ..write('whenEpochMs: $whenEpochMs, ')
          ..write('focusBucket: $focusBucket, ')
          ..write('unread: $unread, ')
          ..write('pinned: $pinned, ')
          ..write('hasAttachments: $hasAttachments, ')
          ..write('rawHeaders: $rawHeaders, ')
          ..write('toRecipients: $toRecipients, ')
          ..write('ccRecipients: $ccRecipients, ')
          ..write('starred: $starred, ')
          ..write('threadId: $threadId, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('trashedAt: $trashedAt, ')
          ..write('isDraft: $isDraft, ')
          ..write('draftSyncProviderId: $draftSyncProviderId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    accountId,
    folderId,
    providerId,
    messageIdHeader,
    fromName,
    fromAddress,
    subject,
    snippet,
    body,
    whenEpochMs,
    focusBucket,
    unread,
    pinned,
    hasAttachments,
    rawHeaders,
    toRecipients,
    ccRecipients,
    starred,
    threadId,
    snoozedUntil,
    trashedAt,
    isDraft,
    draftSyncProviderId,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.folderId == this.folderId &&
          other.providerId == this.providerId &&
          other.messageIdHeader == this.messageIdHeader &&
          other.fromName == this.fromName &&
          other.fromAddress == this.fromAddress &&
          other.subject == this.subject &&
          other.snippet == this.snippet &&
          other.body == this.body &&
          other.whenEpochMs == this.whenEpochMs &&
          other.focusBucket == this.focusBucket &&
          other.unread == this.unread &&
          other.pinned == this.pinned &&
          other.hasAttachments == this.hasAttachments &&
          other.rawHeaders == this.rawHeaders &&
          other.toRecipients == this.toRecipients &&
          other.ccRecipients == this.ccRecipients &&
          other.starred == this.starred &&
          other.threadId == this.threadId &&
          other.snoozedUntil == this.snoozedUntil &&
          other.trashedAt == this.trashedAt &&
          other.isDraft == this.isDraft &&
          other.draftSyncProviderId == this.draftSyncProviderId);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> folderId;
  final Value<String> providerId;
  final Value<String> messageIdHeader;
  final Value<String> fromName;
  final Value<String> fromAddress;
  final Value<String> subject;
  final Value<String> snippet;
  final Value<String?> body;
  final Value<int> whenEpochMs;
  final Value<String> focusBucket;
  final Value<bool> unread;
  final Value<bool> pinned;
  final Value<bool> hasAttachments;
  final Value<String?> rawHeaders;
  final Value<String> toRecipients;
  final Value<String> ccRecipients;
  final Value<bool> starred;
  final Value<String?> threadId;
  final Value<int?> snoozedUntil;
  final Value<int?> trashedAt;
  final Value<bool> isDraft;
  final Value<String?> draftSyncProviderId;
  final Value<int> rowid;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.folderId = const Value.absent(),
    this.providerId = const Value.absent(),
    this.messageIdHeader = const Value.absent(),
    this.fromName = const Value.absent(),
    this.fromAddress = const Value.absent(),
    this.subject = const Value.absent(),
    this.snippet = const Value.absent(),
    this.body = const Value.absent(),
    this.whenEpochMs = const Value.absent(),
    this.focusBucket = const Value.absent(),
    this.unread = const Value.absent(),
    this.pinned = const Value.absent(),
    this.hasAttachments = const Value.absent(),
    this.rawHeaders = const Value.absent(),
    this.toRecipients = const Value.absent(),
    this.ccRecipients = const Value.absent(),
    this.starred = const Value.absent(),
    this.threadId = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.trashedAt = const Value.absent(),
    this.isDraft = const Value.absent(),
    this.draftSyncProviderId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String id,
    required String accountId,
    required String folderId,
    required String providerId,
    required String messageIdHeader,
    required String fromName,
    required String fromAddress,
    required String subject,
    required String snippet,
    this.body = const Value.absent(),
    required int whenEpochMs,
    required String focusBucket,
    this.unread = const Value.absent(),
    this.pinned = const Value.absent(),
    this.hasAttachments = const Value.absent(),
    this.rawHeaders = const Value.absent(),
    this.toRecipients = const Value.absent(),
    this.ccRecipients = const Value.absent(),
    this.starred = const Value.absent(),
    this.threadId = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.trashedAt = const Value.absent(),
    this.isDraft = const Value.absent(),
    this.draftSyncProviderId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       folderId = Value(folderId),
       providerId = Value(providerId),
       messageIdHeader = Value(messageIdHeader),
       fromName = Value(fromName),
       fromAddress = Value(fromAddress),
       subject = Value(subject),
       snippet = Value(snippet),
       whenEpochMs = Value(whenEpochMs),
       focusBucket = Value(focusBucket);
  static Insertable<Message> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? folderId,
    Expression<String>? providerId,
    Expression<String>? messageIdHeader,
    Expression<String>? fromName,
    Expression<String>? fromAddress,
    Expression<String>? subject,
    Expression<String>? snippet,
    Expression<String>? body,
    Expression<int>? whenEpochMs,
    Expression<String>? focusBucket,
    Expression<bool>? unread,
    Expression<bool>? pinned,
    Expression<bool>? hasAttachments,
    Expression<String>? rawHeaders,
    Expression<String>? toRecipients,
    Expression<String>? ccRecipients,
    Expression<bool>? starred,
    Expression<String>? threadId,
    Expression<int>? snoozedUntil,
    Expression<int>? trashedAt,
    Expression<bool>? isDraft,
    Expression<String>? draftSyncProviderId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (folderId != null) 'folder_id': folderId,
      if (providerId != null) 'provider_id': providerId,
      if (messageIdHeader != null) 'message_id_header': messageIdHeader,
      if (fromName != null) 'from_name': fromName,
      if (fromAddress != null) 'from_address': fromAddress,
      if (subject != null) 'subject': subject,
      if (snippet != null) 'snippet': snippet,
      if (body != null) 'body': body,
      if (whenEpochMs != null) 'when_epoch_ms': whenEpochMs,
      if (focusBucket != null) 'focus_bucket': focusBucket,
      if (unread != null) 'unread': unread,
      if (pinned != null) 'pinned': pinned,
      if (hasAttachments != null) 'has_attachments': hasAttachments,
      if (rawHeaders != null) 'raw_headers': rawHeaders,
      if (toRecipients != null) 'to_recipients': toRecipients,
      if (ccRecipients != null) 'cc_recipients': ccRecipients,
      if (starred != null) 'starred': starred,
      if (threadId != null) 'thread_id': threadId,
      if (snoozedUntil != null) 'snoozed_until': snoozedUntil,
      if (trashedAt != null) 'trashed_at': trashedAt,
      if (isDraft != null) 'is_draft': isDraft,
      if (draftSyncProviderId != null)
        'draft_sync_provider_id': draftSyncProviderId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? folderId,
    Value<String>? providerId,
    Value<String>? messageIdHeader,
    Value<String>? fromName,
    Value<String>? fromAddress,
    Value<String>? subject,
    Value<String>? snippet,
    Value<String?>? body,
    Value<int>? whenEpochMs,
    Value<String>? focusBucket,
    Value<bool>? unread,
    Value<bool>? pinned,
    Value<bool>? hasAttachments,
    Value<String?>? rawHeaders,
    Value<String>? toRecipients,
    Value<String>? ccRecipients,
    Value<bool>? starred,
    Value<String?>? threadId,
    Value<int?>? snoozedUntil,
    Value<int?>? trashedAt,
    Value<bool>? isDraft,
    Value<String?>? draftSyncProviderId,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      folderId: folderId ?? this.folderId,
      providerId: providerId ?? this.providerId,
      messageIdHeader: messageIdHeader ?? this.messageIdHeader,
      fromName: fromName ?? this.fromName,
      fromAddress: fromAddress ?? this.fromAddress,
      subject: subject ?? this.subject,
      snippet: snippet ?? this.snippet,
      body: body ?? this.body,
      whenEpochMs: whenEpochMs ?? this.whenEpochMs,
      focusBucket: focusBucket ?? this.focusBucket,
      unread: unread ?? this.unread,
      pinned: pinned ?? this.pinned,
      hasAttachments: hasAttachments ?? this.hasAttachments,
      rawHeaders: rawHeaders ?? this.rawHeaders,
      toRecipients: toRecipients ?? this.toRecipients,
      ccRecipients: ccRecipients ?? this.ccRecipients,
      starred: starred ?? this.starred,
      threadId: threadId ?? this.threadId,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      trashedAt: trashedAt ?? this.trashedAt,
      isDraft: isDraft ?? this.isDraft,
      draftSyncProviderId: draftSyncProviderId ?? this.draftSyncProviderId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (messageIdHeader.present) {
      map['message_id_header'] = Variable<String>(messageIdHeader.value);
    }
    if (fromName.present) {
      map['from_name'] = Variable<String>(fromName.value);
    }
    if (fromAddress.present) {
      map['from_address'] = Variable<String>(fromAddress.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (snippet.present) {
      map['snippet'] = Variable<String>(snippet.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (whenEpochMs.present) {
      map['when_epoch_ms'] = Variable<int>(whenEpochMs.value);
    }
    if (focusBucket.present) {
      map['focus_bucket'] = Variable<String>(focusBucket.value);
    }
    if (unread.present) {
      map['unread'] = Variable<bool>(unread.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (hasAttachments.present) {
      map['has_attachments'] = Variable<bool>(hasAttachments.value);
    }
    if (rawHeaders.present) {
      map['raw_headers'] = Variable<String>(rawHeaders.value);
    }
    if (toRecipients.present) {
      map['to_recipients'] = Variable<String>(toRecipients.value);
    }
    if (ccRecipients.present) {
      map['cc_recipients'] = Variable<String>(ccRecipients.value);
    }
    if (starred.present) {
      map['starred'] = Variable<bool>(starred.value);
    }
    if (threadId.present) {
      map['thread_id'] = Variable<String>(threadId.value);
    }
    if (snoozedUntil.present) {
      map['snoozed_until'] = Variable<int>(snoozedUntil.value);
    }
    if (trashedAt.present) {
      map['trashed_at'] = Variable<int>(trashedAt.value);
    }
    if (isDraft.present) {
      map['is_draft'] = Variable<bool>(isDraft.value);
    }
    if (draftSyncProviderId.present) {
      map['draft_sync_provider_id'] = Variable<String>(
        draftSyncProviderId.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('folderId: $folderId, ')
          ..write('providerId: $providerId, ')
          ..write('messageIdHeader: $messageIdHeader, ')
          ..write('fromName: $fromName, ')
          ..write('fromAddress: $fromAddress, ')
          ..write('subject: $subject, ')
          ..write('snippet: $snippet, ')
          ..write('body: $body, ')
          ..write('whenEpochMs: $whenEpochMs, ')
          ..write('focusBucket: $focusBucket, ')
          ..write('unread: $unread, ')
          ..write('pinned: $pinned, ')
          ..write('hasAttachments: $hasAttachments, ')
          ..write('rawHeaders: $rawHeaders, ')
          ..write('toRecipients: $toRecipients, ')
          ..write('ccRecipients: $ccRecipients, ')
          ..write('starred: $starred, ')
          ..write('threadId: $threadId, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('trashedAt: $trashedAt, ')
          ..write('isDraft: $isDraft, ')
          ..write('draftSyncProviderId: $draftSyncProviderId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FocusRulesTable extends FocusRules
    with TableInfo<$FocusRulesTable, FocusRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FocusRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _patternMeta = const VerificationMeta(
    'pattern',
  );
  @override
  late final GeneratedColumn<String> pattern = GeneratedColumn<String>(
    'pattern',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matchTypeMeta = const VerificationMeta(
    'matchType',
  );
  @override
  late final GeneratedColumn<String> matchType = GeneratedColumn<String>(
    'match_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (match_type IN (\'sender\', \'domain\'))',
  );
  static const VerificationMeta _bucketMeta = const VerificationMeta('bucket');
  @override
  late final GeneratedColumn<String> bucket = GeneratedColumn<String>(
    'bucket',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (bucket IN (\'focused\', \'other\'))',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    pattern,
    matchType,
    bucket,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'focus_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<FocusRule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('pattern')) {
      context.handle(
        _patternMeta,
        pattern.isAcceptableOrUnknown(data['pattern']!, _patternMeta),
      );
    } else if (isInserting) {
      context.missing(_patternMeta);
    }
    if (data.containsKey('match_type')) {
      context.handle(
        _matchTypeMeta,
        matchType.isAcceptableOrUnknown(data['match_type']!, _matchTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_matchTypeMeta);
    }
    if (data.containsKey('bucket')) {
      context.handle(
        _bucketMeta,
        bucket.isAcceptableOrUnknown(data['bucket']!, _bucketMeta),
      );
    } else if (isInserting) {
      context.missing(_bucketMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FocusRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FocusRule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      pattern: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pattern'],
      )!,
      matchType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_type'],
      )!,
      bucket: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bucket'],
      )!,
    );
  }

  @override
  $FocusRulesTable createAlias(String alias) {
    return $FocusRulesTable(attachedDatabase, alias);
  }
}

class FocusRule extends DataClass implements Insertable<FocusRule> {
  final String id;
  final String? accountId;
  final String pattern;
  final String matchType;
  final String bucket;
  const FocusRule({
    required this.id,
    this.accountId,
    required this.pattern,
    required this.matchType,
    required this.bucket,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    map['pattern'] = Variable<String>(pattern);
    map['match_type'] = Variable<String>(matchType);
    map['bucket'] = Variable<String>(bucket);
    return map;
  }

  FocusRulesCompanion toCompanion(bool nullToAbsent) {
    return FocusRulesCompanion(
      id: Value(id),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      pattern: Value(pattern),
      matchType: Value(matchType),
      bucket: Value(bucket),
    );
  }

  factory FocusRule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FocusRule(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      pattern: serializer.fromJson<String>(json['pattern']),
      matchType: serializer.fromJson<String>(json['matchType']),
      bucket: serializer.fromJson<String>(json['bucket']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String?>(accountId),
      'pattern': serializer.toJson<String>(pattern),
      'matchType': serializer.toJson<String>(matchType),
      'bucket': serializer.toJson<String>(bucket),
    };
  }

  FocusRule copyWith({
    String? id,
    Value<String?> accountId = const Value.absent(),
    String? pattern,
    String? matchType,
    String? bucket,
  }) => FocusRule(
    id: id ?? this.id,
    accountId: accountId.present ? accountId.value : this.accountId,
    pattern: pattern ?? this.pattern,
    matchType: matchType ?? this.matchType,
    bucket: bucket ?? this.bucket,
  );
  FocusRule copyWithCompanion(FocusRulesCompanion data) {
    return FocusRule(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      pattern: data.pattern.present ? data.pattern.value : this.pattern,
      matchType: data.matchType.present ? data.matchType.value : this.matchType,
      bucket: data.bucket.present ? data.bucket.value : this.bucket,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FocusRule(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('pattern: $pattern, ')
          ..write('matchType: $matchType, ')
          ..write('bucket: $bucket')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, accountId, pattern, matchType, bucket);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FocusRule &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.pattern == this.pattern &&
          other.matchType == this.matchType &&
          other.bucket == this.bucket);
}

class FocusRulesCompanion extends UpdateCompanion<FocusRule> {
  final Value<String> id;
  final Value<String?> accountId;
  final Value<String> pattern;
  final Value<String> matchType;
  final Value<String> bucket;
  final Value<int> rowid;
  const FocusRulesCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.pattern = const Value.absent(),
    this.matchType = const Value.absent(),
    this.bucket = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FocusRulesCompanion.insert({
    required String id,
    this.accountId = const Value.absent(),
    required String pattern,
    required String matchType,
    required String bucket,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pattern = Value(pattern),
       matchType = Value(matchType),
       bucket = Value(bucket);
  static Insertable<FocusRule> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? pattern,
    Expression<String>? matchType,
    Expression<String>? bucket,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (pattern != null) 'pattern': pattern,
      if (matchType != null) 'match_type': matchType,
      if (bucket != null) 'bucket': bucket,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FocusRulesCompanion copyWith({
    Value<String>? id,
    Value<String?>? accountId,
    Value<String>? pattern,
    Value<String>? matchType,
    Value<String>? bucket,
    Value<int>? rowid,
  }) {
    return FocusRulesCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      pattern: pattern ?? this.pattern,
      matchType: matchType ?? this.matchType,
      bucket: bucket ?? this.bucket,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (pattern.present) {
      map['pattern'] = Variable<String>(pattern.value);
    }
    if (matchType.present) {
      map['match_type'] = Variable<String>(matchType.value);
    }
    if (bucket.present) {
      map['bucket'] = Variable<String>(bucket.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FocusRulesCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('pattern: $pattern, ')
          ..write('matchType: $matchType, ')
          ..write('bucket: $bucket, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _recipientsJsonMeta = const VerificationMeta(
    'recipientsJson',
  );
  @override
  late final GeneratedColumn<String> recipientsJson = GeneratedColumn<String>(
    'to_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (state IN (\'queued\', \'sending\', \'sent\', \'failed\'))',
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ccJsonMeta = const VerificationMeta('ccJson');
  @override
  late final GeneratedColumn<String> ccJson = GeneratedColumn<String>(
    'cc_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bccJsonMeta = const VerificationMeta(
    'bccJson',
  );
  @override
  late final GeneratedColumn<String> bccJson = GeneratedColumn<String>(
    'bcc_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _composeModeMeta = const VerificationMeta(
    'composeMode',
  );
  @override
  late final GeneratedColumn<String> composeMode = GeneratedColumn<String>(
    'compose_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('new'),
  );
  static const VerificationMeta _inReplyToMeta = const VerificationMeta(
    'inReplyTo',
  );
  @override
  late final GeneratedColumn<String> inReplyTo = GeneratedColumn<String>(
    'in_reply_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referencesJsonMeta = const VerificationMeta(
    'referencesJson',
  );
  @override
  late final GeneratedColumn<String> referencesJson = GeneratedColumn<String>(
    'references_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attachmentRefsJsonMeta =
      const VerificationMeta('attachmentRefsJson');
  @override
  late final GeneratedColumn<String> attachmentRefsJson =
      GeneratedColumn<String>(
        'attachment_refs_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _signatureIdMeta = const VerificationMeta(
    'signatureId',
  );
  @override
  late final GeneratedColumn<String> signatureId = GeneratedColumn<String>(
    'signature_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sendAfterMeta = const VerificationMeta(
    'sendAfter',
  );
  @override
  late final GeneratedColumn<int> sendAfter = GeneratedColumn<int>(
    'send_after',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    recipientsJson,
    subject,
    body,
    state,
    attempts,
    lastError,
    createdAt,
    ccJson,
    bccJson,
    composeMode,
    inReplyTo,
    referencesJson,
    attachmentRefsJson,
    signatureId,
    sendAfter,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('to_json')) {
      context.handle(
        _recipientsJsonMeta,
        recipientsJson.isAcceptableOrUnknown(
          data['to_json']!,
          _recipientsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recipientsJsonMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('cc_json')) {
      context.handle(
        _ccJsonMeta,
        ccJson.isAcceptableOrUnknown(data['cc_json']!, _ccJsonMeta),
      );
    }
    if (data.containsKey('bcc_json')) {
      context.handle(
        _bccJsonMeta,
        bccJson.isAcceptableOrUnknown(data['bcc_json']!, _bccJsonMeta),
      );
    }
    if (data.containsKey('compose_mode')) {
      context.handle(
        _composeModeMeta,
        composeMode.isAcceptableOrUnknown(
          data['compose_mode']!,
          _composeModeMeta,
        ),
      );
    }
    if (data.containsKey('in_reply_to')) {
      context.handle(
        _inReplyToMeta,
        inReplyTo.isAcceptableOrUnknown(data['in_reply_to']!, _inReplyToMeta),
      );
    }
    if (data.containsKey('references_json')) {
      context.handle(
        _referencesJsonMeta,
        referencesJson.isAcceptableOrUnknown(
          data['references_json']!,
          _referencesJsonMeta,
        ),
      );
    }
    if (data.containsKey('attachment_refs_json')) {
      context.handle(
        _attachmentRefsJsonMeta,
        attachmentRefsJson.isAcceptableOrUnknown(
          data['attachment_refs_json']!,
          _attachmentRefsJsonMeta,
        ),
      );
    }
    if (data.containsKey('signature_id')) {
      context.handle(
        _signatureIdMeta,
        signatureId.isAcceptableOrUnknown(
          data['signature_id']!,
          _signatureIdMeta,
        ),
      );
    }
    if (data.containsKey('send_after')) {
      context.handle(
        _sendAfterMeta,
        sendAfter.isAcceptableOrUnknown(data['send_after']!, _sendAfterMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      recipientsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_json'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      ccJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cc_json'],
      ),
      bccJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bcc_json'],
      ),
      composeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}compose_mode'],
      )!,
      inReplyTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}in_reply_to'],
      ),
      referencesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}references_json'],
      ),
      attachmentRefsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_refs_json'],
      ),
      signatureId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature_id'],
      ),
      sendAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}send_after'],
      ),
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxData extends DataClass implements Insertable<OutboxData> {
  final String id;
  final String accountId;
  final String recipientsJson;
  final String subject;
  final String body;
  final String state;
  final int attempts;
  final String? lastError;
  final int createdAt;
  final String? ccJson;
  final String? bccJson;
  final String composeMode;
  final String? inReplyTo;
  final String? referencesJson;
  final String? attachmentRefsJson;
  final String? signatureId;
  final int? sendAfter;
  const OutboxData({
    required this.id,
    required this.accountId,
    required this.recipientsJson,
    required this.subject,
    required this.body,
    required this.state,
    required this.attempts,
    this.lastError,
    required this.createdAt,
    this.ccJson,
    this.bccJson,
    required this.composeMode,
    this.inReplyTo,
    this.referencesJson,
    this.attachmentRefsJson,
    this.signatureId,
    this.sendAfter,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['to_json'] = Variable<String>(recipientsJson);
    map['subject'] = Variable<String>(subject);
    map['body'] = Variable<String>(body);
    map['state'] = Variable<String>(state);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || ccJson != null) {
      map['cc_json'] = Variable<String>(ccJson);
    }
    if (!nullToAbsent || bccJson != null) {
      map['bcc_json'] = Variable<String>(bccJson);
    }
    map['compose_mode'] = Variable<String>(composeMode);
    if (!nullToAbsent || inReplyTo != null) {
      map['in_reply_to'] = Variable<String>(inReplyTo);
    }
    if (!nullToAbsent || referencesJson != null) {
      map['references_json'] = Variable<String>(referencesJson);
    }
    if (!nullToAbsent || attachmentRefsJson != null) {
      map['attachment_refs_json'] = Variable<String>(attachmentRefsJson);
    }
    if (!nullToAbsent || signatureId != null) {
      map['signature_id'] = Variable<String>(signatureId);
    }
    if (!nullToAbsent || sendAfter != null) {
      map['send_after'] = Variable<int>(sendAfter);
    }
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      id: Value(id),
      accountId: Value(accountId),
      recipientsJson: Value(recipientsJson),
      subject: Value(subject),
      body: Value(body),
      state: Value(state),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      ccJson: ccJson == null && nullToAbsent
          ? const Value.absent()
          : Value(ccJson),
      bccJson: bccJson == null && nullToAbsent
          ? const Value.absent()
          : Value(bccJson),
      composeMode: Value(composeMode),
      inReplyTo: inReplyTo == null && nullToAbsent
          ? const Value.absent()
          : Value(inReplyTo),
      referencesJson: referencesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(referencesJson),
      attachmentRefsJson: attachmentRefsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentRefsJson),
      signatureId: signatureId == null && nullToAbsent
          ? const Value.absent()
          : Value(signatureId),
      sendAfter: sendAfter == null && nullToAbsent
          ? const Value.absent()
          : Value(sendAfter),
    );
  }

  factory OutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxData(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      recipientsJson: serializer.fromJson<String>(json['recipientsJson']),
      subject: serializer.fromJson<String>(json['subject']),
      body: serializer.fromJson<String>(json['body']),
      state: serializer.fromJson<String>(json['state']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      ccJson: serializer.fromJson<String?>(json['ccJson']),
      bccJson: serializer.fromJson<String?>(json['bccJson']),
      composeMode: serializer.fromJson<String>(json['composeMode']),
      inReplyTo: serializer.fromJson<String?>(json['inReplyTo']),
      referencesJson: serializer.fromJson<String?>(json['referencesJson']),
      attachmentRefsJson: serializer.fromJson<String?>(
        json['attachmentRefsJson'],
      ),
      signatureId: serializer.fromJson<String?>(json['signatureId']),
      sendAfter: serializer.fromJson<int?>(json['sendAfter']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'recipientsJson': serializer.toJson<String>(recipientsJson),
      'subject': serializer.toJson<String>(subject),
      'body': serializer.toJson<String>(body),
      'state': serializer.toJson<String>(state),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<int>(createdAt),
      'ccJson': serializer.toJson<String?>(ccJson),
      'bccJson': serializer.toJson<String?>(bccJson),
      'composeMode': serializer.toJson<String>(composeMode),
      'inReplyTo': serializer.toJson<String?>(inReplyTo),
      'referencesJson': serializer.toJson<String?>(referencesJson),
      'attachmentRefsJson': serializer.toJson<String?>(attachmentRefsJson),
      'signatureId': serializer.toJson<String?>(signatureId),
      'sendAfter': serializer.toJson<int?>(sendAfter),
    };
  }

  OutboxData copyWith({
    String? id,
    String? accountId,
    String? recipientsJson,
    String? subject,
    String? body,
    String? state,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    int? createdAt,
    Value<String?> ccJson = const Value.absent(),
    Value<String?> bccJson = const Value.absent(),
    String? composeMode,
    Value<String?> inReplyTo = const Value.absent(),
    Value<String?> referencesJson = const Value.absent(),
    Value<String?> attachmentRefsJson = const Value.absent(),
    Value<String?> signatureId = const Value.absent(),
    Value<int?> sendAfter = const Value.absent(),
  }) => OutboxData(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    recipientsJson: recipientsJson ?? this.recipientsJson,
    subject: subject ?? this.subject,
    body: body ?? this.body,
    state: state ?? this.state,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    ccJson: ccJson.present ? ccJson.value : this.ccJson,
    bccJson: bccJson.present ? bccJson.value : this.bccJson,
    composeMode: composeMode ?? this.composeMode,
    inReplyTo: inReplyTo.present ? inReplyTo.value : this.inReplyTo,
    referencesJson: referencesJson.present
        ? referencesJson.value
        : this.referencesJson,
    attachmentRefsJson: attachmentRefsJson.present
        ? attachmentRefsJson.value
        : this.attachmentRefsJson,
    signatureId: signatureId.present ? signatureId.value : this.signatureId,
    sendAfter: sendAfter.present ? sendAfter.value : this.sendAfter,
  );
  OutboxData copyWithCompanion(OutboxCompanion data) {
    return OutboxData(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      recipientsJson: data.recipientsJson.present
          ? data.recipientsJson.value
          : this.recipientsJson,
      subject: data.subject.present ? data.subject.value : this.subject,
      body: data.body.present ? data.body.value : this.body,
      state: data.state.present ? data.state.value : this.state,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      ccJson: data.ccJson.present ? data.ccJson.value : this.ccJson,
      bccJson: data.bccJson.present ? data.bccJson.value : this.bccJson,
      composeMode: data.composeMode.present
          ? data.composeMode.value
          : this.composeMode,
      inReplyTo: data.inReplyTo.present ? data.inReplyTo.value : this.inReplyTo,
      referencesJson: data.referencesJson.present
          ? data.referencesJson.value
          : this.referencesJson,
      attachmentRefsJson: data.attachmentRefsJson.present
          ? data.attachmentRefsJson.value
          : this.attachmentRefsJson,
      signatureId: data.signatureId.present
          ? data.signatureId.value
          : this.signatureId,
      sendAfter: data.sendAfter.present ? data.sendAfter.value : this.sendAfter,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxData(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('recipientsJson: $recipientsJson, ')
          ..write('subject: $subject, ')
          ..write('body: $body, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('ccJson: $ccJson, ')
          ..write('bccJson: $bccJson, ')
          ..write('composeMode: $composeMode, ')
          ..write('inReplyTo: $inReplyTo, ')
          ..write('referencesJson: $referencesJson, ')
          ..write('attachmentRefsJson: $attachmentRefsJson, ')
          ..write('signatureId: $signatureId, ')
          ..write('sendAfter: $sendAfter')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    recipientsJson,
    subject,
    body,
    state,
    attempts,
    lastError,
    createdAt,
    ccJson,
    bccJson,
    composeMode,
    inReplyTo,
    referencesJson,
    attachmentRefsJson,
    signatureId,
    sendAfter,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxData &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.recipientsJson == this.recipientsJson &&
          other.subject == this.subject &&
          other.body == this.body &&
          other.state == this.state &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.ccJson == this.ccJson &&
          other.bccJson == this.bccJson &&
          other.composeMode == this.composeMode &&
          other.inReplyTo == this.inReplyTo &&
          other.referencesJson == this.referencesJson &&
          other.attachmentRefsJson == this.attachmentRefsJson &&
          other.signatureId == this.signatureId &&
          other.sendAfter == this.sendAfter);
}

class OutboxCompanion extends UpdateCompanion<OutboxData> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> recipientsJson;
  final Value<String> subject;
  final Value<String> body;
  final Value<String> state;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<int> createdAt;
  final Value<String?> ccJson;
  final Value<String?> bccJson;
  final Value<String> composeMode;
  final Value<String?> inReplyTo;
  final Value<String?> referencesJson;
  final Value<String?> attachmentRefsJson;
  final Value<String?> signatureId;
  final Value<int?> sendAfter;
  final Value<int> rowid;
  const OutboxCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.recipientsJson = const Value.absent(),
    this.subject = const Value.absent(),
    this.body = const Value.absent(),
    this.state = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.ccJson = const Value.absent(),
    this.bccJson = const Value.absent(),
    this.composeMode = const Value.absent(),
    this.inReplyTo = const Value.absent(),
    this.referencesJson = const Value.absent(),
    this.attachmentRefsJson = const Value.absent(),
    this.signatureId = const Value.absent(),
    this.sendAfter = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxCompanion.insert({
    required String id,
    required String accountId,
    required String recipientsJson,
    required String subject,
    required String body,
    required String state,
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    required int createdAt,
    this.ccJson = const Value.absent(),
    this.bccJson = const Value.absent(),
    this.composeMode = const Value.absent(),
    this.inReplyTo = const Value.absent(),
    this.referencesJson = const Value.absent(),
    this.attachmentRefsJson = const Value.absent(),
    this.signatureId = const Value.absent(),
    this.sendAfter = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       recipientsJson = Value(recipientsJson),
       subject = Value(subject),
       body = Value(body),
       state = Value(state),
       createdAt = Value(createdAt);
  static Insertable<OutboxData> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? recipientsJson,
    Expression<String>? subject,
    Expression<String>? body,
    Expression<String>? state,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<int>? createdAt,
    Expression<String>? ccJson,
    Expression<String>? bccJson,
    Expression<String>? composeMode,
    Expression<String>? inReplyTo,
    Expression<String>? referencesJson,
    Expression<String>? attachmentRefsJson,
    Expression<String>? signatureId,
    Expression<int>? sendAfter,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (recipientsJson != null) 'to_json': recipientsJson,
      if (subject != null) 'subject': subject,
      if (body != null) 'body': body,
      if (state != null) 'state': state,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (ccJson != null) 'cc_json': ccJson,
      if (bccJson != null) 'bcc_json': bccJson,
      if (composeMode != null) 'compose_mode': composeMode,
      if (inReplyTo != null) 'in_reply_to': inReplyTo,
      if (referencesJson != null) 'references_json': referencesJson,
      if (attachmentRefsJson != null)
        'attachment_refs_json': attachmentRefsJson,
      if (signatureId != null) 'signature_id': signatureId,
      if (sendAfter != null) 'send_after': sendAfter,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? recipientsJson,
    Value<String>? subject,
    Value<String>? body,
    Value<String>? state,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<int>? createdAt,
    Value<String?>? ccJson,
    Value<String?>? bccJson,
    Value<String>? composeMode,
    Value<String?>? inReplyTo,
    Value<String?>? referencesJson,
    Value<String?>? attachmentRefsJson,
    Value<String?>? signatureId,
    Value<int?>? sendAfter,
    Value<int>? rowid,
  }) {
    return OutboxCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      recipientsJson: recipientsJson ?? this.recipientsJson,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      state: state ?? this.state,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      ccJson: ccJson ?? this.ccJson,
      bccJson: bccJson ?? this.bccJson,
      composeMode: composeMode ?? this.composeMode,
      inReplyTo: inReplyTo ?? this.inReplyTo,
      referencesJson: referencesJson ?? this.referencesJson,
      attachmentRefsJson: attachmentRefsJson ?? this.attachmentRefsJson,
      signatureId: signatureId ?? this.signatureId,
      sendAfter: sendAfter ?? this.sendAfter,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (recipientsJson.present) {
      map['to_json'] = Variable<String>(recipientsJson.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (ccJson.present) {
      map['cc_json'] = Variable<String>(ccJson.value);
    }
    if (bccJson.present) {
      map['bcc_json'] = Variable<String>(bccJson.value);
    }
    if (composeMode.present) {
      map['compose_mode'] = Variable<String>(composeMode.value);
    }
    if (inReplyTo.present) {
      map['in_reply_to'] = Variable<String>(inReplyTo.value);
    }
    if (referencesJson.present) {
      map['references_json'] = Variable<String>(referencesJson.value);
    }
    if (attachmentRefsJson.present) {
      map['attachment_refs_json'] = Variable<String>(attachmentRefsJson.value);
    }
    if (signatureId.present) {
      map['signature_id'] = Variable<String>(signatureId.value);
    }
    if (sendAfter.present) {
      map['send_after'] = Variable<int>(sendAfter.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('recipientsJson: $recipientsJson, ')
          ..write('subject: $subject, ')
          ..write('body: $body, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('ccJson: $ccJson, ')
          ..write('bccJson: $bccJson, ')
          ..write('composeMode: $composeMode, ')
          ..write('inReplyTo: $inReplyTo, ')
          ..write('referencesJson: $referencesJson, ')
          ..write('attachmentRefsJson: $attachmentRefsJson, ')
          ..write('signatureId: $signatureId, ')
          ..write('sendAfter: $sendAfter, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JobsTable extends Jobs with TableInfo<$JobsTable, Job> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (status IN (\'pending\', \'running\', \'done\', \'failed\'))',
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cursorJsonMeta = const VerificationMeta(
    'cursorJson',
  );
  @override
  late final GeneratedColumn<String> cursorJson = GeneratedColumn<String>(
    'cursor_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    type,
    status,
    payloadJson,
    cursorJson,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Job> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    }
    if (data.containsKey('cursor_json')) {
      context.handle(
        _cursorJsonMeta,
        cursorJson.isAcceptableOrUnknown(data['cursor_json']!, _cursorJsonMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Job map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Job(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      ),
      cursorJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor_json'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $JobsTable createAlias(String alias) {
    return $JobsTable(attachedDatabase, alias);
  }
}

class Job extends DataClass implements Insertable<Job> {
  final String id;
  final String accountId;
  final String type;
  final String status;
  final String? payloadJson;
  final String? cursorJson;
  final int updatedAt;
  const Job({
    required this.id,
    required this.accountId,
    required this.type,
    required this.status,
    this.payloadJson,
    this.cursorJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['type'] = Variable<String>(type);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || payloadJson != null) {
      map['payload_json'] = Variable<String>(payloadJson);
    }
    if (!nullToAbsent || cursorJson != null) {
      map['cursor_json'] = Variable<String>(cursorJson);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  JobsCompanion toCompanion(bool nullToAbsent) {
    return JobsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      type: Value(type),
      status: Value(status),
      payloadJson: payloadJson == null && nullToAbsent
          ? const Value.absent()
          : Value(payloadJson),
      cursorJson: cursorJson == null && nullToAbsent
          ? const Value.absent()
          : Value(cursorJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory Job.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Job(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      type: serializer.fromJson<String>(json['type']),
      status: serializer.fromJson<String>(json['status']),
      payloadJson: serializer.fromJson<String?>(json['payloadJson']),
      cursorJson: serializer.fromJson<String?>(json['cursorJson']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'type': serializer.toJson<String>(type),
      'status': serializer.toJson<String>(status),
      'payloadJson': serializer.toJson<String?>(payloadJson),
      'cursorJson': serializer.toJson<String?>(cursorJson),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Job copyWith({
    String? id,
    String? accountId,
    String? type,
    String? status,
    Value<String?> payloadJson = const Value.absent(),
    Value<String?> cursorJson = const Value.absent(),
    int? updatedAt,
  }) => Job(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    type: type ?? this.type,
    status: status ?? this.status,
    payloadJson: payloadJson.present ? payloadJson.value : this.payloadJson,
    cursorJson: cursorJson.present ? cursorJson.value : this.cursorJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Job copyWithCompanion(JobsCompanion data) {
    return Job(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      type: data.type.present ? data.type.value : this.type,
      status: data.status.present ? data.status.value : this.status,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      cursorJson: data.cursorJson.present
          ? data.cursorJson.value
          : this.cursorJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Job(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('cursorJson: $cursorJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    type,
    status,
    payloadJson,
    cursorJson,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Job &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.type == this.type &&
          other.status == this.status &&
          other.payloadJson == this.payloadJson &&
          other.cursorJson == this.cursorJson &&
          other.updatedAt == this.updatedAt);
}

class JobsCompanion extends UpdateCompanion<Job> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> type;
  final Value<String> status;
  final Value<String?> payloadJson;
  final Value<String?> cursorJson;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const JobsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.type = const Value.absent(),
    this.status = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.cursorJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JobsCompanion.insert({
    required String id,
    required String accountId,
    required String type,
    required String status,
    this.payloadJson = const Value.absent(),
    this.cursorJson = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       type = Value(type),
       status = Value(status),
       updatedAt = Value(updatedAt);
  static Insertable<Job> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? type,
    Expression<String>? status,
    Expression<String>? payloadJson,
    Expression<String>? cursorJson,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (cursorJson != null) 'cursor_json': cursorJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JobsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? type,
    Value<String>? status,
    Value<String?>? payloadJson,
    Value<String?>? cursorJson,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return JobsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      status: status ?? this.status,
      payloadJson: payloadJson ?? this.payloadJson,
      cursorJson: cursorJson ?? this.cursorJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (cursorJson.present) {
      map['cursor_json'] = Variable<String>(cursorJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('cursorJson: $cursorJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncCursorsTable extends SyncCursors
    with TableInfo<$SyncCursorsTable, SyncCursor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCursorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
    'folder_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorKeyMeta = const VerificationMeta(
    'cursorKey',
  );
  @override
  late final GeneratedColumn<String> cursorKey = GeneratedColumn<String>(
    'cursor_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorValueMeta = const VerificationMeta(
    'cursorValue',
  );
  @override
  late final GeneratedColumn<String> cursorValue = GeneratedColumn<String>(
    'cursor_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    folderId,
    cursorKey,
    cursorValue,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursors';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCursor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_folderIdMeta);
    }
    if (data.containsKey('cursor_key')) {
      context.handle(
        _cursorKeyMeta,
        cursorKey.isAcceptableOrUnknown(data['cursor_key']!, _cursorKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cursorKeyMeta);
    }
    if (data.containsKey('cursor_value')) {
      context.handle(
        _cursorValueMeta,
        cursorValue.isAcceptableOrUnknown(
          data['cursor_value']!,
          _cursorValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cursorValueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, folderId, cursorKey};
  @override
  SyncCursor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursor(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_id'],
      )!,
      cursorKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor_key'],
      )!,
      cursorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor_value'],
      )!,
    );
  }

  @override
  $SyncCursorsTable createAlias(String alias) {
    return $SyncCursorsTable(attachedDatabase, alias);
  }
}

class SyncCursor extends DataClass implements Insertable<SyncCursor> {
  final String accountId;
  final String folderId;
  final String cursorKey;
  final String cursorValue;
  const SyncCursor({
    required this.accountId,
    required this.folderId,
    required this.cursorKey,
    required this.cursorValue,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['folder_id'] = Variable<String>(folderId);
    map['cursor_key'] = Variable<String>(cursorKey);
    map['cursor_value'] = Variable<String>(cursorValue);
    return map;
  }

  SyncCursorsCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorsCompanion(
      accountId: Value(accountId),
      folderId: Value(folderId),
      cursorKey: Value(cursorKey),
      cursorValue: Value(cursorValue),
    );
  }

  factory SyncCursor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursor(
      accountId: serializer.fromJson<String>(json['accountId']),
      folderId: serializer.fromJson<String>(json['folderId']),
      cursorKey: serializer.fromJson<String>(json['cursorKey']),
      cursorValue: serializer.fromJson<String>(json['cursorValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'folderId': serializer.toJson<String>(folderId),
      'cursorKey': serializer.toJson<String>(cursorKey),
      'cursorValue': serializer.toJson<String>(cursorValue),
    };
  }

  SyncCursor copyWith({
    String? accountId,
    String? folderId,
    String? cursorKey,
    String? cursorValue,
  }) => SyncCursor(
    accountId: accountId ?? this.accountId,
    folderId: folderId ?? this.folderId,
    cursorKey: cursorKey ?? this.cursorKey,
    cursorValue: cursorValue ?? this.cursorValue,
  );
  SyncCursor copyWithCompanion(SyncCursorsCompanion data) {
    return SyncCursor(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      cursorKey: data.cursorKey.present ? data.cursorKey.value : this.cursorKey,
      cursorValue: data.cursorValue.present
          ? data.cursorValue.value
          : this.cursorValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursor(')
          ..write('accountId: $accountId, ')
          ..write('folderId: $folderId, ')
          ..write('cursorKey: $cursorKey, ')
          ..write('cursorValue: $cursorValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(accountId, folderId, cursorKey, cursorValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursor &&
          other.accountId == this.accountId &&
          other.folderId == this.folderId &&
          other.cursorKey == this.cursorKey &&
          other.cursorValue == this.cursorValue);
}

class SyncCursorsCompanion extends UpdateCompanion<SyncCursor> {
  final Value<String> accountId;
  final Value<String> folderId;
  final Value<String> cursorKey;
  final Value<String> cursorValue;
  final Value<int> rowid;
  const SyncCursorsCompanion({
    this.accountId = const Value.absent(),
    this.folderId = const Value.absent(),
    this.cursorKey = const Value.absent(),
    this.cursorValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCursorsCompanion.insert({
    required String accountId,
    required String folderId,
    required String cursorKey,
    required String cursorValue,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       folderId = Value(folderId),
       cursorKey = Value(cursorKey),
       cursorValue = Value(cursorValue);
  static Insertable<SyncCursor> custom({
    Expression<String>? accountId,
    Expression<String>? folderId,
    Expression<String>? cursorKey,
    Expression<String>? cursorValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (folderId != null) 'folder_id': folderId,
      if (cursorKey != null) 'cursor_key': cursorKey,
      if (cursorValue != null) 'cursor_value': cursorValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCursorsCompanion copyWith({
    Value<String>? accountId,
    Value<String>? folderId,
    Value<String>? cursorKey,
    Value<String>? cursorValue,
    Value<int>? rowid,
  }) {
    return SyncCursorsCompanion(
      accountId: accountId ?? this.accountId,
      folderId: folderId ?? this.folderId,
      cursorKey: cursorKey ?? this.cursorKey,
      cursorValue: cursorValue ?? this.cursorValue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (cursorKey.present) {
      map['cursor_key'] = Variable<String>(cursorKey.value);
    }
    if (cursorValue.present) {
      map['cursor_value'] = Variable<String>(cursorValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('folderId: $folderId, ')
          ..write('cursorKey: $cursorKey, ')
          ..write('cursorValue: $cursorValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WidgetSnapshotsTable extends WidgetSnapshots
    with TableInfo<$WidgetSnapshotsTable, WidgetSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WidgetSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, kind, payloadJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'widget_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<WidgetSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WidgetSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WidgetSnapshot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WidgetSnapshotsTable createAlias(String alias) {
    return $WidgetSnapshotsTable(attachedDatabase, alias);
  }
}

class WidgetSnapshot extends DataClass implements Insertable<WidgetSnapshot> {
  final String id;
  final String kind;
  final String payloadJson;
  final int updatedAt;
  const WidgetSnapshot({
    required this.id,
    required this.kind,
    required this.payloadJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['payload_json'] = Variable<String>(payloadJson);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  WidgetSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return WidgetSnapshotsCompanion(
      id: Value(id),
      kind: Value(kind),
      payloadJson: Value(payloadJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory WidgetSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WidgetSnapshot(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  WidgetSnapshot copyWith({
    String? id,
    String? kind,
    String? payloadJson,
    int? updatedAt,
  }) => WidgetSnapshot(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    payloadJson: payloadJson ?? this.payloadJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WidgetSnapshot copyWithCompanion(WidgetSnapshotsCompanion data) {
    return WidgetSnapshot(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WidgetSnapshot(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kind, payloadJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WidgetSnapshot &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.payloadJson == this.payloadJson &&
          other.updatedAt == this.updatedAt);
}

class WidgetSnapshotsCompanion extends UpdateCompanion<WidgetSnapshot> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> payloadJson;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const WidgetSnapshotsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WidgetSnapshotsCompanion.insert({
    required String id,
    required String kind,
    required String payloadJson,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       payloadJson = Value(payloadJson),
       updatedAt = Value(updatedAt);
  static Insertable<WidgetSnapshot> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? payloadJson,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WidgetSnapshotsCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? payloadJson,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return WidgetSnapshotsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      payloadJson: payloadJson ?? this.payloadJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WidgetSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncProfilesTable extends SyncProfiles
    with TableInfo<$SyncProfilesTable, SyncProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retentionDaysMeta = const VerificationMeta(
    'retentionDays',
  );
  @override
  late final GeneratedColumn<int> retentionDays = GeneratedColumn<int>(
    'retention_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderScopeJsonMeta = const VerificationMeta(
    'folderScopeJson',
  );
  @override
  late final GeneratedColumn<String> folderScopeJson = GeneratedColumn<String>(
    'folder_scope_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyPolicyMeta = const VerificationMeta(
    'bodyPolicy',
  );
  @override
  late final GeneratedColumn<String> bodyPolicy = GeneratedColumn<String>(
    'body_policy',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('on_open'),
  );
  static const VerificationMeta _attachmentMaxMbMeta = const VerificationMeta(
    'attachmentMaxMb',
  );
  @override
  late final GeneratedColumn<int> attachmentMaxMb = GeneratedColumn<int>(
    'attachment_max_mb',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(25),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    retentionDays,
    folderScopeJson,
    bodyPolicy,
    attachmentMaxMb,
    isDefault,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('retention_days')) {
      context.handle(
        _retentionDaysMeta,
        retentionDays.isAcceptableOrUnknown(
          data['retention_days']!,
          _retentionDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_retentionDaysMeta);
    }
    if (data.containsKey('folder_scope_json')) {
      context.handle(
        _folderScopeJsonMeta,
        folderScopeJson.isAcceptableOrUnknown(
          data['folder_scope_json']!,
          _folderScopeJsonMeta,
        ),
      );
    }
    if (data.containsKey('body_policy')) {
      context.handle(
        _bodyPolicyMeta,
        bodyPolicy.isAcceptableOrUnknown(data['body_policy']!, _bodyPolicyMeta),
      );
    }
    if (data.containsKey('attachment_max_mb')) {
      context.handle(
        _attachmentMaxMbMeta,
        attachmentMaxMb.isAcceptableOrUnknown(
          data['attachment_max_mb']!,
          _attachmentMaxMbMeta,
        ),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      retentionDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retention_days'],
      )!,
      folderScopeJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_scope_json'],
      ),
      bodyPolicy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_policy'],
      )!,
      attachmentMaxMb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attachment_max_mb'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
    );
  }

  @override
  $SyncProfilesTable createAlias(String alias) {
    return $SyncProfilesTable(attachedDatabase, alias);
  }
}

class SyncProfile extends DataClass implements Insertable<SyncProfile> {
  final String id;
  final String name;
  final int retentionDays;
  final String? folderScopeJson;
  final String bodyPolicy;
  final int attachmentMaxMb;
  final bool isDefault;
  const SyncProfile({
    required this.id,
    required this.name,
    required this.retentionDays,
    this.folderScopeJson,
    required this.bodyPolicy,
    required this.attachmentMaxMb,
    required this.isDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['retention_days'] = Variable<int>(retentionDays);
    if (!nullToAbsent || folderScopeJson != null) {
      map['folder_scope_json'] = Variable<String>(folderScopeJson);
    }
    map['body_policy'] = Variable<String>(bodyPolicy);
    map['attachment_max_mb'] = Variable<int>(attachmentMaxMb);
    map['is_default'] = Variable<bool>(isDefault);
    return map;
  }

  SyncProfilesCompanion toCompanion(bool nullToAbsent) {
    return SyncProfilesCompanion(
      id: Value(id),
      name: Value(name),
      retentionDays: Value(retentionDays),
      folderScopeJson: folderScopeJson == null && nullToAbsent
          ? const Value.absent()
          : Value(folderScopeJson),
      bodyPolicy: Value(bodyPolicy),
      attachmentMaxMb: Value(attachmentMaxMb),
      isDefault: Value(isDefault),
    );
  }

  factory SyncProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncProfile(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      retentionDays: serializer.fromJson<int>(json['retentionDays']),
      folderScopeJson: serializer.fromJson<String?>(json['folderScopeJson']),
      bodyPolicy: serializer.fromJson<String>(json['bodyPolicy']),
      attachmentMaxMb: serializer.fromJson<int>(json['attachmentMaxMb']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'retentionDays': serializer.toJson<int>(retentionDays),
      'folderScopeJson': serializer.toJson<String?>(folderScopeJson),
      'bodyPolicy': serializer.toJson<String>(bodyPolicy),
      'attachmentMaxMb': serializer.toJson<int>(attachmentMaxMb),
      'isDefault': serializer.toJson<bool>(isDefault),
    };
  }

  SyncProfile copyWith({
    String? id,
    String? name,
    int? retentionDays,
    Value<String?> folderScopeJson = const Value.absent(),
    String? bodyPolicy,
    int? attachmentMaxMb,
    bool? isDefault,
  }) => SyncProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    retentionDays: retentionDays ?? this.retentionDays,
    folderScopeJson: folderScopeJson.present
        ? folderScopeJson.value
        : this.folderScopeJson,
    bodyPolicy: bodyPolicy ?? this.bodyPolicy,
    attachmentMaxMb: attachmentMaxMb ?? this.attachmentMaxMb,
    isDefault: isDefault ?? this.isDefault,
  );
  SyncProfile copyWithCompanion(SyncProfilesCompanion data) {
    return SyncProfile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      retentionDays: data.retentionDays.present
          ? data.retentionDays.value
          : this.retentionDays,
      folderScopeJson: data.folderScopeJson.present
          ? data.folderScopeJson.value
          : this.folderScopeJson,
      bodyPolicy: data.bodyPolicy.present
          ? data.bodyPolicy.value
          : this.bodyPolicy,
      attachmentMaxMb: data.attachmentMaxMb.present
          ? data.attachmentMaxMb.value
          : this.attachmentMaxMb,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncProfile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('retentionDays: $retentionDays, ')
          ..write('folderScopeJson: $folderScopeJson, ')
          ..write('bodyPolicy: $bodyPolicy, ')
          ..write('attachmentMaxMb: $attachmentMaxMb, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    retentionDays,
    folderScopeJson,
    bodyPolicy,
    attachmentMaxMb,
    isDefault,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncProfile &&
          other.id == this.id &&
          other.name == this.name &&
          other.retentionDays == this.retentionDays &&
          other.folderScopeJson == this.folderScopeJson &&
          other.bodyPolicy == this.bodyPolicy &&
          other.attachmentMaxMb == this.attachmentMaxMb &&
          other.isDefault == this.isDefault);
}

class SyncProfilesCompanion extends UpdateCompanion<SyncProfile> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> retentionDays;
  final Value<String?> folderScopeJson;
  final Value<String> bodyPolicy;
  final Value<int> attachmentMaxMb;
  final Value<bool> isDefault;
  final Value<int> rowid;
  const SyncProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.retentionDays = const Value.absent(),
    this.folderScopeJson = const Value.absent(),
    this.bodyPolicy = const Value.absent(),
    this.attachmentMaxMb = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncProfilesCompanion.insert({
    required String id,
    required String name,
    required int retentionDays,
    this.folderScopeJson = const Value.absent(),
    this.bodyPolicy = const Value.absent(),
    this.attachmentMaxMb = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       retentionDays = Value(retentionDays);
  static Insertable<SyncProfile> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? retentionDays,
    Expression<String>? folderScopeJson,
    Expression<String>? bodyPolicy,
    Expression<int>? attachmentMaxMb,
    Expression<bool>? isDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (retentionDays != null) 'retention_days': retentionDays,
      if (folderScopeJson != null) 'folder_scope_json': folderScopeJson,
      if (bodyPolicy != null) 'body_policy': bodyPolicy,
      if (attachmentMaxMb != null) 'attachment_max_mb': attachmentMaxMb,
      if (isDefault != null) 'is_default': isDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? retentionDays,
    Value<String?>? folderScopeJson,
    Value<String>? bodyPolicy,
    Value<int>? attachmentMaxMb,
    Value<bool>? isDefault,
    Value<int>? rowid,
  }) {
    return SyncProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      retentionDays: retentionDays ?? this.retentionDays,
      folderScopeJson: folderScopeJson ?? this.folderScopeJson,
      bodyPolicy: bodyPolicy ?? this.bodyPolicy,
      attachmentMaxMb: attachmentMaxMb ?? this.attachmentMaxMb,
      isDefault: isDefault ?? this.isDefault,
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
    if (retentionDays.present) {
      map['retention_days'] = Variable<int>(retentionDays.value);
    }
    if (folderScopeJson.present) {
      map['folder_scope_json'] = Variable<String>(folderScopeJson.value);
    }
    if (bodyPolicy.present) {
      map['body_policy'] = Variable<String>(bodyPolicy.value);
    }
    if (attachmentMaxMb.present) {
      map['attachment_max_mb'] = Variable<int>(attachmentMaxMb.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('retentionDays: $retentionDays, ')
          ..write('folderScopeJson: $folderScopeJson, ')
          ..write('bodyPolicy: $bodyPolicy, ')
          ..write('attachmentMaxMb: $attachmentMaxMb, ')
          ..write('isDefault: $isDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, Attachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES messages (id)',
    ),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _providerPartIdMeta = const VerificationMeta(
    'providerPartId',
  );
  @override
  late final GeneratedColumn<String> providerPartId = GeneratedColumn<String>(
    'provider_part_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _filenameMeta = const VerificationMeta(
    'filename',
  );
  @override
  late final GeneratedColumn<String> filename = GeneratedColumn<String>(
    'filename',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    messageId,
    accountId,
    providerPartId,
    filename,
    mimeType,
    sizeBytes,
    localPath,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Attachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('provider_part_id')) {
      context.handle(
        _providerPartIdMeta,
        providerPartId.isAcceptableOrUnknown(
          data['provider_part_id']!,
          _providerPartIdMeta,
        ),
      );
    }
    if (data.containsKey('filename')) {
      context.handle(
        _filenameMeta,
        filename.isAcceptableOrUnknown(data['filename']!, _filenameMeta),
      );
    } else if (isInserting) {
      context.missing(_filenameMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Attachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attachment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      providerPartId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_part_id'],
      ),
      filename: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filename'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      ),
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }
}

class Attachment extends DataClass implements Insertable<Attachment> {
  final String id;
  final String messageId;
  final String accountId;
  final String? providerPartId;
  final String filename;
  final String mimeType;
  final int sizeBytes;
  final String? localPath;
  final int? fetchedAt;
  const Attachment({
    required this.id,
    required this.messageId,
    required this.accountId,
    this.providerPartId,
    required this.filename,
    required this.mimeType,
    required this.sizeBytes,
    this.localPath,
    this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['message_id'] = Variable<String>(messageId);
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || providerPartId != null) {
      map['provider_part_id'] = Variable<String>(providerPartId);
    }
    map['filename'] = Variable<String>(filename);
    map['mime_type'] = Variable<String>(mimeType);
    map['size_bytes'] = Variable<int>(sizeBytes);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || fetchedAt != null) {
      map['fetched_at'] = Variable<int>(fetchedAt);
    }
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      messageId: Value(messageId),
      accountId: Value(accountId),
      providerPartId: providerPartId == null && nullToAbsent
          ? const Value.absent()
          : Value(providerPartId),
      filename: Value(filename),
      mimeType: Value(mimeType),
      sizeBytes: Value(sizeBytes),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      fetchedAt: fetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(fetchedAt),
    );
  }

  factory Attachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attachment(
      id: serializer.fromJson<String>(json['id']),
      messageId: serializer.fromJson<String>(json['messageId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      providerPartId: serializer.fromJson<String?>(json['providerPartId']),
      filename: serializer.fromJson<String>(json['filename']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      fetchedAt: serializer.fromJson<int?>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'messageId': serializer.toJson<String>(messageId),
      'accountId': serializer.toJson<String>(accountId),
      'providerPartId': serializer.toJson<String?>(providerPartId),
      'filename': serializer.toJson<String>(filename),
      'mimeType': serializer.toJson<String>(mimeType),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'localPath': serializer.toJson<String?>(localPath),
      'fetchedAt': serializer.toJson<int?>(fetchedAt),
    };
  }

  Attachment copyWith({
    String? id,
    String? messageId,
    String? accountId,
    Value<String?> providerPartId = const Value.absent(),
    String? filename,
    String? mimeType,
    int? sizeBytes,
    Value<String?> localPath = const Value.absent(),
    Value<int?> fetchedAt = const Value.absent(),
  }) => Attachment(
    id: id ?? this.id,
    messageId: messageId ?? this.messageId,
    accountId: accountId ?? this.accountId,
    providerPartId: providerPartId.present
        ? providerPartId.value
        : this.providerPartId,
    filename: filename ?? this.filename,
    mimeType: mimeType ?? this.mimeType,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    localPath: localPath.present ? localPath.value : this.localPath,
    fetchedAt: fetchedAt.present ? fetchedAt.value : this.fetchedAt,
  );
  Attachment copyWithCompanion(AttachmentsCompanion data) {
    return Attachment(
      id: data.id.present ? data.id.value : this.id,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      providerPartId: data.providerPartId.present
          ? data.providerPartId.value
          : this.providerPartId,
      filename: data.filename.present ? data.filename.value : this.filename,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attachment(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('accountId: $accountId, ')
          ..write('providerPartId: $providerPartId, ')
          ..write('filename: $filename, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('localPath: $localPath, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    messageId,
    accountId,
    providerPartId,
    filename,
    mimeType,
    sizeBytes,
    localPath,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attachment &&
          other.id == this.id &&
          other.messageId == this.messageId &&
          other.accountId == this.accountId &&
          other.providerPartId == this.providerPartId &&
          other.filename == this.filename &&
          other.mimeType == this.mimeType &&
          other.sizeBytes == this.sizeBytes &&
          other.localPath == this.localPath &&
          other.fetchedAt == this.fetchedAt);
}

class AttachmentsCompanion extends UpdateCompanion<Attachment> {
  final Value<String> id;
  final Value<String> messageId;
  final Value<String> accountId;
  final Value<String?> providerPartId;
  final Value<String> filename;
  final Value<String> mimeType;
  final Value<int> sizeBytes;
  final Value<String?> localPath;
  final Value<int?> fetchedAt;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.messageId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.providerPartId = const Value.absent(),
    this.filename = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.localPath = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    required String id,
    required String messageId,
    required String accountId,
    this.providerPartId = const Value.absent(),
    required String filename,
    required String mimeType,
    required int sizeBytes,
    this.localPath = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       messageId = Value(messageId),
       accountId = Value(accountId),
       filename = Value(filename),
       mimeType = Value(mimeType),
       sizeBytes = Value(sizeBytes);
  static Insertable<Attachment> custom({
    Expression<String>? id,
    Expression<String>? messageId,
    Expression<String>? accountId,
    Expression<String>? providerPartId,
    Expression<String>? filename,
    Expression<String>? mimeType,
    Expression<int>? sizeBytes,
    Expression<String>? localPath,
    Expression<int>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (messageId != null) 'message_id': messageId,
      if (accountId != null) 'account_id': accountId,
      if (providerPartId != null) 'provider_part_id': providerPartId,
      if (filename != null) 'filename': filename,
      if (mimeType != null) 'mime_type': mimeType,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (localPath != null) 'local_path': localPath,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? messageId,
    Value<String>? accountId,
    Value<String?>? providerPartId,
    Value<String>? filename,
    Value<String>? mimeType,
    Value<int>? sizeBytes,
    Value<String?>? localPath,
    Value<int?>? fetchedAt,
    Value<int>? rowid,
  }) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      accountId: accountId ?? this.accountId,
      providerPartId: providerPartId ?? this.providerPartId,
      filename: filename ?? this.filename,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      localPath: localPath ?? this.localPath,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (providerPartId.present) {
      map['provider_part_id'] = Variable<String>(providerPartId.value);
    }
    if (filename.present) {
      map['filename'] = Variable<String>(filename.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('accountId: $accountId, ')
          ..write('providerPartId: $providerPartId, ')
          ..write('filename: $filename, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('localPath: $localPath, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentBlobsTable extends AttachmentBlobs
    with TableInfo<$AttachmentBlobsTable, AttachmentBlob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentBlobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    path,
    sizeBytes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachment_blobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttachmentBlob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttachmentBlob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttachmentBlob(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AttachmentBlobsTable createAlias(String alias) {
    return $AttachmentBlobsTable(attachedDatabase, alias);
  }
}

class AttachmentBlob extends DataClass implements Insertable<AttachmentBlob> {
  final String id;
  final String accountId;
  final String path;
  final int sizeBytes;
  final int createdAt;
  const AttachmentBlob({
    required this.id,
    required this.accountId,
    required this.path,
    required this.sizeBytes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['path'] = Variable<String>(path);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  AttachmentBlobsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentBlobsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      path: Value(path),
      sizeBytes: Value(sizeBytes),
      createdAt: Value(createdAt),
    );
  }

  factory AttachmentBlob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttachmentBlob(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      path: serializer.fromJson<String>(json['path']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'path': serializer.toJson<String>(path),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  AttachmentBlob copyWith({
    String? id,
    String? accountId,
    String? path,
    int? sizeBytes,
    int? createdAt,
  }) => AttachmentBlob(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    path: path ?? this.path,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    createdAt: createdAt ?? this.createdAt,
  );
  AttachmentBlob copyWithCompanion(AttachmentBlobsCompanion data) {
    return AttachmentBlob(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      path: data.path.present ? data.path.value : this.path,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentBlob(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('path: $path, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, accountId, path, sizeBytes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttachmentBlob &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.path == this.path &&
          other.sizeBytes == this.sizeBytes &&
          other.createdAt == this.createdAt);
}

class AttachmentBlobsCompanion extends UpdateCompanion<AttachmentBlob> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> path;
  final Value<int> sizeBytes;
  final Value<int> createdAt;
  final Value<int> rowid;
  const AttachmentBlobsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.path = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentBlobsCompanion.insert({
    required String id,
    required String accountId,
    required String path,
    required int sizeBytes,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       path = Value(path),
       sizeBytes = Value(sizeBytes),
       createdAt = Value(createdAt);
  static Insertable<AttachmentBlob> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? path,
    Expression<int>? sizeBytes,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (path != null) 'path': path,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentBlobsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? path,
    Value<int>? sizeBytes,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return AttachmentBlobsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      path: path ?? this.path,
      sizeBytes: sizeBytes ?? this.sizeBytes,
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
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentBlobsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('path: $path, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountSignaturesTable extends AccountSignatures
    with TableInfo<$AccountSignaturesTable, AccountSignature> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountSignaturesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyPlainMeta = const VerificationMeta(
    'bodyPlain',
  );
  @override
  late final GeneratedColumn<String> bodyPlain = GeneratedColumn<String>(
    'body_plain',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyHtmlMeta = const VerificationMeta(
    'bodyHtml',
  );
  @override
  late final GeneratedColumn<String> bodyHtml = GeneratedColumn<String>(
    'body_html',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    name,
    bodyPlain,
    bodyHtml,
    isDefault,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'account_signatures';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountSignature> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('body_plain')) {
      context.handle(
        _bodyPlainMeta,
        bodyPlain.isAcceptableOrUnknown(data['body_plain']!, _bodyPlainMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyPlainMeta);
    }
    if (data.containsKey('body_html')) {
      context.handle(
        _bodyHtmlMeta,
        bodyHtml.isAcceptableOrUnknown(data['body_html']!, _bodyHtmlMeta),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountSignature map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountSignature(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      bodyPlain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_plain'],
      )!,
      bodyHtml: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_html'],
      ),
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $AccountSignaturesTable createAlias(String alias) {
    return $AccountSignaturesTable(attachedDatabase, alias);
  }
}

class AccountSignature extends DataClass
    implements Insertable<AccountSignature> {
  final String id;
  final String accountId;
  final String name;
  final String bodyPlain;
  final String? bodyHtml;
  final bool isDefault;
  final int sortOrder;
  const AccountSignature({
    required this.id,
    required this.accountId,
    required this.name,
    required this.bodyPlain,
    this.bodyHtml,
    required this.isDefault,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['name'] = Variable<String>(name);
    map['body_plain'] = Variable<String>(bodyPlain);
    if (!nullToAbsent || bodyHtml != null) {
      map['body_html'] = Variable<String>(bodyHtml);
    }
    map['is_default'] = Variable<bool>(isDefault);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  AccountSignaturesCompanion toCompanion(bool nullToAbsent) {
    return AccountSignaturesCompanion(
      id: Value(id),
      accountId: Value(accountId),
      name: Value(name),
      bodyPlain: Value(bodyPlain),
      bodyHtml: bodyHtml == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyHtml),
      isDefault: Value(isDefault),
      sortOrder: Value(sortOrder),
    );
  }

  factory AccountSignature.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountSignature(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      name: serializer.fromJson<String>(json['name']),
      bodyPlain: serializer.fromJson<String>(json['bodyPlain']),
      bodyHtml: serializer.fromJson<String?>(json['bodyHtml']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'name': serializer.toJson<String>(name),
      'bodyPlain': serializer.toJson<String>(bodyPlain),
      'bodyHtml': serializer.toJson<String?>(bodyHtml),
      'isDefault': serializer.toJson<bool>(isDefault),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  AccountSignature copyWith({
    String? id,
    String? accountId,
    String? name,
    String? bodyPlain,
    Value<String?> bodyHtml = const Value.absent(),
    bool? isDefault,
    int? sortOrder,
  }) => AccountSignature(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    name: name ?? this.name,
    bodyPlain: bodyPlain ?? this.bodyPlain,
    bodyHtml: bodyHtml.present ? bodyHtml.value : this.bodyHtml,
    isDefault: isDefault ?? this.isDefault,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  AccountSignature copyWithCompanion(AccountSignaturesCompanion data) {
    return AccountSignature(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      name: data.name.present ? data.name.value : this.name,
      bodyPlain: data.bodyPlain.present ? data.bodyPlain.value : this.bodyPlain,
      bodyHtml: data.bodyHtml.present ? data.bodyHtml.value : this.bodyHtml,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountSignature(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('name: $name, ')
          ..write('bodyPlain: $bodyPlain, ')
          ..write('bodyHtml: $bodyHtml, ')
          ..write('isDefault: $isDefault, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    name,
    bodyPlain,
    bodyHtml,
    isDefault,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountSignature &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.name == this.name &&
          other.bodyPlain == this.bodyPlain &&
          other.bodyHtml == this.bodyHtml &&
          other.isDefault == this.isDefault &&
          other.sortOrder == this.sortOrder);
}

class AccountSignaturesCompanion extends UpdateCompanion<AccountSignature> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> name;
  final Value<String> bodyPlain;
  final Value<String?> bodyHtml;
  final Value<bool> isDefault;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const AccountSignaturesCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.name = const Value.absent(),
    this.bodyPlain = const Value.absent(),
    this.bodyHtml = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountSignaturesCompanion.insert({
    required String id,
    required String accountId,
    required String name,
    required String bodyPlain,
    this.bodyHtml = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       name = Value(name),
       bodyPlain = Value(bodyPlain);
  static Insertable<AccountSignature> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? name,
    Expression<String>? bodyPlain,
    Expression<String>? bodyHtml,
    Expression<bool>? isDefault,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (name != null) 'name': name,
      if (bodyPlain != null) 'body_plain': bodyPlain,
      if (bodyHtml != null) 'body_html': bodyHtml,
      if (isDefault != null) 'is_default': isDefault,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountSignaturesCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? name,
    Value<String>? bodyPlain,
    Value<String?>? bodyHtml,
    Value<bool>? isDefault,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return AccountSignaturesCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      name: name ?? this.name,
      bodyPlain: bodyPlain ?? this.bodyPlain,
      bodyHtml: bodyHtml ?? this.bodyHtml,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (bodyPlain.present) {
      map['body_plain'] = Variable<String>(bodyPlain.value);
    }
    if (bodyHtml.present) {
      map['body_html'] = Variable<String>(bodyHtml.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountSignaturesCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('name: $name, ')
          ..write('bodyPlain: $bodyPlain, ')
          ..write('bodyHtml: $bodyHtml, ')
          ..write('isDefault: $isDefault, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountSignatureAssetsTable extends AccountSignatureAssets
    with TableInfo<$AccountSignatureAssetsTable, AccountSignatureAsset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountSignatureAssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _signatureIdMeta = const VerificationMeta(
    'signatureId',
  );
  @override
  late final GeneratedColumn<String> signatureId = GeneratedColumn<String>(
    'signature_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES account_signatures (id)',
    ),
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentIdMeta = const VerificationMeta(
    'contentId',
  );
  @override
  late final GeneratedColumn<String> contentId = GeneratedColumn<String>(
    'content_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    signatureId,
    localPath,
    contentId,
    mimeType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'account_signature_assets';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountSignatureAsset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('signature_id')) {
      context.handle(
        _signatureIdMeta,
        signatureId.isAcceptableOrUnknown(
          data['signature_id']!,
          _signatureIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_signatureIdMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('content_id')) {
      context.handle(
        _contentIdMeta,
        contentId.isAcceptableOrUnknown(data['content_id']!, _contentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contentIdMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountSignatureAsset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountSignatureAsset(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      signatureId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature_id'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      contentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_id'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
    );
  }

  @override
  $AccountSignatureAssetsTable createAlias(String alias) {
    return $AccountSignatureAssetsTable(attachedDatabase, alias);
  }
}

class AccountSignatureAsset extends DataClass
    implements Insertable<AccountSignatureAsset> {
  final String id;
  final String signatureId;
  final String localPath;
  final String contentId;
  final String mimeType;
  const AccountSignatureAsset({
    required this.id,
    required this.signatureId,
    required this.localPath,
    required this.contentId,
    required this.mimeType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['signature_id'] = Variable<String>(signatureId);
    map['local_path'] = Variable<String>(localPath);
    map['content_id'] = Variable<String>(contentId);
    map['mime_type'] = Variable<String>(mimeType);
    return map;
  }

  AccountSignatureAssetsCompanion toCompanion(bool nullToAbsent) {
    return AccountSignatureAssetsCompanion(
      id: Value(id),
      signatureId: Value(signatureId),
      localPath: Value(localPath),
      contentId: Value(contentId),
      mimeType: Value(mimeType),
    );
  }

  factory AccountSignatureAsset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountSignatureAsset(
      id: serializer.fromJson<String>(json['id']),
      signatureId: serializer.fromJson<String>(json['signatureId']),
      localPath: serializer.fromJson<String>(json['localPath']),
      contentId: serializer.fromJson<String>(json['contentId']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'signatureId': serializer.toJson<String>(signatureId),
      'localPath': serializer.toJson<String>(localPath),
      'contentId': serializer.toJson<String>(contentId),
      'mimeType': serializer.toJson<String>(mimeType),
    };
  }

  AccountSignatureAsset copyWith({
    String? id,
    String? signatureId,
    String? localPath,
    String? contentId,
    String? mimeType,
  }) => AccountSignatureAsset(
    id: id ?? this.id,
    signatureId: signatureId ?? this.signatureId,
    localPath: localPath ?? this.localPath,
    contentId: contentId ?? this.contentId,
    mimeType: mimeType ?? this.mimeType,
  );
  AccountSignatureAsset copyWithCompanion(
    AccountSignatureAssetsCompanion data,
  ) {
    return AccountSignatureAsset(
      id: data.id.present ? data.id.value : this.id,
      signatureId: data.signatureId.present
          ? data.signatureId.value
          : this.signatureId,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      contentId: data.contentId.present ? data.contentId.value : this.contentId,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountSignatureAsset(')
          ..write('id: $id, ')
          ..write('signatureId: $signatureId, ')
          ..write('localPath: $localPath, ')
          ..write('contentId: $contentId, ')
          ..write('mimeType: $mimeType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, signatureId, localPath, contentId, mimeType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountSignatureAsset &&
          other.id == this.id &&
          other.signatureId == this.signatureId &&
          other.localPath == this.localPath &&
          other.contentId == this.contentId &&
          other.mimeType == this.mimeType);
}

class AccountSignatureAssetsCompanion
    extends UpdateCompanion<AccountSignatureAsset> {
  final Value<String> id;
  final Value<String> signatureId;
  final Value<String> localPath;
  final Value<String> contentId;
  final Value<String> mimeType;
  final Value<int> rowid;
  const AccountSignatureAssetsCompanion({
    this.id = const Value.absent(),
    this.signatureId = const Value.absent(),
    this.localPath = const Value.absent(),
    this.contentId = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountSignatureAssetsCompanion.insert({
    required String id,
    required String signatureId,
    required String localPath,
    required String contentId,
    required String mimeType,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       signatureId = Value(signatureId),
       localPath = Value(localPath),
       contentId = Value(contentId),
       mimeType = Value(mimeType);
  static Insertable<AccountSignatureAsset> custom({
    Expression<String>? id,
    Expression<String>? signatureId,
    Expression<String>? localPath,
    Expression<String>? contentId,
    Expression<String>? mimeType,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (signatureId != null) 'signature_id': signatureId,
      if (localPath != null) 'local_path': localPath,
      if (contentId != null) 'content_id': contentId,
      if (mimeType != null) 'mime_type': mimeType,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountSignatureAssetsCompanion copyWith({
    Value<String>? id,
    Value<String>? signatureId,
    Value<String>? localPath,
    Value<String>? contentId,
    Value<String>? mimeType,
    Value<int>? rowid,
  }) {
    return AccountSignatureAssetsCompanion(
      id: id ?? this.id,
      signatureId: signatureId ?? this.signatureId,
      localPath: localPath ?? this.localPath,
      contentId: contentId ?? this.contentId,
      mimeType: mimeType ?? this.mimeType,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (signatureId.present) {
      map['signature_id'] = Variable<String>(signatureId.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (contentId.present) {
      map['content_id'] = Variable<String>(contentId.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountSignatureAssetsCompanion(')
          ..write('id: $id, ')
          ..write('signatureId: $signatureId, ')
          ..write('localPath: $localPath, ')
          ..write('contentId: $contentId, ')
          ..write('mimeType: $mimeType, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessageTemplatesTable extends MessageTemplates
    with TableInfo<$MessageTemplatesTable, MessageTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessageTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyHtmlMeta = const VerificationMeta(
    'bodyHtml',
  );
  @override
  late final GeneratedColumn<String> bodyHtml = GeneratedColumn<String>(
    'body_html',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    name,
    subject,
    bodyHtml,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('body_html')) {
      context.handle(
        _bodyHtmlMeta,
        bodyHtml.isAcceptableOrUnknown(data['body_html']!, _bodyHtmlMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyHtmlMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      bodyHtml: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_html'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $MessageTemplatesTable createAlias(String alias) {
    return $MessageTemplatesTable(attachedDatabase, alias);
  }
}

class MessageTemplate extends DataClass implements Insertable<MessageTemplate> {
  final String id;
  final String? accountId;
  final String name;
  final String subject;
  final String bodyHtml;
  final int sortOrder;
  const MessageTemplate({
    required this.id,
    this.accountId,
    required this.name,
    required this.subject,
    required this.bodyHtml,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    map['name'] = Variable<String>(name);
    map['subject'] = Variable<String>(subject);
    map['body_html'] = Variable<String>(bodyHtml);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  MessageTemplatesCompanion toCompanion(bool nullToAbsent) {
    return MessageTemplatesCompanion(
      id: Value(id),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      name: Value(name),
      subject: Value(subject),
      bodyHtml: Value(bodyHtml),
      sortOrder: Value(sortOrder),
    );
  }

  factory MessageTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageTemplate(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      name: serializer.fromJson<String>(json['name']),
      subject: serializer.fromJson<String>(json['subject']),
      bodyHtml: serializer.fromJson<String>(json['bodyHtml']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String?>(accountId),
      'name': serializer.toJson<String>(name),
      'subject': serializer.toJson<String>(subject),
      'bodyHtml': serializer.toJson<String>(bodyHtml),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  MessageTemplate copyWith({
    String? id,
    Value<String?> accountId = const Value.absent(),
    String? name,
    String? subject,
    String? bodyHtml,
    int? sortOrder,
  }) => MessageTemplate(
    id: id ?? this.id,
    accountId: accountId.present ? accountId.value : this.accountId,
    name: name ?? this.name,
    subject: subject ?? this.subject,
    bodyHtml: bodyHtml ?? this.bodyHtml,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  MessageTemplate copyWithCompanion(MessageTemplatesCompanion data) {
    return MessageTemplate(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      name: data.name.present ? data.name.value : this.name,
      subject: data.subject.present ? data.subject.value : this.subject,
      bodyHtml: data.bodyHtml.present ? data.bodyHtml.value : this.bodyHtml,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageTemplate(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('name: $name, ')
          ..write('subject: $subject, ')
          ..write('bodyHtml: $bodyHtml, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, accountId, name, subject, bodyHtml, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageTemplate &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.name == this.name &&
          other.subject == this.subject &&
          other.bodyHtml == this.bodyHtml &&
          other.sortOrder == this.sortOrder);
}

class MessageTemplatesCompanion extends UpdateCompanion<MessageTemplate> {
  final Value<String> id;
  final Value<String?> accountId;
  final Value<String> name;
  final Value<String> subject;
  final Value<String> bodyHtml;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const MessageTemplatesCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.name = const Value.absent(),
    this.subject = const Value.absent(),
    this.bodyHtml = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessageTemplatesCompanion.insert({
    required String id,
    this.accountId = const Value.absent(),
    required String name,
    required String subject,
    required String bodyHtml,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       subject = Value(subject),
       bodyHtml = Value(bodyHtml);
  static Insertable<MessageTemplate> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? name,
    Expression<String>? subject,
    Expression<String>? bodyHtml,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (name != null) 'name': name,
      if (subject != null) 'subject': subject,
      if (bodyHtml != null) 'body_html': bodyHtml,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessageTemplatesCompanion copyWith({
    Value<String>? id,
    Value<String?>? accountId,
    Value<String>? name,
    Value<String>? subject,
    Value<String>? bodyHtml,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return MessageTemplatesCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      bodyHtml: bodyHtml ?? this.bodyHtml,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (bodyHtml.present) {
      map['body_html'] = Variable<String>(bodyHtml.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('name: $name, ')
          ..write('subject: $subject, ')
          ..write('bodyHtml: $bodyHtml, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomThemesTable extends CustomThemes
    with TableInfo<$CustomThemesTable, CustomTheme> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomThemesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseThemeIdMeta = const VerificationMeta(
    'baseThemeId',
  );
  @override
  late final GeneratedColumn<String> baseThemeId = GeneratedColumn<String>(
    'base_theme_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tokenOverridesJsonMeta =
      const VerificationMeta('tokenOverridesJson');
  @override
  late final GeneratedColumn<String> tokenOverridesJson =
      GeneratedColumn<String>(
        'token_overrides_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    baseThemeId,
    tokenOverridesJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_themes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomTheme> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('base_theme_id')) {
      context.handle(
        _baseThemeIdMeta,
        baseThemeId.isAcceptableOrUnknown(
          data['base_theme_id']!,
          _baseThemeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseThemeIdMeta);
    }
    if (data.containsKey('token_overrides_json')) {
      context.handle(
        _tokenOverridesJsonMeta,
        tokenOverridesJson.isAcceptableOrUnknown(
          data['token_overrides_json']!,
          _tokenOverridesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tokenOverridesJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomTheme map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomTheme(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      baseThemeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_theme_id'],
      )!,
      tokenOverridesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}token_overrides_json'],
      )!,
    );
  }

  @override
  $CustomThemesTable createAlias(String alias) {
    return $CustomThemesTable(attachedDatabase, alias);
  }
}

class CustomTheme extends DataClass implements Insertable<CustomTheme> {
  final String id;
  final String name;
  final String baseThemeId;
  final String tokenOverridesJson;
  const CustomTheme({
    required this.id,
    required this.name,
    required this.baseThemeId,
    required this.tokenOverridesJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['base_theme_id'] = Variable<String>(baseThemeId);
    map['token_overrides_json'] = Variable<String>(tokenOverridesJson);
    return map;
  }

  CustomThemesCompanion toCompanion(bool nullToAbsent) {
    return CustomThemesCompanion(
      id: Value(id),
      name: Value(name),
      baseThemeId: Value(baseThemeId),
      tokenOverridesJson: Value(tokenOverridesJson),
    );
  }

  factory CustomTheme.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomTheme(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      baseThemeId: serializer.fromJson<String>(json['baseThemeId']),
      tokenOverridesJson: serializer.fromJson<String>(
        json['tokenOverridesJson'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'baseThemeId': serializer.toJson<String>(baseThemeId),
      'tokenOverridesJson': serializer.toJson<String>(tokenOverridesJson),
    };
  }

  CustomTheme copyWith({
    String? id,
    String? name,
    String? baseThemeId,
    String? tokenOverridesJson,
  }) => CustomTheme(
    id: id ?? this.id,
    name: name ?? this.name,
    baseThemeId: baseThemeId ?? this.baseThemeId,
    tokenOverridesJson: tokenOverridesJson ?? this.tokenOverridesJson,
  );
  CustomTheme copyWithCompanion(CustomThemesCompanion data) {
    return CustomTheme(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      baseThemeId: data.baseThemeId.present
          ? data.baseThemeId.value
          : this.baseThemeId,
      tokenOverridesJson: data.tokenOverridesJson.present
          ? data.tokenOverridesJson.value
          : this.tokenOverridesJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomTheme(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseThemeId: $baseThemeId, ')
          ..write('tokenOverridesJson: $tokenOverridesJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, baseThemeId, tokenOverridesJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomTheme &&
          other.id == this.id &&
          other.name == this.name &&
          other.baseThemeId == this.baseThemeId &&
          other.tokenOverridesJson == this.tokenOverridesJson);
}

class CustomThemesCompanion extends UpdateCompanion<CustomTheme> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> baseThemeId;
  final Value<String> tokenOverridesJson;
  final Value<int> rowid;
  const CustomThemesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.baseThemeId = const Value.absent(),
    this.tokenOverridesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomThemesCompanion.insert({
    required String id,
    required String name,
    required String baseThemeId,
    required String tokenOverridesJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       baseThemeId = Value(baseThemeId),
       tokenOverridesJson = Value(tokenOverridesJson);
  static Insertable<CustomTheme> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? baseThemeId,
    Expression<String>? tokenOverridesJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (baseThemeId != null) 'base_theme_id': baseThemeId,
      if (tokenOverridesJson != null)
        'token_overrides_json': tokenOverridesJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomThemesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? baseThemeId,
    Value<String>? tokenOverridesJson,
    Value<int>? rowid,
  }) {
    return CustomThemesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      baseThemeId: baseThemeId ?? this.baseThemeId,
      tokenOverridesJson: tokenOverridesJson ?? this.tokenOverridesJson,
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
    if (baseThemeId.present) {
      map['base_theme_id'] = Variable<String>(baseThemeId.value);
    }
    if (tokenOverridesJson.present) {
      map['token_overrides_json'] = Variable<String>(tokenOverridesJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomThemesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseThemeId: $baseThemeId, ')
          ..write('tokenOverridesJson: $tokenOverridesJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ByteMailDatabase extends GeneratedDatabase {
  _$ByteMailDatabase(QueryExecutor e) : super(e);
  $ByteMailDatabaseManager get managers => $ByteMailDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $FoldersTable folders = $FoldersTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $FocusRulesTable focusRules = $FocusRulesTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $JobsTable jobs = $JobsTable(this);
  late final $SyncCursorsTable syncCursors = $SyncCursorsTable(this);
  late final $WidgetSnapshotsTable widgetSnapshots = $WidgetSnapshotsTable(
    this,
  );
  late final $SyncProfilesTable syncProfiles = $SyncProfilesTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $AttachmentBlobsTable attachmentBlobs = $AttachmentBlobsTable(
    this,
  );
  late final $AccountSignaturesTable accountSignatures =
      $AccountSignaturesTable(this);
  late final $AccountSignatureAssetsTable accountSignatureAssets =
      $AccountSignatureAssetsTable(this);
  late final $MessageTemplatesTable messageTemplates = $MessageTemplatesTable(
    this,
  );
  late final $CustomThemesTable customThemes = $CustomThemesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    folders,
    messages,
    focusRules,
    outbox,
    jobs,
    syncCursors,
    widgetSnapshots,
    syncProfiles,
    attachments,
    attachmentBlobs,
    accountSignatures,
    accountSignatureAssets,
    messageTemplates,
    customThemes,
  ];
}

typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      required String id,
      required String label,
      required String address,
      required int accentArgb,
      required String providerType,
      required String storageType,
      Value<bool> focusEnabled,
      Value<String?> credentialsRef,
      Value<String?> syncProfileId,
      Value<int?> retentionDaysOverride,
      Value<int> rowid,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<String> id,
      Value<String> label,
      Value<String> address,
      Value<int> accentArgb,
      Value<String> providerType,
      Value<String> storageType,
      Value<bool> focusEnabled,
      Value<String?> credentialsRef,
      Value<String?> syncProfileId,
      Value<int?> retentionDaysOverride,
      Value<int> rowid,
    });

final class $$AccountsTableReferences
    extends BaseReferences<_$ByteMailDatabase, $AccountsTable, Account> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FoldersTable, List<Folder>> _foldersRefsTable(
    _$ByteMailDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.folders,
    aliasName: 'accounts__id__folders__account_id',
  );

  $$FoldersTableProcessedTableManager get foldersRefs {
    final manager = $$FoldersTableTableManager(
      $_db,
      $_db.folders,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_foldersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MessagesTable, List<Message>> _messagesRefsTable(
    _$ByteMailDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.messages,
    aliasName: 'accounts__id__messages__account_id',
  );

  $$MessagesTableProcessedTableManager get messagesRefs {
    final manager = $$MessagesTableTableManager(
      $_db,
      $_db.messages,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_messagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FocusRulesTable, List<FocusRule>>
  _focusRulesRefsTable(_$ByteMailDatabase db) => MultiTypedResultKey.fromTable(
    db.focusRules,
    aliasName: 'accounts__id__focus_rules__account_id',
  );

  $$FocusRulesTableProcessedTableManager get focusRulesRefs {
    final manager = $$FocusRulesTableTableManager(
      $_db,
      $_db.focusRules,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_focusRulesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$OutboxTable, List<OutboxData>> _outboxRefsTable(
    _$ByteMailDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.outbox,
    aliasName: 'accounts__id__outbox__account_id',
  );

  $$OutboxTableProcessedTableManager get outboxRefs {
    final manager = $$OutboxTableTableManager(
      $_db,
      $_db.outbox,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_outboxRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$JobsTable, List<Job>> _jobsRefsTable(
    _$ByteMailDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.jobs,
    aliasName: 'accounts__id__sync_jobs__account_id',
  );

  $$JobsTableProcessedTableManager get jobsRefs {
    final manager = $$JobsTableTableManager(
      $_db,
      $_db.jobs,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_jobsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SyncCursorsTable, List<SyncCursor>>
  _syncCursorsRefsTable(_$ByteMailDatabase db) => MultiTypedResultKey.fromTable(
    db.syncCursors,
    aliasName: 'accounts__id__sync_cursors__account_id',
  );

  $$SyncCursorsTableProcessedTableManager get syncCursorsRefs {
    final manager = $$SyncCursorsTableTableManager(
      $_db,
      $_db.syncCursors,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_syncCursorsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AttachmentsTable, List<Attachment>>
  _attachmentsRefsTable(_$ByteMailDatabase db) => MultiTypedResultKey.fromTable(
    db.attachments,
    aliasName: 'accounts__id__attachments__account_id',
  );

  $$AttachmentsTableProcessedTableManager get attachmentsRefs {
    final manager = $$AttachmentsTableTableManager(
      $_db,
      $_db.attachments,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_attachmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AttachmentBlobsTable, List<AttachmentBlob>>
  _attachmentBlobsRefsTable(_$ByteMailDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.attachmentBlobs,
        aliasName: 'accounts__id__attachment_blobs__account_id',
      );

  $$AttachmentBlobsTableProcessedTableManager get attachmentBlobsRefs {
    final manager = $$AttachmentBlobsTableTableManager(
      $_db,
      $_db.attachmentBlobs,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _attachmentBlobsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AccountSignaturesTable, List<AccountSignature>>
  _accountSignaturesRefsTable(_$ByteMailDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.accountSignatures,
        aliasName: 'accounts__id__account_signatures__account_id',
      );

  $$AccountSignaturesTableProcessedTableManager get accountSignaturesRefs {
    final manager = $$AccountSignaturesTableTableManager(
      $_db,
      $_db.accountSignatures,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _accountSignaturesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MessageTemplatesTable, List<MessageTemplate>>
  _messageTemplatesRefsTable(_$ByteMailDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.messageTemplates,
        aliasName: 'accounts__id__message_templates__account_id',
      );

  $$MessageTemplatesTableProcessedTableManager get messageTemplatesRefs {
    final manager = $$MessageTemplatesTableTableManager(
      $_db,
      $_db.messageTemplates,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _messageTemplatesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$ByteMailDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accentArgb => $composableBuilder(
    column: $table.accentArgb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerType => $composableBuilder(
    column: $table.providerType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storageType => $composableBuilder(
    column: $table.storageType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get focusEnabled => $composableBuilder(
    column: $table.focusEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get credentialsRef => $composableBuilder(
    column: $table.credentialsRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncProfileId => $composableBuilder(
    column: $table.syncProfileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retentionDaysOverride => $composableBuilder(
    column: $table.retentionDaysOverride,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> foldersRefs(
    Expression<bool> Function($$FoldersTableFilterComposer f) f,
  ) {
    final $$FoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableFilterComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> messagesRefs(
    Expression<bool> Function($$MessagesTableFilterComposer f) f,
  ) {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableFilterComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> focusRulesRefs(
    Expression<bool> Function($$FocusRulesTableFilterComposer f) f,
  ) {
    final $$FocusRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.focusRules,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FocusRulesTableFilterComposer(
            $db: $db,
            $table: $db.focusRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> outboxRefs(
    Expression<bool> Function($$OutboxTableFilterComposer f) f,
  ) {
    final $$OutboxTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.outbox,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OutboxTableFilterComposer(
            $db: $db,
            $table: $db.outbox,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> jobsRefs(
    Expression<bool> Function($$JobsTableFilterComposer f) f,
  ) {
    final $$JobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.jobs,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableFilterComposer(
            $db: $db,
            $table: $db.jobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> syncCursorsRefs(
    Expression<bool> Function($$SyncCursorsTableFilterComposer f) f,
  ) {
    final $$SyncCursorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncCursors,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncCursorsTableFilterComposer(
            $db: $db,
            $table: $db.syncCursors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> attachmentsRefs(
    Expression<bool> Function($$AttachmentsTableFilterComposer f) f,
  ) {
    final $$AttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> attachmentBlobsRefs(
    Expression<bool> Function($$AttachmentBlobsTableFilterComposer f) f,
  ) {
    final $$AttachmentBlobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachmentBlobs,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentBlobsTableFilterComposer(
            $db: $db,
            $table: $db.attachmentBlobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> accountSignaturesRefs(
    Expression<bool> Function($$AccountSignaturesTableFilterComposer f) f,
  ) {
    final $$AccountSignaturesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accountSignatures,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountSignaturesTableFilterComposer(
            $db: $db,
            $table: $db.accountSignatures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> messageTemplatesRefs(
    Expression<bool> Function($$MessageTemplatesTableFilterComposer f) f,
  ) {
    final $$MessageTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messageTemplates,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessageTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.messageTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$ByteMailDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accentArgb => $composableBuilder(
    column: $table.accentArgb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerType => $composableBuilder(
    column: $table.providerType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storageType => $composableBuilder(
    column: $table.storageType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get focusEnabled => $composableBuilder(
    column: $table.focusEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get credentialsRef => $composableBuilder(
    column: $table.credentialsRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncProfileId => $composableBuilder(
    column: $table.syncProfileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retentionDaysOverride => $composableBuilder(
    column: $table.retentionDaysOverride,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$ByteMailDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<int> get accentArgb => $composableBuilder(
    column: $table.accentArgb,
    builder: (column) => column,
  );

  GeneratedColumn<String> get providerType => $composableBuilder(
    column: $table.providerType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get storageType => $composableBuilder(
    column: $table.storageType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get focusEnabled => $composableBuilder(
    column: $table.focusEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get credentialsRef => $composableBuilder(
    column: $table.credentialsRef,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncProfileId => $composableBuilder(
    column: $table.syncProfileId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retentionDaysOverride => $composableBuilder(
    column: $table.retentionDaysOverride,
    builder: (column) => column,
  );

  Expression<T> foldersRefs<T extends Object>(
    Expression<T> Function($$FoldersTableAnnotationComposer a) f,
  ) {
    final $$FoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> messagesRefs<T extends Object>(
    Expression<T> Function($$MessagesTableAnnotationComposer a) f,
  ) {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> focusRulesRefs<T extends Object>(
    Expression<T> Function($$FocusRulesTableAnnotationComposer a) f,
  ) {
    final $$FocusRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.focusRules,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FocusRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.focusRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> outboxRefs<T extends Object>(
    Expression<T> Function($$OutboxTableAnnotationComposer a) f,
  ) {
    final $$OutboxTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.outbox,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OutboxTableAnnotationComposer(
            $db: $db,
            $table: $db.outbox,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> jobsRefs<T extends Object>(
    Expression<T> Function($$JobsTableAnnotationComposer a) f,
  ) {
    final $$JobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.jobs,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableAnnotationComposer(
            $db: $db,
            $table: $db.jobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> syncCursorsRefs<T extends Object>(
    Expression<T> Function($$SyncCursorsTableAnnotationComposer a) f,
  ) {
    final $$SyncCursorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncCursors,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncCursorsTableAnnotationComposer(
            $db: $db,
            $table: $db.syncCursors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> attachmentsRefs<T extends Object>(
    Expression<T> Function($$AttachmentsTableAnnotationComposer a) f,
  ) {
    final $$AttachmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> attachmentBlobsRefs<T extends Object>(
    Expression<T> Function($$AttachmentBlobsTableAnnotationComposer a) f,
  ) {
    final $$AttachmentBlobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachmentBlobs,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentBlobsTableAnnotationComposer(
            $db: $db,
            $table: $db.attachmentBlobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> accountSignaturesRefs<T extends Object>(
    Expression<T> Function($$AccountSignaturesTableAnnotationComposer a) f,
  ) {
    final $$AccountSignaturesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.accountSignatures,
          getReferencedColumn: (t) => t.accountId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AccountSignaturesTableAnnotationComposer(
                $db: $db,
                $table: $db.accountSignatures,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> messageTemplatesRefs<T extends Object>(
    Expression<T> Function($$MessageTemplatesTableAnnotationComposer a) f,
  ) {
    final $$MessageTemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messageTemplates,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessageTemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.messageTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$ByteMailDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, $$AccountsTableReferences),
          Account,
          PrefetchHooks Function({
            bool foldersRefs,
            bool messagesRefs,
            bool focusRulesRefs,
            bool outboxRefs,
            bool jobsRefs,
            bool syncCursorsRefs,
            bool attachmentsRefs,
            bool attachmentBlobsRefs,
            bool accountSignaturesRefs,
            bool messageTemplatesRefs,
          })
        > {
  $$AccountsTableTableManager(_$ByteMailDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<int> accentArgb = const Value.absent(),
                Value<String> providerType = const Value.absent(),
                Value<String> storageType = const Value.absent(),
                Value<bool> focusEnabled = const Value.absent(),
                Value<String?> credentialsRef = const Value.absent(),
                Value<String?> syncProfileId = const Value.absent(),
                Value<int?> retentionDaysOverride = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                label: label,
                address: address,
                accentArgb: accentArgb,
                providerType: providerType,
                storageType: storageType,
                focusEnabled: focusEnabled,
                credentialsRef: credentialsRef,
                syncProfileId: syncProfileId,
                retentionDaysOverride: retentionDaysOverride,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String label,
                required String address,
                required int accentArgb,
                required String providerType,
                required String storageType,
                Value<bool> focusEnabled = const Value.absent(),
                Value<String?> credentialsRef = const Value.absent(),
                Value<String?> syncProfileId = const Value.absent(),
                Value<int?> retentionDaysOverride = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                label: label,
                address: address,
                accentArgb: accentArgb,
                providerType: providerType,
                storageType: storageType,
                focusEnabled: focusEnabled,
                credentialsRef: credentialsRef,
                syncProfileId: syncProfileId,
                retentionDaysOverride: retentionDaysOverride,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                foldersRefs = false,
                messagesRefs = false,
                focusRulesRefs = false,
                outboxRefs = false,
                jobsRefs = false,
                syncCursorsRefs = false,
                attachmentsRefs = false,
                attachmentBlobsRefs = false,
                accountSignaturesRefs = false,
                messageTemplatesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (foldersRefs) db.folders,
                    if (messagesRefs) db.messages,
                    if (focusRulesRefs) db.focusRules,
                    if (outboxRefs) db.outbox,
                    if (jobsRefs) db.jobs,
                    if (syncCursorsRefs) db.syncCursors,
                    if (attachmentsRefs) db.attachments,
                    if (attachmentBlobsRefs) db.attachmentBlobs,
                    if (accountSignaturesRefs) db.accountSignatures,
                    if (messageTemplatesRefs) db.messageTemplates,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (foldersRefs)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          Folder
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._foldersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).foldersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (messagesRefs)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          Message
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._messagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).messagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (focusRulesRefs)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          FocusRule
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._focusRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).focusRulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (outboxRefs)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          OutboxData
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._outboxRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).outboxRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (jobsRefs)
                        await $_getPrefetchedData<Account, $AccountsTable, Job>(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._jobsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(db, table, p0).jobsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (syncCursorsRefs)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          SyncCursor
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._syncCursorsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).syncCursorsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (attachmentsRefs)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          Attachment
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._attachmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).attachmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (attachmentBlobsRefs)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          AttachmentBlob
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._attachmentBlobsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).attachmentBlobsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (accountSignaturesRefs)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          AccountSignature
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._accountSignaturesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).accountSignaturesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (messageTemplatesRefs)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          MessageTemplate
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._messageTemplatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).messageTemplatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$ByteMailDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, $$AccountsTableReferences),
      Account,
      PrefetchHooks Function({
        bool foldersRefs,
        bool messagesRefs,
        bool focusRulesRefs,
        bool outboxRefs,
        bool jobsRefs,
        bool syncCursorsRefs,
        bool attachmentsRefs,
        bool attachmentBlobsRefs,
        bool accountSignaturesRefs,
        bool messageTemplatesRefs,
      })
    >;
typedef $$FoldersTableCreateCompanionBuilder =
    FoldersCompanion Function({
      required String id,
      required String accountId,
      required String name,
      Value<String> role,
      required String remoteId,
      Value<String?> parentRemoteId,
      Value<int?> unreadCount,
      Value<int?> totalCount,
      Value<int> rowid,
    });
typedef $$FoldersTableUpdateCompanionBuilder =
    FoldersCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<String> name,
      Value<String> role,
      Value<String> remoteId,
      Value<String?> parentRemoteId,
      Value<int?> unreadCount,
      Value<int?> totalCount,
      Value<int> rowid,
    });

final class $$FoldersTableReferences
    extends BaseReferences<_$ByteMailDatabase, $FoldersTable, Folder> {
  $$FoldersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$ByteMailDatabase db) =>
      db.accounts.createAlias('folders__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FoldersTableFilterComposer
    extends Composer<_$ByteMailDatabase, $FoldersTable> {
  $$FoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentRemoteId => $composableBuilder(
    column: $table.parentRemoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCount => $composableBuilder(
    column: $table.totalCount,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FoldersTableOrderingComposer
    extends Composer<_$ByteMailDatabase, $FoldersTable> {
  $$FoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentRemoteId => $composableBuilder(
    column: $table.parentRemoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCount => $composableBuilder(
    column: $table.totalCount,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FoldersTableAnnotationComposer
    extends Composer<_$ByteMailDatabase, $FoldersTable> {
  $$FoldersTableAnnotationComposer({
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

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get parentRemoteId => $composableBuilder(
    column: $table.parentRemoteId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalCount => $composableBuilder(
    column: $table.totalCount,
    builder: (column) => column,
  );

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FoldersTableTableManager
    extends
        RootTableManager<
          _$ByteMailDatabase,
          $FoldersTable,
          Folder,
          $$FoldersTableFilterComposer,
          $$FoldersTableOrderingComposer,
          $$FoldersTableAnnotationComposer,
          $$FoldersTableCreateCompanionBuilder,
          $$FoldersTableUpdateCompanionBuilder,
          (Folder, $$FoldersTableReferences),
          Folder,
          PrefetchHooks Function({bool accountId})
        > {
  $$FoldersTableTableManager(_$ByteMailDatabase db, $FoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> remoteId = const Value.absent(),
                Value<String?> parentRemoteId = const Value.absent(),
                Value<int?> unreadCount = const Value.absent(),
                Value<int?> totalCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoldersCompanion(
                id: id,
                accountId: accountId,
                name: name,
                role: role,
                remoteId: remoteId,
                parentRemoteId: parentRemoteId,
                unreadCount: unreadCount,
                totalCount: totalCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required String name,
                Value<String> role = const Value.absent(),
                required String remoteId,
                Value<String?> parentRemoteId = const Value.absent(),
                Value<int?> unreadCount = const Value.absent(),
                Value<int?> totalCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoldersCompanion.insert(
                id: id,
                accountId: accountId,
                name: name,
                role: role,
                remoteId: remoteId,
                parentRemoteId: parentRemoteId,
                unreadCount: unreadCount,
                totalCount: totalCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FoldersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable: $$FoldersTableReferences
                                    ._accountIdTable(db),
                                referencedColumn: $$FoldersTableReferences
                                    ._accountIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$ByteMailDatabase,
      $FoldersTable,
      Folder,
      $$FoldersTableFilterComposer,
      $$FoldersTableOrderingComposer,
      $$FoldersTableAnnotationComposer,
      $$FoldersTableCreateCompanionBuilder,
      $$FoldersTableUpdateCompanionBuilder,
      (Folder, $$FoldersTableReferences),
      Folder,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      required String id,
      required String accountId,
      required String folderId,
      required String providerId,
      required String messageIdHeader,
      required String fromName,
      required String fromAddress,
      required String subject,
      required String snippet,
      Value<String?> body,
      required int whenEpochMs,
      required String focusBucket,
      Value<bool> unread,
      Value<bool> pinned,
      Value<bool> hasAttachments,
      Value<String?> rawHeaders,
      Value<String> toRecipients,
      Value<String> ccRecipients,
      Value<bool> starred,
      Value<String?> threadId,
      Value<int?> snoozedUntil,
      Value<int?> trashedAt,
      Value<bool> isDraft,
      Value<String?> draftSyncProviderId,
      Value<int> rowid,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<String> folderId,
      Value<String> providerId,
      Value<String> messageIdHeader,
      Value<String> fromName,
      Value<String> fromAddress,
      Value<String> subject,
      Value<String> snippet,
      Value<String?> body,
      Value<int> whenEpochMs,
      Value<String> focusBucket,
      Value<bool> unread,
      Value<bool> pinned,
      Value<bool> hasAttachments,
      Value<String?> rawHeaders,
      Value<String> toRecipients,
      Value<String> ccRecipients,
      Value<bool> starred,
      Value<String?> threadId,
      Value<int?> snoozedUntil,
      Value<int?> trashedAt,
      Value<bool> isDraft,
      Value<String?> draftSyncProviderId,
      Value<int> rowid,
    });

final class $$MessagesTableReferences
    extends BaseReferences<_$ByteMailDatabase, $MessagesTable, Message> {
  $$MessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$ByteMailDatabase db) =>
      db.accounts.createAlias('messages__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AttachmentsTable, List<Attachment>>
  _attachmentsRefsTable(_$ByteMailDatabase db) => MultiTypedResultKey.fromTable(
    db.attachments,
    aliasName: 'messages__id__attachments__message_id',
  );

  $$AttachmentsTableProcessedTableManager get attachmentsRefs {
    final manager = $$AttachmentsTableTableManager(
      $_db,
      $_db.attachments,
    ).filter((f) => f.messageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_attachmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MessagesTableFilterComposer
    extends Composer<_$ByteMailDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageIdHeader => $composableBuilder(
    column: $table.messageIdHeader,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromName => $composableBuilder(
    column: $table.fromName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromAddress => $composableBuilder(
    column: $table.fromAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snippet => $composableBuilder(
    column: $table.snippet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get whenEpochMs => $composableBuilder(
    column: $table.whenEpochMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get focusBucket => $composableBuilder(
    column: $table.focusBucket,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get unread => $composableBuilder(
    column: $table.unread,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasAttachments => $composableBuilder(
    column: $table.hasAttachments,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawHeaders => $composableBuilder(
    column: $table.rawHeaders,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toRecipients => $composableBuilder(
    column: $table.toRecipients,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ccRecipients => $composableBuilder(
    column: $table.ccRecipients,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get starred => $composableBuilder(
    column: $table.starred,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trashedAt => $composableBuilder(
    column: $table.trashedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDraft => $composableBuilder(
    column: $table.isDraft,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get draftSyncProviderId => $composableBuilder(
    column: $table.draftSyncProviderId,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> attachmentsRefs(
    Expression<bool> Function($$AttachmentsTableFilterComposer f) f,
  ) {
    final $$AttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.messageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MessagesTableOrderingComposer
    extends Composer<_$ByteMailDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageIdHeader => $composableBuilder(
    column: $table.messageIdHeader,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromName => $composableBuilder(
    column: $table.fromName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromAddress => $composableBuilder(
    column: $table.fromAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snippet => $composableBuilder(
    column: $table.snippet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get whenEpochMs => $composableBuilder(
    column: $table.whenEpochMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get focusBucket => $composableBuilder(
    column: $table.focusBucket,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get unread => $composableBuilder(
    column: $table.unread,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasAttachments => $composableBuilder(
    column: $table.hasAttachments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawHeaders => $composableBuilder(
    column: $table.rawHeaders,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toRecipients => $composableBuilder(
    column: $table.toRecipients,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ccRecipients => $composableBuilder(
    column: $table.ccRecipients,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get starred => $composableBuilder(
    column: $table.starred,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trashedAt => $composableBuilder(
    column: $table.trashedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDraft => $composableBuilder(
    column: $table.isDraft,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get draftSyncProviderId => $composableBuilder(
    column: $table.draftSyncProviderId,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$ByteMailDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get messageIdHeader => $composableBuilder(
    column: $table.messageIdHeader,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fromName =>
      $composableBuilder(column: $table.fromName, builder: (column) => column);

  GeneratedColumn<String> get fromAddress => $composableBuilder(
    column: $table.fromAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get snippet =>
      $composableBuilder(column: $table.snippet, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get whenEpochMs => $composableBuilder(
    column: $table.whenEpochMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get focusBucket => $composableBuilder(
    column: $table.focusBucket,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get unread =>
      $composableBuilder(column: $table.unread, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumn<bool> get hasAttachments => $composableBuilder(
    column: $table.hasAttachments,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawHeaders => $composableBuilder(
    column: $table.rawHeaders,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toRecipients => $composableBuilder(
    column: $table.toRecipients,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ccRecipients => $composableBuilder(
    column: $table.ccRecipients,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get starred =>
      $composableBuilder(column: $table.starred, builder: (column) => column);

  GeneratedColumn<String> get threadId =>
      $composableBuilder(column: $table.threadId, builder: (column) => column);

  GeneratedColumn<int> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trashedAt =>
      $composableBuilder(column: $table.trashedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDraft =>
      $composableBuilder(column: $table.isDraft, builder: (column) => column);

  GeneratedColumn<String> get draftSyncProviderId => $composableBuilder(
    column: $table.draftSyncProviderId,
    builder: (column) => column,
  );

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> attachmentsRefs<T extends Object>(
    Expression<T> Function($$AttachmentsTableAnnotationComposer a) f,
  ) {
    final $$AttachmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.messageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$ByteMailDatabase,
          $MessagesTable,
          Message,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (Message, $$MessagesTableReferences),
          Message,
          PrefetchHooks Function({bool accountId, bool attachmentsRefs})
        > {
  $$MessagesTableTableManager(_$ByteMailDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> folderId = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String> messageIdHeader = const Value.absent(),
                Value<String> fromName = const Value.absent(),
                Value<String> fromAddress = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> snippet = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<int> whenEpochMs = const Value.absent(),
                Value<String> focusBucket = const Value.absent(),
                Value<bool> unread = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<bool> hasAttachments = const Value.absent(),
                Value<String?> rawHeaders = const Value.absent(),
                Value<String> toRecipients = const Value.absent(),
                Value<String> ccRecipients = const Value.absent(),
                Value<bool> starred = const Value.absent(),
                Value<String?> threadId = const Value.absent(),
                Value<int?> snoozedUntil = const Value.absent(),
                Value<int?> trashedAt = const Value.absent(),
                Value<bool> isDraft = const Value.absent(),
                Value<String?> draftSyncProviderId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                accountId: accountId,
                folderId: folderId,
                providerId: providerId,
                messageIdHeader: messageIdHeader,
                fromName: fromName,
                fromAddress: fromAddress,
                subject: subject,
                snippet: snippet,
                body: body,
                whenEpochMs: whenEpochMs,
                focusBucket: focusBucket,
                unread: unread,
                pinned: pinned,
                hasAttachments: hasAttachments,
                rawHeaders: rawHeaders,
                toRecipients: toRecipients,
                ccRecipients: ccRecipients,
                starred: starred,
                threadId: threadId,
                snoozedUntil: snoozedUntil,
                trashedAt: trashedAt,
                isDraft: isDraft,
                draftSyncProviderId: draftSyncProviderId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required String folderId,
                required String providerId,
                required String messageIdHeader,
                required String fromName,
                required String fromAddress,
                required String subject,
                required String snippet,
                Value<String?> body = const Value.absent(),
                required int whenEpochMs,
                required String focusBucket,
                Value<bool> unread = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<bool> hasAttachments = const Value.absent(),
                Value<String?> rawHeaders = const Value.absent(),
                Value<String> toRecipients = const Value.absent(),
                Value<String> ccRecipients = const Value.absent(),
                Value<bool> starred = const Value.absent(),
                Value<String?> threadId = const Value.absent(),
                Value<int?> snoozedUntil = const Value.absent(),
                Value<int?> trashedAt = const Value.absent(),
                Value<bool> isDraft = const Value.absent(),
                Value<String?> draftSyncProviderId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                accountId: accountId,
                folderId: folderId,
                providerId: providerId,
                messageIdHeader: messageIdHeader,
                fromName: fromName,
                fromAddress: fromAddress,
                subject: subject,
                snippet: snippet,
                body: body,
                whenEpochMs: whenEpochMs,
                focusBucket: focusBucket,
                unread: unread,
                pinned: pinned,
                hasAttachments: hasAttachments,
                rawHeaders: rawHeaders,
                toRecipients: toRecipients,
                ccRecipients: ccRecipients,
                starred: starred,
                threadId: threadId,
                snoozedUntil: snoozedUntil,
                trashedAt: trashedAt,
                isDraft: isDraft,
                draftSyncProviderId: draftSyncProviderId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({accountId = false, attachmentsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (attachmentsRefs) db.attachments,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (accountId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.accountId,
                                    referencedTable: $$MessagesTableReferences
                                        ._accountIdTable(db),
                                    referencedColumn: $$MessagesTableReferences
                                        ._accountIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (attachmentsRefs)
                        await $_getPrefetchedData<
                          Message,
                          $MessagesTable,
                          Attachment
                        >(
                          currentTable: table,
                          referencedTable: $$MessagesTableReferences
                              ._attachmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MessagesTableReferences(
                                db,
                                table,
                                p0,
                              ).attachmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.messageId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$ByteMailDatabase,
      $MessagesTable,
      Message,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (Message, $$MessagesTableReferences),
      Message,
      PrefetchHooks Function({bool accountId, bool attachmentsRefs})
    >;
typedef $$FocusRulesTableCreateCompanionBuilder =
    FocusRulesCompanion Function({
      required String id,
      Value<String?> accountId,
      required String pattern,
      required String matchType,
      required String bucket,
      Value<int> rowid,
    });
typedef $$FocusRulesTableUpdateCompanionBuilder =
    FocusRulesCompanion Function({
      Value<String> id,
      Value<String?> accountId,
      Value<String> pattern,
      Value<String> matchType,
      Value<String> bucket,
      Value<int> rowid,
    });

final class $$FocusRulesTableReferences
    extends BaseReferences<_$ByteMailDatabase, $FocusRulesTable, FocusRule> {
  $$FocusRulesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$ByteMailDatabase db) =>
      db.accounts.createAlias('focus_rules__account_id__accounts__id');

  $$AccountsTableProcessedTableManager? get accountId {
    final $_column = $_itemColumn<String>('account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FocusRulesTableFilterComposer
    extends Composer<_$ByteMailDatabase, $FocusRulesTable> {
  $$FocusRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pattern => $composableBuilder(
    column: $table.pattern,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchType => $composableBuilder(
    column: $table.matchType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bucket => $composableBuilder(
    column: $table.bucket,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FocusRulesTableOrderingComposer
    extends Composer<_$ByteMailDatabase, $FocusRulesTable> {
  $$FocusRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pattern => $composableBuilder(
    column: $table.pattern,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchType => $composableBuilder(
    column: $table.matchType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bucket => $composableBuilder(
    column: $table.bucket,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FocusRulesTableAnnotationComposer
    extends Composer<_$ByteMailDatabase, $FocusRulesTable> {
  $$FocusRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pattern =>
      $composableBuilder(column: $table.pattern, builder: (column) => column);

  GeneratedColumn<String> get matchType =>
      $composableBuilder(column: $table.matchType, builder: (column) => column);

  GeneratedColumn<String> get bucket =>
      $composableBuilder(column: $table.bucket, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FocusRulesTableTableManager
    extends
        RootTableManager<
          _$ByteMailDatabase,
          $FocusRulesTable,
          FocusRule,
          $$FocusRulesTableFilterComposer,
          $$FocusRulesTableOrderingComposer,
          $$FocusRulesTableAnnotationComposer,
          $$FocusRulesTableCreateCompanionBuilder,
          $$FocusRulesTableUpdateCompanionBuilder,
          (FocusRule, $$FocusRulesTableReferences),
          FocusRule,
          PrefetchHooks Function({bool accountId})
        > {
  $$FocusRulesTableTableManager(_$ByteMailDatabase db, $FocusRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FocusRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FocusRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FocusRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String> pattern = const Value.absent(),
                Value<String> matchType = const Value.absent(),
                Value<String> bucket = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FocusRulesCompanion(
                id: id,
                accountId: accountId,
                pattern: pattern,
                matchType: matchType,
                bucket: bucket,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> accountId = const Value.absent(),
                required String pattern,
                required String matchType,
                required String bucket,
                Value<int> rowid = const Value.absent(),
              }) => FocusRulesCompanion.insert(
                id: id,
                accountId: accountId,
                pattern: pattern,
                matchType: matchType,
                bucket: bucket,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FocusRulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable: $$FocusRulesTableReferences
                                    ._accountIdTable(db),
                                referencedColumn: $$FocusRulesTableReferences
                                    ._accountIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FocusRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$ByteMailDatabase,
      $FocusRulesTable,
      FocusRule,
      $$FocusRulesTableFilterComposer,
      $$FocusRulesTableOrderingComposer,
      $$FocusRulesTableAnnotationComposer,
      $$FocusRulesTableCreateCompanionBuilder,
      $$FocusRulesTableUpdateCompanionBuilder,
      (FocusRule, $$FocusRulesTableReferences),
      FocusRule,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$OutboxTableCreateCompanionBuilder =
    OutboxCompanion Function({
      required String id,
      required String accountId,
      required String recipientsJson,
      required String subject,
      required String body,
      required String state,
      Value<int> attempts,
      Value<String?> lastError,
      required int createdAt,
      Value<String?> ccJson,
      Value<String?> bccJson,
      Value<String> composeMode,
      Value<String?> inReplyTo,
      Value<String?> referencesJson,
      Value<String?> attachmentRefsJson,
      Value<String?> signatureId,
      Value<int?> sendAfter,
      Value<int> rowid,
    });
typedef $$OutboxTableUpdateCompanionBuilder =
    OutboxCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<String> recipientsJson,
      Value<String> subject,
      Value<String> body,
      Value<String> state,
      Value<int> attempts,
      Value<String?> lastError,
      Value<int> createdAt,
      Value<String?> ccJson,
      Value<String?> bccJson,
      Value<String> composeMode,
      Value<String?> inReplyTo,
      Value<String?> referencesJson,
      Value<String?> attachmentRefsJson,
      Value<String?> signatureId,
      Value<int?> sendAfter,
      Value<int> rowid,
    });

final class $$OutboxTableReferences
    extends BaseReferences<_$ByteMailDatabase, $OutboxTable, OutboxData> {
  $$OutboxTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$ByteMailDatabase db) =>
      db.accounts.createAlias('outbox__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OutboxTableFilterComposer
    extends Composer<_$ByteMailDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipientsJson => $composableBuilder(
    column: $table.recipientsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ccJson => $composableBuilder(
    column: $table.ccJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bccJson => $composableBuilder(
    column: $table.bccJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get composeMode => $composableBuilder(
    column: $table.composeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inReplyTo => $composableBuilder(
    column: $table.inReplyTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referencesJson => $composableBuilder(
    column: $table.referencesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachmentRefsJson => $composableBuilder(
    column: $table.attachmentRefsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signatureId => $composableBuilder(
    column: $table.signatureId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sendAfter => $composableBuilder(
    column: $table.sendAfter,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OutboxTableOrderingComposer
    extends Composer<_$ByteMailDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipientsJson => $composableBuilder(
    column: $table.recipientsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ccJson => $composableBuilder(
    column: $table.ccJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bccJson => $composableBuilder(
    column: $table.bccJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get composeMode => $composableBuilder(
    column: $table.composeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inReplyTo => $composableBuilder(
    column: $table.inReplyTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referencesJson => $composableBuilder(
    column: $table.referencesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentRefsJson => $composableBuilder(
    column: $table.attachmentRefsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signatureId => $composableBuilder(
    column: $table.signatureId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sendAfter => $composableBuilder(
    column: $table.sendAfter,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$ByteMailDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get recipientsJson => $composableBuilder(
    column: $table.recipientsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get ccJson =>
      $composableBuilder(column: $table.ccJson, builder: (column) => column);

  GeneratedColumn<String> get bccJson =>
      $composableBuilder(column: $table.bccJson, builder: (column) => column);

  GeneratedColumn<String> get composeMode => $composableBuilder(
    column: $table.composeMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inReplyTo =>
      $composableBuilder(column: $table.inReplyTo, builder: (column) => column);

  GeneratedColumn<String> get referencesJson => $composableBuilder(
    column: $table.referencesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get attachmentRefsJson => $composableBuilder(
    column: $table.attachmentRefsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get signatureId => $composableBuilder(
    column: $table.signatureId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sendAfter =>
      $composableBuilder(column: $table.sendAfter, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$ByteMailDatabase,
          $OutboxTable,
          OutboxData,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (OutboxData, $$OutboxTableReferences),
          OutboxData,
          PrefetchHooks Function({bool accountId})
        > {
  $$OutboxTableTableManager(_$ByteMailDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> recipientsJson = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String?> ccJson = const Value.absent(),
                Value<String?> bccJson = const Value.absent(),
                Value<String> composeMode = const Value.absent(),
                Value<String?> inReplyTo = const Value.absent(),
                Value<String?> referencesJson = const Value.absent(),
                Value<String?> attachmentRefsJson = const Value.absent(),
                Value<String?> signatureId = const Value.absent(),
                Value<int?> sendAfter = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion(
                id: id,
                accountId: accountId,
                recipientsJson: recipientsJson,
                subject: subject,
                body: body,
                state: state,
                attempts: attempts,
                lastError: lastError,
                createdAt: createdAt,
                ccJson: ccJson,
                bccJson: bccJson,
                composeMode: composeMode,
                inReplyTo: inReplyTo,
                referencesJson: referencesJson,
                attachmentRefsJson: attachmentRefsJson,
                signatureId: signatureId,
                sendAfter: sendAfter,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required String recipientsJson,
                required String subject,
                required String body,
                required String state,
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required int createdAt,
                Value<String?> ccJson = const Value.absent(),
                Value<String?> bccJson = const Value.absent(),
                Value<String> composeMode = const Value.absent(),
                Value<String?> inReplyTo = const Value.absent(),
                Value<String?> referencesJson = const Value.absent(),
                Value<String?> attachmentRefsJson = const Value.absent(),
                Value<String?> signatureId = const Value.absent(),
                Value<int?> sendAfter = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion.insert(
                id: id,
                accountId: accountId,
                recipientsJson: recipientsJson,
                subject: subject,
                body: body,
                state: state,
                attempts: attempts,
                lastError: lastError,
                createdAt: createdAt,
                ccJson: ccJson,
                bccJson: bccJson,
                composeMode: composeMode,
                inReplyTo: inReplyTo,
                referencesJson: referencesJson,
                attachmentRefsJson: attachmentRefsJson,
                signatureId: signatureId,
                sendAfter: sendAfter,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$OutboxTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable: $$OutboxTableReferences
                                    ._accountIdTable(db),
                                referencedColumn: $$OutboxTableReferences
                                    ._accountIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$ByteMailDatabase,
      $OutboxTable,
      OutboxData,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxData, $$OutboxTableReferences),
      OutboxData,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$JobsTableCreateCompanionBuilder =
    JobsCompanion Function({
      required String id,
      required String accountId,
      required String type,
      required String status,
      Value<String?> payloadJson,
      Value<String?> cursorJson,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$JobsTableUpdateCompanionBuilder =
    JobsCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<String> type,
      Value<String> status,
      Value<String?> payloadJson,
      Value<String?> cursorJson,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$JobsTableReferences
    extends BaseReferences<_$ByteMailDatabase, $JobsTable, Job> {
  $$JobsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$ByteMailDatabase db) =>
      db.accounts.createAlias('sync_jobs__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$JobsTableFilterComposer
    extends Composer<_$ByteMailDatabase, $JobsTable> {
  $$JobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursorJson => $composableBuilder(
    column: $table.cursorJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JobsTableOrderingComposer
    extends Composer<_$ByteMailDatabase, $JobsTable> {
  $$JobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursorJson => $composableBuilder(
    column: $table.cursorJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JobsTableAnnotationComposer
    extends Composer<_$ByteMailDatabase, $JobsTable> {
  $$JobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cursorJson => $composableBuilder(
    column: $table.cursorJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JobsTableTableManager
    extends
        RootTableManager<
          _$ByteMailDatabase,
          $JobsTable,
          Job,
          $$JobsTableFilterComposer,
          $$JobsTableOrderingComposer,
          $$JobsTableAnnotationComposer,
          $$JobsTableCreateCompanionBuilder,
          $$JobsTableUpdateCompanionBuilder,
          (Job, $$JobsTableReferences),
          Job,
          PrefetchHooks Function({bool accountId})
        > {
  $$JobsTableTableManager(_$ByteMailDatabase db, $JobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> payloadJson = const Value.absent(),
                Value<String?> cursorJson = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JobsCompanion(
                id: id,
                accountId: accountId,
                type: type,
                status: status,
                payloadJson: payloadJson,
                cursorJson: cursorJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required String type,
                required String status,
                Value<String?> payloadJson = const Value.absent(),
                Value<String?> cursorJson = const Value.absent(),
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => JobsCompanion.insert(
                id: id,
                accountId: accountId,
                type: type,
                status: status,
                payloadJson: payloadJson,
                cursorJson: cursorJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$JobsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable: $$JobsTableReferences
                                    ._accountIdTable(db),
                                referencedColumn: $$JobsTableReferences
                                    ._accountIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$JobsTableProcessedTableManager =
    ProcessedTableManager<
      _$ByteMailDatabase,
      $JobsTable,
      Job,
      $$JobsTableFilterComposer,
      $$JobsTableOrderingComposer,
      $$JobsTableAnnotationComposer,
      $$JobsTableCreateCompanionBuilder,
      $$JobsTableUpdateCompanionBuilder,
      (Job, $$JobsTableReferences),
      Job,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$SyncCursorsTableCreateCompanionBuilder =
    SyncCursorsCompanion Function({
      required String accountId,
      required String folderId,
      required String cursorKey,
      required String cursorValue,
      Value<int> rowid,
    });
typedef $$SyncCursorsTableUpdateCompanionBuilder =
    SyncCursorsCompanion Function({
      Value<String> accountId,
      Value<String> folderId,
      Value<String> cursorKey,
      Value<String> cursorValue,
      Value<int> rowid,
    });

final class $$SyncCursorsTableReferences
    extends BaseReferences<_$ByteMailDatabase, $SyncCursorsTable, SyncCursor> {
  $$SyncCursorsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$ByteMailDatabase db) =>
      db.accounts.createAlias('sync_cursors__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SyncCursorsTableFilterComposer
    extends Composer<_$ByteMailDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursorKey => $composableBuilder(
    column: $table.cursorKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursorValue => $composableBuilder(
    column: $table.cursorValue,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncCursorsTableOrderingComposer
    extends Composer<_$ByteMailDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursorKey => $composableBuilder(
    column: $table.cursorKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursorValue => $composableBuilder(
    column: $table.cursorValue,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncCursorsTableAnnotationComposer
    extends Composer<_$ByteMailDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);

  GeneratedColumn<String> get cursorKey =>
      $composableBuilder(column: $table.cursorKey, builder: (column) => column);

  GeneratedColumn<String> get cursorValue => $composableBuilder(
    column: $table.cursorValue,
    builder: (column) => column,
  );

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncCursorsTableTableManager
    extends
        RootTableManager<
          _$ByteMailDatabase,
          $SyncCursorsTable,
          SyncCursor,
          $$SyncCursorsTableFilterComposer,
          $$SyncCursorsTableOrderingComposer,
          $$SyncCursorsTableAnnotationComposer,
          $$SyncCursorsTableCreateCompanionBuilder,
          $$SyncCursorsTableUpdateCompanionBuilder,
          (SyncCursor, $$SyncCursorsTableReferences),
          SyncCursor,
          PrefetchHooks Function({bool accountId})
        > {
  $$SyncCursorsTableTableManager(_$ByteMailDatabase db, $SyncCursorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> folderId = const Value.absent(),
                Value<String> cursorKey = const Value.absent(),
                Value<String> cursorValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion(
                accountId: accountId,
                folderId: folderId,
                cursorKey: cursorKey,
                cursorValue: cursorValue,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String folderId,
                required String cursorKey,
                required String cursorValue,
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion.insert(
                accountId: accountId,
                folderId: folderId,
                cursorKey: cursorKey,
                cursorValue: cursorValue,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SyncCursorsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable: $$SyncCursorsTableReferences
                                    ._accountIdTable(db),
                                referencedColumn: $$SyncCursorsTableReferences
                                    ._accountIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SyncCursorsTableProcessedTableManager =
    ProcessedTableManager<
      _$ByteMailDatabase,
      $SyncCursorsTable,
      SyncCursor,
      $$SyncCursorsTableFilterComposer,
      $$SyncCursorsTableOrderingComposer,
      $$SyncCursorsTableAnnotationComposer,
      $$SyncCursorsTableCreateCompanionBuilder,
      $$SyncCursorsTableUpdateCompanionBuilder,
      (SyncCursor, $$SyncCursorsTableReferences),
      SyncCursor,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$WidgetSnapshotsTableCreateCompanionBuilder =
    WidgetSnapshotsCompanion Function({
      required String id,
      required String kind,
      required String payloadJson,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$WidgetSnapshotsTableUpdateCompanionBuilder =
    WidgetSnapshotsCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<String> payloadJson,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$WidgetSnapshotsTableFilterComposer
    extends Composer<_$ByteMailDatabase, $WidgetSnapshotsTable> {
  $$WidgetSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WidgetSnapshotsTableOrderingComposer
    extends Composer<_$ByteMailDatabase, $WidgetSnapshotsTable> {
  $$WidgetSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WidgetSnapshotsTableAnnotationComposer
    extends Composer<_$ByteMailDatabase, $WidgetSnapshotsTable> {
  $$WidgetSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WidgetSnapshotsTableTableManager
    extends
        RootTableManager<
          _$ByteMailDatabase,
          $WidgetSnapshotsTable,
          WidgetSnapshot,
          $$WidgetSnapshotsTableFilterComposer,
          $$WidgetSnapshotsTableOrderingComposer,
          $$WidgetSnapshotsTableAnnotationComposer,
          $$WidgetSnapshotsTableCreateCompanionBuilder,
          $$WidgetSnapshotsTableUpdateCompanionBuilder,
          (
            WidgetSnapshot,
            BaseReferences<
              _$ByteMailDatabase,
              $WidgetSnapshotsTable,
              WidgetSnapshot
            >,
          ),
          WidgetSnapshot,
          PrefetchHooks Function()
        > {
  $$WidgetSnapshotsTableTableManager(
    _$ByteMailDatabase db,
    $WidgetSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WidgetSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WidgetSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WidgetSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WidgetSnapshotsCompanion(
                id: id,
                kind: kind,
                payloadJson: payloadJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String payloadJson,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => WidgetSnapshotsCompanion.insert(
                id: id,
                kind: kind,
                payloadJson: payloadJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WidgetSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$ByteMailDatabase,
      $WidgetSnapshotsTable,
      WidgetSnapshot,
      $$WidgetSnapshotsTableFilterComposer,
      $$WidgetSnapshotsTableOrderingComposer,
      $$WidgetSnapshotsTableAnnotationComposer,
      $$WidgetSnapshotsTableCreateCompanionBuilder,
      $$WidgetSnapshotsTableUpdateCompanionBuilder,
      (
        WidgetSnapshot,
        BaseReferences<
          _$ByteMailDatabase,
          $WidgetSnapshotsTable,
          WidgetSnapshot
        >,
      ),
      WidgetSnapshot,
      PrefetchHooks Function()
    >;
typedef $$SyncProfilesTableCreateCompanionBuilder =
    SyncProfilesCompanion Function({
      required String id,
      required String name,
      required int retentionDays,
      Value<String?> folderScopeJson,
      Value<String> bodyPolicy,
      Value<int> attachmentMaxMb,
      Value<bool> isDefault,
      Value<int> rowid,
    });
typedef $$SyncProfilesTableUpdateCompanionBuilder =
    SyncProfilesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> retentionDays,
      Value<String?> folderScopeJson,
      Value<String> bodyPolicy,
      Value<int> attachmentMaxMb,
      Value<bool> isDefault,
      Value<int> rowid,
    });

class $$SyncProfilesTableFilterComposer
    extends Composer<_$ByteMailDatabase, $SyncProfilesTable> {
  $$SyncProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retentionDays => $composableBuilder(
    column: $table.retentionDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderScopeJson => $composableBuilder(
    column: $table.folderScopeJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bodyPolicy => $composableBuilder(
    column: $table.bodyPolicy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attachmentMaxMb => $composableBuilder(
    column: $table.attachmentMaxMb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncProfilesTableOrderingComposer
    extends Composer<_$ByteMailDatabase, $SyncProfilesTable> {
  $$SyncProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retentionDays => $composableBuilder(
    column: $table.retentionDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderScopeJson => $composableBuilder(
    column: $table.folderScopeJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bodyPolicy => $composableBuilder(
    column: $table.bodyPolicy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attachmentMaxMb => $composableBuilder(
    column: $table.attachmentMaxMb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncProfilesTableAnnotationComposer
    extends Composer<_$ByteMailDatabase, $SyncProfilesTable> {
  $$SyncProfilesTableAnnotationComposer({
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

  GeneratedColumn<int> get retentionDays => $composableBuilder(
    column: $table.retentionDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get folderScopeJson => $composableBuilder(
    column: $table.folderScopeJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bodyPolicy => $composableBuilder(
    column: $table.bodyPolicy,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attachmentMaxMb => $composableBuilder(
    column: $table.attachmentMaxMb,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);
}

class $$SyncProfilesTableTableManager
    extends
        RootTableManager<
          _$ByteMailDatabase,
          $SyncProfilesTable,
          SyncProfile,
          $$SyncProfilesTableFilterComposer,
          $$SyncProfilesTableOrderingComposer,
          $$SyncProfilesTableAnnotationComposer,
          $$SyncProfilesTableCreateCompanionBuilder,
          $$SyncProfilesTableUpdateCompanionBuilder,
          (
            SyncProfile,
            BaseReferences<_$ByteMailDatabase, $SyncProfilesTable, SyncProfile>,
          ),
          SyncProfile,
          PrefetchHooks Function()
        > {
  $$SyncProfilesTableTableManager(
    _$ByteMailDatabase db,
    $SyncProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> retentionDays = const Value.absent(),
                Value<String?> folderScopeJson = const Value.absent(),
                Value<String> bodyPolicy = const Value.absent(),
                Value<int> attachmentMaxMb = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncProfilesCompanion(
                id: id,
                name: name,
                retentionDays: retentionDays,
                folderScopeJson: folderScopeJson,
                bodyPolicy: bodyPolicy,
                attachmentMaxMb: attachmentMaxMb,
                isDefault: isDefault,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int retentionDays,
                Value<String?> folderScopeJson = const Value.absent(),
                Value<String> bodyPolicy = const Value.absent(),
                Value<int> attachmentMaxMb = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncProfilesCompanion.insert(
                id: id,
                name: name,
                retentionDays: retentionDays,
                folderScopeJson: folderScopeJson,
                bodyPolicy: bodyPolicy,
                attachmentMaxMb: attachmentMaxMb,
                isDefault: isDefault,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$ByteMailDatabase,
      $SyncProfilesTable,
      SyncProfile,
      $$SyncProfilesTableFilterComposer,
      $$SyncProfilesTableOrderingComposer,
      $$SyncProfilesTableAnnotationComposer,
      $$SyncProfilesTableCreateCompanionBuilder,
      $$SyncProfilesTableUpdateCompanionBuilder,
      (
        SyncProfile,
        BaseReferences<_$ByteMailDatabase, $SyncProfilesTable, SyncProfile>,
      ),
      SyncProfile,
      PrefetchHooks Function()
    >;
typedef $$AttachmentsTableCreateCompanionBuilder =
    AttachmentsCompanion Function({
      required String id,
      required String messageId,
      required String accountId,
      Value<String?> providerPartId,
      required String filename,
      required String mimeType,
      required int sizeBytes,
      Value<String?> localPath,
      Value<int?> fetchedAt,
      Value<int> rowid,
    });
typedef $$AttachmentsTableUpdateCompanionBuilder =
    AttachmentsCompanion Function({
      Value<String> id,
      Value<String> messageId,
      Value<String> accountId,
      Value<String?> providerPartId,
      Value<String> filename,
      Value<String> mimeType,
      Value<int> sizeBytes,
      Value<String?> localPath,
      Value<int?> fetchedAt,
      Value<int> rowid,
    });

final class $$AttachmentsTableReferences
    extends BaseReferences<_$ByteMailDatabase, $AttachmentsTable, Attachment> {
  $$AttachmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MessagesTable _messageIdTable(_$ByteMailDatabase db) =>
      db.messages.createAlias('attachments__message_id__messages__id');

  $$MessagesTableProcessedTableManager get messageId {
    final $_column = $_itemColumn<String>('message_id')!;

    final manager = $$MessagesTableTableManager(
      $_db,
      $_db.messages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_messageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _accountIdTable(_$ByteMailDatabase db) =>
      db.accounts.createAlias('attachments__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttachmentsTableFilterComposer
    extends Composer<_$ByteMailDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerPartId => $composableBuilder(
    column: $table.providerPartId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MessagesTableFilterComposer get messageId {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.messageId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableFilterComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableOrderingComposer
    extends Composer<_$ByteMailDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerPartId => $composableBuilder(
    column: $table.providerPartId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MessagesTableOrderingComposer get messageId {
    final $$MessagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.messageId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableOrderingComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableAnnotationComposer
    extends Composer<_$ByteMailDatabase, $AttachmentsTable> {
  $$AttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get providerPartId => $composableBuilder(
    column: $table.providerPartId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filename =>
      $composableBuilder(column: $table.filename, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  $$MessagesTableAnnotationComposer get messageId {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.messageId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableTableManager
    extends
        RootTableManager<
          _$ByteMailDatabase,
          $AttachmentsTable,
          Attachment,
          $$AttachmentsTableFilterComposer,
          $$AttachmentsTableOrderingComposer,
          $$AttachmentsTableAnnotationComposer,
          $$AttachmentsTableCreateCompanionBuilder,
          $$AttachmentsTableUpdateCompanionBuilder,
          (Attachment, $$AttachmentsTableReferences),
          Attachment,
          PrefetchHooks Function({bool messageId, bool accountId})
        > {
  $$AttachmentsTableTableManager(_$ByteMailDatabase db, $AttachmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> messageId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String?> providerPartId = const Value.absent(),
                Value<String> filename = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<int?> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion(
                id: id,
                messageId: messageId,
                accountId: accountId,
                providerPartId: providerPartId,
                filename: filename,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                localPath: localPath,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String messageId,
                required String accountId,
                Value<String?> providerPartId = const Value.absent(),
                required String filename,
                required String mimeType,
                required int sizeBytes,
                Value<String?> localPath = const Value.absent(),
                Value<int?> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion.insert(
                id: id,
                messageId: messageId,
                accountId: accountId,
                providerPartId: providerPartId,
                filename: filename,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                localPath: localPath,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AttachmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({messageId = false, accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (messageId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.messageId,
                                referencedTable: $$AttachmentsTableReferences
                                    ._messageIdTable(db),
                                referencedColumn: $$AttachmentsTableReferences
                                    ._messageIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable: $$AttachmentsTableReferences
                                    ._accountIdTable(db),
                                referencedColumn: $$AttachmentsTableReferences
                                    ._accountIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$ByteMailDatabase,
      $AttachmentsTable,
      Attachment,
      $$AttachmentsTableFilterComposer,
      $$AttachmentsTableOrderingComposer,
      $$AttachmentsTableAnnotationComposer,
      $$AttachmentsTableCreateCompanionBuilder,
      $$AttachmentsTableUpdateCompanionBuilder,
      (Attachment, $$AttachmentsTableReferences),
      Attachment,
      PrefetchHooks Function({bool messageId, bool accountId})
    >;
typedef $$AttachmentBlobsTableCreateCompanionBuilder =
    AttachmentBlobsCompanion Function({
      required String id,
      required String accountId,
      required String path,
      required int sizeBytes,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$AttachmentBlobsTableUpdateCompanionBuilder =
    AttachmentBlobsCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<String> path,
      Value<int> sizeBytes,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$AttachmentBlobsTableReferences
    extends
        BaseReferences<
          _$ByteMailDatabase,
          $AttachmentBlobsTable,
          AttachmentBlob
        > {
  $$AttachmentBlobsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AccountsTable _accountIdTable(_$ByteMailDatabase db) =>
      db.accounts.createAlias('attachment_blobs__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttachmentBlobsTableFilterComposer
    extends Composer<_$ByteMailDatabase, $AttachmentBlobsTable> {
  $$AttachmentBlobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentBlobsTableOrderingComposer
    extends Composer<_$ByteMailDatabase, $AttachmentBlobsTable> {
  $$AttachmentBlobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentBlobsTableAnnotationComposer
    extends Composer<_$ByteMailDatabase, $AttachmentBlobsTable> {
  $$AttachmentBlobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentBlobsTableTableManager
    extends
        RootTableManager<
          _$ByteMailDatabase,
          $AttachmentBlobsTable,
          AttachmentBlob,
          $$AttachmentBlobsTableFilterComposer,
          $$AttachmentBlobsTableOrderingComposer,
          $$AttachmentBlobsTableAnnotationComposer,
          $$AttachmentBlobsTableCreateCompanionBuilder,
          $$AttachmentBlobsTableUpdateCompanionBuilder,
          (AttachmentBlob, $$AttachmentBlobsTableReferences),
          AttachmentBlob,
          PrefetchHooks Function({bool accountId})
        > {
  $$AttachmentBlobsTableTableManager(
    _$ByteMailDatabase db,
    $AttachmentBlobsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentBlobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentBlobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentBlobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentBlobsCompanion(
                id: id,
                accountId: accountId,
                path: path,
                sizeBytes: sizeBytes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required String path,
                required int sizeBytes,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AttachmentBlobsCompanion.insert(
                id: id,
                accountId: accountId,
                path: path,
                sizeBytes: sizeBytes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AttachmentBlobsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable:
                                    $$AttachmentBlobsTableReferences
                                        ._accountIdTable(db),
                                referencedColumn:
                                    $$AttachmentBlobsTableReferences
                                        ._accountIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AttachmentBlobsTableProcessedTableManager =
    ProcessedTableManager<
      _$ByteMailDatabase,
      $AttachmentBlobsTable,
      AttachmentBlob,
      $$AttachmentBlobsTableFilterComposer,
      $$AttachmentBlobsTableOrderingComposer,
      $$AttachmentBlobsTableAnnotationComposer,
      $$AttachmentBlobsTableCreateCompanionBuilder,
      $$AttachmentBlobsTableUpdateCompanionBuilder,
      (AttachmentBlob, $$AttachmentBlobsTableReferences),
      AttachmentBlob,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$AccountSignaturesTableCreateCompanionBuilder =
    AccountSignaturesCompanion Function({
      required String id,
      required String accountId,
      required String name,
      required String bodyPlain,
      Value<String?> bodyHtml,
      Value<bool> isDefault,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$AccountSignaturesTableUpdateCompanionBuilder =
    AccountSignaturesCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<String> name,
      Value<String> bodyPlain,
      Value<String?> bodyHtml,
      Value<bool> isDefault,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$AccountSignaturesTableReferences
    extends
        BaseReferences<
          _$ByteMailDatabase,
          $AccountSignaturesTable,
          AccountSignature
        > {
  $$AccountSignaturesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AccountsTable _accountIdTable(_$ByteMailDatabase db) =>
      db.accounts.createAlias('account_signatures__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $AccountSignatureAssetsTable,
    List<AccountSignatureAsset>
  >
  _accountSignatureAssetsRefsTable(_$ByteMailDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.accountSignatureAssets,
        aliasName:
            'account_signatures__id__account_signature_assets__signature_id',
      );

  $$AccountSignatureAssetsTableProcessedTableManager
  get accountSignatureAssetsRefs {
    final manager = $$AccountSignatureAssetsTableTableManager(
      $_db,
      $_db.accountSignatureAssets,
    ).filter((f) => f.signatureId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _accountSignatureAssetsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountSignaturesTableFilterComposer
    extends Composer<_$ByteMailDatabase, $AccountSignaturesTable> {
  $$AccountSignaturesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bodyPlain => $composableBuilder(
    column: $table.bodyPlain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bodyHtml => $composableBuilder(
    column: $table.bodyHtml,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> accountSignatureAssetsRefs(
    Expression<bool> Function($$AccountSignatureAssetsTableFilterComposer f) f,
  ) {
    final $$AccountSignatureAssetsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.accountSignatureAssets,
          getReferencedColumn: (t) => t.signatureId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AccountSignatureAssetsTableFilterComposer(
                $db: $db,
                $table: $db.accountSignatureAssets,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AccountSignaturesTableOrderingComposer
    extends Composer<_$ByteMailDatabase, $AccountSignaturesTable> {
  $$AccountSignaturesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bodyPlain => $composableBuilder(
    column: $table.bodyPlain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bodyHtml => $composableBuilder(
    column: $table.bodyHtml,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountSignaturesTableAnnotationComposer
    extends Composer<_$ByteMailDatabase, $AccountSignaturesTable> {
  $$AccountSignaturesTableAnnotationComposer({
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

  GeneratedColumn<String> get bodyPlain =>
      $composableBuilder(column: $table.bodyPlain, builder: (column) => column);

  GeneratedColumn<String> get bodyHtml =>
      $composableBuilder(column: $table.bodyHtml, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> accountSignatureAssetsRefs<T extends Object>(
    Expression<T> Function($$AccountSignatureAssetsTableAnnotationComposer a) f,
  ) {
    final $$AccountSignatureAssetsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.accountSignatureAssets,
          getReferencedColumn: (t) => t.signatureId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AccountSignatureAssetsTableAnnotationComposer(
                $db: $db,
                $table: $db.accountSignatureAssets,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AccountSignaturesTableTableManager
    extends
        RootTableManager<
          _$ByteMailDatabase,
          $AccountSignaturesTable,
          AccountSignature,
          $$AccountSignaturesTableFilterComposer,
          $$AccountSignaturesTableOrderingComposer,
          $$AccountSignaturesTableAnnotationComposer,
          $$AccountSignaturesTableCreateCompanionBuilder,
          $$AccountSignaturesTableUpdateCompanionBuilder,
          (AccountSignature, $$AccountSignaturesTableReferences),
          AccountSignature,
          PrefetchHooks Function({
            bool accountId,
            bool accountSignatureAssetsRefs,
          })
        > {
  $$AccountSignaturesTableTableManager(
    _$ByteMailDatabase db,
    $AccountSignaturesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountSignaturesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountSignaturesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountSignaturesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> bodyPlain = const Value.absent(),
                Value<String?> bodyHtml = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountSignaturesCompanion(
                id: id,
                accountId: accountId,
                name: name,
                bodyPlain: bodyPlain,
                bodyHtml: bodyHtml,
                isDefault: isDefault,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required String name,
                required String bodyPlain,
                Value<String?> bodyHtml = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountSignaturesCompanion.insert(
                id: id,
                accountId: accountId,
                name: name,
                bodyPlain: bodyPlain,
                bodyHtml: bodyHtml,
                isDefault: isDefault,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AccountSignaturesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({accountId = false, accountSignatureAssetsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (accountSignatureAssetsRefs) db.accountSignatureAssets,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (accountId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.accountId,
                                    referencedTable:
                                        $$AccountSignaturesTableReferences
                                            ._accountIdTable(db),
                                    referencedColumn:
                                        $$AccountSignaturesTableReferences
                                            ._accountIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (accountSignatureAssetsRefs)
                        await $_getPrefetchedData<
                          AccountSignature,
                          $AccountSignaturesTable,
                          AccountSignatureAsset
                        >(
                          currentTable: table,
                          referencedTable: $$AccountSignaturesTableReferences
                              ._accountSignatureAssetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountSignaturesTableReferences(
                                db,
                                table,
                                p0,
                              ).accountSignatureAssetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.signatureId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AccountSignaturesTableProcessedTableManager =
    ProcessedTableManager<
      _$ByteMailDatabase,
      $AccountSignaturesTable,
      AccountSignature,
      $$AccountSignaturesTableFilterComposer,
      $$AccountSignaturesTableOrderingComposer,
      $$AccountSignaturesTableAnnotationComposer,
      $$AccountSignaturesTableCreateCompanionBuilder,
      $$AccountSignaturesTableUpdateCompanionBuilder,
      (AccountSignature, $$AccountSignaturesTableReferences),
      AccountSignature,
      PrefetchHooks Function({bool accountId, bool accountSignatureAssetsRefs})
    >;
typedef $$AccountSignatureAssetsTableCreateCompanionBuilder =
    AccountSignatureAssetsCompanion Function({
      required String id,
      required String signatureId,
      required String localPath,
      required String contentId,
      required String mimeType,
      Value<int> rowid,
    });
typedef $$AccountSignatureAssetsTableUpdateCompanionBuilder =
    AccountSignatureAssetsCompanion Function({
      Value<String> id,
      Value<String> signatureId,
      Value<String> localPath,
      Value<String> contentId,
      Value<String> mimeType,
      Value<int> rowid,
    });

final class $$AccountSignatureAssetsTableReferences
    extends
        BaseReferences<
          _$ByteMailDatabase,
          $AccountSignatureAssetsTable,
          AccountSignatureAsset
        > {
  $$AccountSignatureAssetsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AccountSignaturesTable _signatureIdTable(_$ByteMailDatabase db) =>
      db.accountSignatures.createAlias(
        'account_signature_assets__signature_id__account_signatures__id',
      );

  $$AccountSignaturesTableProcessedTableManager get signatureId {
    final $_column = $_itemColumn<String>('signature_id')!;

    final manager = $$AccountSignaturesTableTableManager(
      $_db,
      $_db.accountSignatures,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_signatureIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AccountSignatureAssetsTableFilterComposer
    extends Composer<_$ByteMailDatabase, $AccountSignatureAssetsTable> {
  $$AccountSignatureAssetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentId => $composableBuilder(
    column: $table.contentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountSignaturesTableFilterComposer get signatureId {
    final $$AccountSignaturesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.signatureId,
      referencedTable: $db.accountSignatures,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountSignaturesTableFilterComposer(
            $db: $db,
            $table: $db.accountSignatures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountSignatureAssetsTableOrderingComposer
    extends Composer<_$ByteMailDatabase, $AccountSignatureAssetsTable> {
  $$AccountSignatureAssetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentId => $composableBuilder(
    column: $table.contentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountSignaturesTableOrderingComposer get signatureId {
    final $$AccountSignaturesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.signatureId,
      referencedTable: $db.accountSignatures,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountSignaturesTableOrderingComposer(
            $db: $db,
            $table: $db.accountSignatures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountSignatureAssetsTableAnnotationComposer
    extends Composer<_$ByteMailDatabase, $AccountSignatureAssetsTable> {
  $$AccountSignatureAssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get contentId =>
      $composableBuilder(column: $table.contentId, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  $$AccountSignaturesTableAnnotationComposer get signatureId {
    final $$AccountSignaturesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.signatureId,
          referencedTable: $db.accountSignatures,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AccountSignaturesTableAnnotationComposer(
                $db: $db,
                $table: $db.accountSignatures,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$AccountSignatureAssetsTableTableManager
    extends
        RootTableManager<
          _$ByteMailDatabase,
          $AccountSignatureAssetsTable,
          AccountSignatureAsset,
          $$AccountSignatureAssetsTableFilterComposer,
          $$AccountSignatureAssetsTableOrderingComposer,
          $$AccountSignatureAssetsTableAnnotationComposer,
          $$AccountSignatureAssetsTableCreateCompanionBuilder,
          $$AccountSignatureAssetsTableUpdateCompanionBuilder,
          (AccountSignatureAsset, $$AccountSignatureAssetsTableReferences),
          AccountSignatureAsset,
          PrefetchHooks Function({bool signatureId})
        > {
  $$AccountSignatureAssetsTableTableManager(
    _$ByteMailDatabase db,
    $AccountSignatureAssetsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountSignatureAssetsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AccountSignatureAssetsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AccountSignatureAssetsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> signatureId = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<String> contentId = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountSignatureAssetsCompanion(
                id: id,
                signatureId: signatureId,
                localPath: localPath,
                contentId: contentId,
                mimeType: mimeType,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String signatureId,
                required String localPath,
                required String contentId,
                required String mimeType,
                Value<int> rowid = const Value.absent(),
              }) => AccountSignatureAssetsCompanion.insert(
                id: id,
                signatureId: signatureId,
                localPath: localPath,
                contentId: contentId,
                mimeType: mimeType,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AccountSignatureAssetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({signatureId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (signatureId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.signatureId,
                                referencedTable:
                                    $$AccountSignatureAssetsTableReferences
                                        ._signatureIdTable(db),
                                referencedColumn:
                                    $$AccountSignatureAssetsTableReferences
                                        ._signatureIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AccountSignatureAssetsTableProcessedTableManager =
    ProcessedTableManager<
      _$ByteMailDatabase,
      $AccountSignatureAssetsTable,
      AccountSignatureAsset,
      $$AccountSignatureAssetsTableFilterComposer,
      $$AccountSignatureAssetsTableOrderingComposer,
      $$AccountSignatureAssetsTableAnnotationComposer,
      $$AccountSignatureAssetsTableCreateCompanionBuilder,
      $$AccountSignatureAssetsTableUpdateCompanionBuilder,
      (AccountSignatureAsset, $$AccountSignatureAssetsTableReferences),
      AccountSignatureAsset,
      PrefetchHooks Function({bool signatureId})
    >;
typedef $$MessageTemplatesTableCreateCompanionBuilder =
    MessageTemplatesCompanion Function({
      required String id,
      Value<String?> accountId,
      required String name,
      required String subject,
      required String bodyHtml,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$MessageTemplatesTableUpdateCompanionBuilder =
    MessageTemplatesCompanion Function({
      Value<String> id,
      Value<String?> accountId,
      Value<String> name,
      Value<String> subject,
      Value<String> bodyHtml,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$MessageTemplatesTableReferences
    extends
        BaseReferences<
          _$ByteMailDatabase,
          $MessageTemplatesTable,
          MessageTemplate
        > {
  $$MessageTemplatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AccountsTable _accountIdTable(_$ByteMailDatabase db) =>
      db.accounts.createAlias('message_templates__account_id__accounts__id');

  $$AccountsTableProcessedTableManager? get accountId {
    final $_column = $_itemColumn<String>('account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MessageTemplatesTableFilterComposer
    extends Composer<_$ByteMailDatabase, $MessageTemplatesTable> {
  $$MessageTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bodyHtml => $composableBuilder(
    column: $table.bodyHtml,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessageTemplatesTableOrderingComposer
    extends Composer<_$ByteMailDatabase, $MessageTemplatesTable> {
  $$MessageTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bodyHtml => $composableBuilder(
    column: $table.bodyHtml,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessageTemplatesTableAnnotationComposer
    extends Composer<_$ByteMailDatabase, $MessageTemplatesTable> {
  $$MessageTemplatesTableAnnotationComposer({
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

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get bodyHtml =>
      $composableBuilder(column: $table.bodyHtml, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessageTemplatesTableTableManager
    extends
        RootTableManager<
          _$ByteMailDatabase,
          $MessageTemplatesTable,
          MessageTemplate,
          $$MessageTemplatesTableFilterComposer,
          $$MessageTemplatesTableOrderingComposer,
          $$MessageTemplatesTableAnnotationComposer,
          $$MessageTemplatesTableCreateCompanionBuilder,
          $$MessageTemplatesTableUpdateCompanionBuilder,
          (MessageTemplate, $$MessageTemplatesTableReferences),
          MessageTemplate,
          PrefetchHooks Function({bool accountId})
        > {
  $$MessageTemplatesTableTableManager(
    _$ByteMailDatabase db,
    $MessageTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessageTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessageTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessageTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> bodyHtml = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessageTemplatesCompanion(
                id: id,
                accountId: accountId,
                name: name,
                subject: subject,
                bodyHtml: bodyHtml,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> accountId = const Value.absent(),
                required String name,
                required String subject,
                required String bodyHtml,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessageTemplatesCompanion.insert(
                id: id,
                accountId: accountId,
                name: name,
                subject: subject,
                bodyHtml: bodyHtml,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MessageTemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable:
                                    $$MessageTemplatesTableReferences
                                        ._accountIdTable(db),
                                referencedColumn:
                                    $$MessageTemplatesTableReferences
                                        ._accountIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MessageTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$ByteMailDatabase,
      $MessageTemplatesTable,
      MessageTemplate,
      $$MessageTemplatesTableFilterComposer,
      $$MessageTemplatesTableOrderingComposer,
      $$MessageTemplatesTableAnnotationComposer,
      $$MessageTemplatesTableCreateCompanionBuilder,
      $$MessageTemplatesTableUpdateCompanionBuilder,
      (MessageTemplate, $$MessageTemplatesTableReferences),
      MessageTemplate,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$CustomThemesTableCreateCompanionBuilder =
    CustomThemesCompanion Function({
      required String id,
      required String name,
      required String baseThemeId,
      required String tokenOverridesJson,
      Value<int> rowid,
    });
typedef $$CustomThemesTableUpdateCompanionBuilder =
    CustomThemesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> baseThemeId,
      Value<String> tokenOverridesJson,
      Value<int> rowid,
    });

class $$CustomThemesTableFilterComposer
    extends Composer<_$ByteMailDatabase, $CustomThemesTable> {
  $$CustomThemesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseThemeId => $composableBuilder(
    column: $table.baseThemeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tokenOverridesJson => $composableBuilder(
    column: $table.tokenOverridesJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomThemesTableOrderingComposer
    extends Composer<_$ByteMailDatabase, $CustomThemesTable> {
  $$CustomThemesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseThemeId => $composableBuilder(
    column: $table.baseThemeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tokenOverridesJson => $composableBuilder(
    column: $table.tokenOverridesJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomThemesTableAnnotationComposer
    extends Composer<_$ByteMailDatabase, $CustomThemesTable> {
  $$CustomThemesTableAnnotationComposer({
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

  GeneratedColumn<String> get baseThemeId => $composableBuilder(
    column: $table.baseThemeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tokenOverridesJson => $composableBuilder(
    column: $table.tokenOverridesJson,
    builder: (column) => column,
  );
}

class $$CustomThemesTableTableManager
    extends
        RootTableManager<
          _$ByteMailDatabase,
          $CustomThemesTable,
          CustomTheme,
          $$CustomThemesTableFilterComposer,
          $$CustomThemesTableOrderingComposer,
          $$CustomThemesTableAnnotationComposer,
          $$CustomThemesTableCreateCompanionBuilder,
          $$CustomThemesTableUpdateCompanionBuilder,
          (
            CustomTheme,
            BaseReferences<_$ByteMailDatabase, $CustomThemesTable, CustomTheme>,
          ),
          CustomTheme,
          PrefetchHooks Function()
        > {
  $$CustomThemesTableTableManager(
    _$ByteMailDatabase db,
    $CustomThemesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomThemesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomThemesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomThemesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> baseThemeId = const Value.absent(),
                Value<String> tokenOverridesJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomThemesCompanion(
                id: id,
                name: name,
                baseThemeId: baseThemeId,
                tokenOverridesJson: tokenOverridesJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String baseThemeId,
                required String tokenOverridesJson,
                Value<int> rowid = const Value.absent(),
              }) => CustomThemesCompanion.insert(
                id: id,
                name: name,
                baseThemeId: baseThemeId,
                tokenOverridesJson: tokenOverridesJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomThemesTableProcessedTableManager =
    ProcessedTableManager<
      _$ByteMailDatabase,
      $CustomThemesTable,
      CustomTheme,
      $$CustomThemesTableFilterComposer,
      $$CustomThemesTableOrderingComposer,
      $$CustomThemesTableAnnotationComposer,
      $$CustomThemesTableCreateCompanionBuilder,
      $$CustomThemesTableUpdateCompanionBuilder,
      (
        CustomTheme,
        BaseReferences<_$ByteMailDatabase, $CustomThemesTable, CustomTheme>,
      ),
      CustomTheme,
      PrefetchHooks Function()
    >;

class $ByteMailDatabaseManager {
  final _$ByteMailDatabase _db;
  $ByteMailDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db, _db.folders);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$FocusRulesTableTableManager get focusRules =>
      $$FocusRulesTableTableManager(_db, _db.focusRules);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
  $$JobsTableTableManager get jobs => $$JobsTableTableManager(_db, _db.jobs);
  $$SyncCursorsTableTableManager get syncCursors =>
      $$SyncCursorsTableTableManager(_db, _db.syncCursors);
  $$WidgetSnapshotsTableTableManager get widgetSnapshots =>
      $$WidgetSnapshotsTableTableManager(_db, _db.widgetSnapshots);
  $$SyncProfilesTableTableManager get syncProfiles =>
      $$SyncProfilesTableTableManager(_db, _db.syncProfiles);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
  $$AttachmentBlobsTableTableManager get attachmentBlobs =>
      $$AttachmentBlobsTableTableManager(_db, _db.attachmentBlobs);
  $$AccountSignaturesTableTableManager get accountSignatures =>
      $$AccountSignaturesTableTableManager(_db, _db.accountSignatures);
  $$AccountSignatureAssetsTableTableManager get accountSignatureAssets =>
      $$AccountSignatureAssetsTableTableManager(
        _db,
        _db.accountSignatureAssets,
      );
  $$MessageTemplatesTableTableManager get messageTemplates =>
      $$MessageTemplatesTableTableManager(_db, _db.messageTemplates);
  $$CustomThemesTableTableManager get customThemes =>
      $$CustomThemesTableTableManager(_db, _db.customThemes);
}
