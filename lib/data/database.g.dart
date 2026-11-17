// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DocumentsTable extends Documents
    with TableInfo<$DocumentsTable, Document> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DocumentType, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DocumentType>($DocumentsTable.$convertertype);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _holderMeta = const VerificationMeta('holder');
  @override
  late final GeneratedColumn<String> holder = GeneratedColumn<String>(
    'holder',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _documentNumberMeta = const VerificationMeta(
    'documentNumber',
  );
  @override
  late final GeneratedColumn<String> documentNumber = GeneratedColumn<String>(
    'document_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _issuingCountryMeta = const VerificationMeta(
    'issuingCountry',
  );
  @override
  late final GeneratedColumn<String> issuingCountry = GeneratedColumn<String>(
    'issuing_country',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _issueDateMeta = const VerificationMeta(
    'issueDate',
  );
  @override
  late final GeneratedColumn<DateTime> issueDate = GeneratedColumn<DateTime>(
    'issue_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expiryDateMeta = const VerificationMeta(
    'expiryDate',
  );
  @override
  late final GeneratedColumn<DateTime> expiryDate = GeneratedColumn<DateTime>(
    'expiry_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _renewalLeadDaysMeta = const VerificationMeta(
    'renewalLeadDays',
  );
  @override
  late final GeneratedColumn<int> renewalLeadDays = GeneratedColumn<int>(
    'renewal_lead_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageCountMeta = const VerificationMeta(
    'imageCount',
  );
  @override
  late final GeneratedColumn<int> imageCount = GeneratedColumn<int>(
    'image_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _detailsMeta = const VerificationMeta(
    'details',
  );
  @override
  late final GeneratedColumn<String> details = GeneratedColumn<String>(
    'details',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeNameMeta = const VerificationMeta(
    'typeName',
  );
  @override
  late final GeneratedColumn<String> typeName = GeneratedColumn<String>(
    'type_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scanTextMeta = const VerificationMeta(
    'scanText',
  );
  @override
  late final GeneratedColumn<String> scanText = GeneratedColumn<String>(
    'scan_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _neverExpiresMeta = const VerificationMeta(
    'neverExpires',
  );
  @override
  late final GeneratedColumn<bool> neverExpires = GeneratedColumn<bool>(
    'never_expires',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("never_expires" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _extrasMeta = const VerificationMeta('extras');
  @override
  late final GeneratedColumn<String> extras = GeneratedColumn<String>(
    'extras',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderOffsetsMeta = const VerificationMeta(
    'reminderOffsets',
  );
  @override
  late final GeneratedColumn<String> reminderOffsets = GeneratedColumn<String>(
    'reminder_offsets',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attachmentsMeta = const VerificationMeta(
    'attachments',
  );
  @override
  late final GeneratedColumn<String> attachments = GeneratedColumn<String>(
    'attachments',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    label,
    holder,
    documentNumber,
    issuingCountry,
    issueDate,
    expiryDate,
    renewalLeadDays,
    imagePath,
    imageCount,
    details,
    typeName,
    scanText,
    neverExpires,
    extras,
    reminderOffsets,
    attachments,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<Document> instance, {
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
    if (data.containsKey('holder')) {
      context.handle(
        _holderMeta,
        holder.isAcceptableOrUnknown(data['holder']!, _holderMeta),
      );
    }
    if (data.containsKey('document_number')) {
      context.handle(
        _documentNumberMeta,
        documentNumber.isAcceptableOrUnknown(
          data['document_number']!,
          _documentNumberMeta,
        ),
      );
    }
    if (data.containsKey('issuing_country')) {
      context.handle(
        _issuingCountryMeta,
        issuingCountry.isAcceptableOrUnknown(
          data['issuing_country']!,
          _issuingCountryMeta,
        ),
      );
    }
    if (data.containsKey('issue_date')) {
      context.handle(
        _issueDateMeta,
        issueDate.isAcceptableOrUnknown(data['issue_date']!, _issueDateMeta),
      );
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
        _expiryDateMeta,
        expiryDate.isAcceptableOrUnknown(data['expiry_date']!, _expiryDateMeta),
      );
    } else if (isInserting) {
      context.missing(_expiryDateMeta);
    }
    if (data.containsKey('renewal_lead_days')) {
      context.handle(
        _renewalLeadDaysMeta,
        renewalLeadDays.isAcceptableOrUnknown(
          data['renewal_lead_days']!,
          _renewalLeadDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_renewalLeadDaysMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('image_count')) {
      context.handle(
        _imageCountMeta,
        imageCount.isAcceptableOrUnknown(data['image_count']!, _imageCountMeta),
      );
    }
    if (data.containsKey('details')) {
      context.handle(
        _detailsMeta,
        details.isAcceptableOrUnknown(data['details']!, _detailsMeta),
      );
    }
    if (data.containsKey('type_name')) {
      context.handle(
        _typeNameMeta,
        typeName.isAcceptableOrUnknown(data['type_name']!, _typeNameMeta),
      );
    }
    if (data.containsKey('scan_text')) {
      context.handle(
        _scanTextMeta,
        scanText.isAcceptableOrUnknown(data['scan_text']!, _scanTextMeta),
      );
    }
    if (data.containsKey('never_expires')) {
      context.handle(
        _neverExpiresMeta,
        neverExpires.isAcceptableOrUnknown(
          data['never_expires']!,
          _neverExpiresMeta,
        ),
      );
    }
    if (data.containsKey('extras')) {
      context.handle(
        _extrasMeta,
        extras.isAcceptableOrUnknown(data['extras']!, _extrasMeta),
      );
    }
    if (data.containsKey('reminder_offsets')) {
      context.handle(
        _reminderOffsetsMeta,
        reminderOffsets.isAcceptableOrUnknown(
          data['reminder_offsets']!,
          _reminderOffsetsMeta,
        ),
      );
    }
    if (data.containsKey('attachments')) {
      context.handle(
        _attachmentsMeta,
        attachments.isAcceptableOrUnknown(
          data['attachments']!,
          _attachmentsMeta,
        ),
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
  Document map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Document(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: $DocumentsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      holder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}holder'],
      ),
      documentNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_number'],
      ),
      issuingCountry: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issuing_country'],
      ),
      issueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}issue_date'],
      ),
      expiryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expiry_date'],
      )!,
      renewalLeadDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}renewal_lead_days'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      imageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}image_count'],
      )!,
      details: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}details'],
      ),
      typeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type_name'],
      ),
      scanText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scan_text'],
      ),
      neverExpires: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}never_expires'],
      )!,
      extras: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extras'],
      ),
      reminderOffsets: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_offsets'],
      ),
      attachments: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachments'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DocumentsTable createAlias(String alias) {
    return $DocumentsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DocumentType, int, int> $convertertype =
      const EnumIndexConverter<DocumentType>(DocumentType.values);
}

class Document extends DataClass implements Insertable<Document> {
  final String id;
  final DocumentType type;
  final String label;
  final String? holder;
  final String? documentNumber;
  final String? issuingCountry;
  final DateTime? issueDate;
  final DateTime expiryDate;
  final int renewalLeadDays;
  final String? imagePath;

  /// How many pictures this document has. A card has two sides and some
  /// documents several pages, so one record owns an ordered set of images
  /// rather than a single face.
  final int imageCount;

  /// Type-specific fields, as JSON.
  ///
  /// A column each would mean a migration every time a document type gains a
  /// field, and a table full of nulls — a bank card has no plate number and a
  /// passport has no security code.
  final String? details;

  /// A name the user invented for this kind of document, if they did.
  ///
  /// Not called customType: Drift's own Table already has a member by that
  /// name, and a column that shadows the base class compiles into nonsense.
  final String? typeName;

  /// What the recogniser read, kept with the document it was read from.
  final String? scanText;

  /// True when the document says it never expires.
  ///
  /// A Chinese identity card issued to someone over 46 reads 2015.01.01-长期,
  /// and a great many memberships and licences simply have no end. The expiry
  /// column keeps whatever date it had, because a column that must hold
  /// something should hold something; nothing reads it while this is set.
  final bool neverExpires;

  /// Fields the user added themselves, as JSON.
  ///
  /// Separate from [details], which is a fixed set this app understands and
  /// reasons about. These are names only the user knows the meaning of, so
  /// they are stored and shown back and nothing more is claimed about them.
  final String? extras;

  /// The reminder times the user chose, in days before expiry, comma
  /// separated. Null means they never chose and the conventional set applies.
  final String? reminderOffsets;

  /// Files and links kept with the document, as JSON. The files' bytes live
  /// encrypted on disk beside the photos; this holds only what describes them.
  final String? attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Document({
    required this.id,
    required this.type,
    required this.label,
    this.holder,
    this.documentNumber,
    this.issuingCountry,
    this.issueDate,
    required this.expiryDate,
    required this.renewalLeadDays,
    this.imagePath,
    required this.imageCount,
    this.details,
    this.typeName,
    this.scanText,
    required this.neverExpires,
    this.extras,
    this.reminderOffsets,
    this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['type'] = Variable<int>($DocumentsTable.$convertertype.toSql(type));
    }
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || holder != null) {
      map['holder'] = Variable<String>(holder);
    }
    if (!nullToAbsent || documentNumber != null) {
      map['document_number'] = Variable<String>(documentNumber);
    }
    if (!nullToAbsent || issuingCountry != null) {
      map['issuing_country'] = Variable<String>(issuingCountry);
    }
    if (!nullToAbsent || issueDate != null) {
      map['issue_date'] = Variable<DateTime>(issueDate);
    }
    map['expiry_date'] = Variable<DateTime>(expiryDate);
    map['renewal_lead_days'] = Variable<int>(renewalLeadDays);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['image_count'] = Variable<int>(imageCount);
    if (!nullToAbsent || details != null) {
      map['details'] = Variable<String>(details);
    }
    if (!nullToAbsent || typeName != null) {
      map['type_name'] = Variable<String>(typeName);
    }
    if (!nullToAbsent || scanText != null) {
      map['scan_text'] = Variable<String>(scanText);
    }
    map['never_expires'] = Variable<bool>(neverExpires);
    if (!nullToAbsent || extras != null) {
      map['extras'] = Variable<String>(extras);
    }
    if (!nullToAbsent || reminderOffsets != null) {
      map['reminder_offsets'] = Variable<String>(reminderOffsets);
    }
    if (!nullToAbsent || attachments != null) {
      map['attachments'] = Variable<String>(attachments);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DocumentsCompanion toCompanion(bool nullToAbsent) {
    return DocumentsCompanion(
      id: Value(id),
      type: Value(type),
      label: Value(label),
      holder: holder == null && nullToAbsent
          ? const Value.absent()
          : Value(holder),
      documentNumber: documentNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(documentNumber),
      issuingCountry: issuingCountry == null && nullToAbsent
          ? const Value.absent()
          : Value(issuingCountry),
      issueDate: issueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(issueDate),
      expiryDate: Value(expiryDate),
      renewalLeadDays: Value(renewalLeadDays),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      imageCount: Value(imageCount),
      details: details == null && nullToAbsent
          ? const Value.absent()
          : Value(details),
      typeName: typeName == null && nullToAbsent
          ? const Value.absent()
          : Value(typeName),
      scanText: scanText == null && nullToAbsent
          ? const Value.absent()
          : Value(scanText),
      neverExpires: Value(neverExpires),
      extras: extras == null && nullToAbsent
          ? const Value.absent()
          : Value(extras),
      reminderOffsets: reminderOffsets == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderOffsets),
      attachments: attachments == null && nullToAbsent
          ? const Value.absent()
          : Value(attachments),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Document.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Document(
      id: serializer.fromJson<String>(json['id']),
      type: $DocumentsTable.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
      label: serializer.fromJson<String>(json['label']),
      holder: serializer.fromJson<String?>(json['holder']),
      documentNumber: serializer.fromJson<String?>(json['documentNumber']),
      issuingCountry: serializer.fromJson<String?>(json['issuingCountry']),
      issueDate: serializer.fromJson<DateTime?>(json['issueDate']),
      expiryDate: serializer.fromJson<DateTime>(json['expiryDate']),
      renewalLeadDays: serializer.fromJson<int>(json['renewalLeadDays']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      imageCount: serializer.fromJson<int>(json['imageCount']),
      details: serializer.fromJson<String?>(json['details']),
      typeName: serializer.fromJson<String?>(json['typeName']),
      scanText: serializer.fromJson<String?>(json['scanText']),
      neverExpires: serializer.fromJson<bool>(json['neverExpires']),
      extras: serializer.fromJson<String?>(json['extras']),
      reminderOffsets: serializer.fromJson<String?>(json['reminderOffsets']),
      attachments: serializer.fromJson<String?>(json['attachments']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<int>(
        $DocumentsTable.$convertertype.toJson(type),
      ),
      'label': serializer.toJson<String>(label),
      'holder': serializer.toJson<String?>(holder),
      'documentNumber': serializer.toJson<String?>(documentNumber),
      'issuingCountry': serializer.toJson<String?>(issuingCountry),
      'issueDate': serializer.toJson<DateTime?>(issueDate),
      'expiryDate': serializer.toJson<DateTime>(expiryDate),
      'renewalLeadDays': serializer.toJson<int>(renewalLeadDays),
      'imagePath': serializer.toJson<String?>(imagePath),
      'imageCount': serializer.toJson<int>(imageCount),
      'details': serializer.toJson<String?>(details),
      'typeName': serializer.toJson<String?>(typeName),
      'scanText': serializer.toJson<String?>(scanText),
      'neverExpires': serializer.toJson<bool>(neverExpires),
      'extras': serializer.toJson<String?>(extras),
      'reminderOffsets': serializer.toJson<String?>(reminderOffsets),
      'attachments': serializer.toJson<String?>(attachments),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Document copyWith({
    String? id,
    DocumentType? type,
    String? label,
    Value<String?> holder = const Value.absent(),
    Value<String?> documentNumber = const Value.absent(),
    Value<String?> issuingCountry = const Value.absent(),
    Value<DateTime?> issueDate = const Value.absent(),
    DateTime? expiryDate,
    int? renewalLeadDays,
    Value<String?> imagePath = const Value.absent(),
    int? imageCount,
    Value<String?> details = const Value.absent(),
    Value<String?> typeName = const Value.absent(),
    Value<String?> scanText = const Value.absent(),
    bool? neverExpires,
    Value<String?> extras = const Value.absent(),
    Value<String?> reminderOffsets = const Value.absent(),
    Value<String?> attachments = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Document(
    id: id ?? this.id,
    type: type ?? this.type,
    label: label ?? this.label,
    holder: holder.present ? holder.value : this.holder,
    documentNumber: documentNumber.present
        ? documentNumber.value
        : this.documentNumber,
    issuingCountry: issuingCountry.present
        ? issuingCountry.value
        : this.issuingCountry,
    issueDate: issueDate.present ? issueDate.value : this.issueDate,
    expiryDate: expiryDate ?? this.expiryDate,
    renewalLeadDays: renewalLeadDays ?? this.renewalLeadDays,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    imageCount: imageCount ?? this.imageCount,
    details: details.present ? details.value : this.details,
    typeName: typeName.present ? typeName.value : this.typeName,
    scanText: scanText.present ? scanText.value : this.scanText,
    neverExpires: neverExpires ?? this.neverExpires,
    extras: extras.present ? extras.value : this.extras,
    reminderOffsets: reminderOffsets.present
        ? reminderOffsets.value
        : this.reminderOffsets,
    attachments: attachments.present ? attachments.value : this.attachments,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Document copyWithCompanion(DocumentsCompanion data) {
    return Document(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      label: data.label.present ? data.label.value : this.label,
      holder: data.holder.present ? data.holder.value : this.holder,
      documentNumber: data.documentNumber.present
          ? data.documentNumber.value
          : this.documentNumber,
      issuingCountry: data.issuingCountry.present
          ? data.issuingCountry.value
          : this.issuingCountry,
      issueDate: data.issueDate.present ? data.issueDate.value : this.issueDate,
      expiryDate: data.expiryDate.present
          ? data.expiryDate.value
          : this.expiryDate,
      renewalLeadDays: data.renewalLeadDays.present
          ? data.renewalLeadDays.value
          : this.renewalLeadDays,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      imageCount: data.imageCount.present
          ? data.imageCount.value
          : this.imageCount,
      details: data.details.present ? data.details.value : this.details,
      typeName: data.typeName.present ? data.typeName.value : this.typeName,
      scanText: data.scanText.present ? data.scanText.value : this.scanText,
      neverExpires: data.neverExpires.present
          ? data.neverExpires.value
          : this.neverExpires,
      extras: data.extras.present ? data.extras.value : this.extras,
      reminderOffsets: data.reminderOffsets.present
          ? data.reminderOffsets.value
          : this.reminderOffsets,
      attachments: data.attachments.present
          ? data.attachments.value
          : this.attachments,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Document(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('label: $label, ')
          ..write('holder: $holder, ')
          ..write('documentNumber: $documentNumber, ')
          ..write('issuingCountry: $issuingCountry, ')
          ..write('issueDate: $issueDate, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('renewalLeadDays: $renewalLeadDays, ')
          ..write('imagePath: $imagePath, ')
          ..write('imageCount: $imageCount, ')
          ..write('details: $details, ')
          ..write('typeName: $typeName, ')
          ..write('scanText: $scanText, ')
          ..write('neverExpires: $neverExpires, ')
          ..write('extras: $extras, ')
          ..write('reminderOffsets: $reminderOffsets, ')
          ..write('attachments: $attachments, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    label,
    holder,
    documentNumber,
    issuingCountry,
    issueDate,
    expiryDate,
    renewalLeadDays,
    imagePath,
    imageCount,
    details,
    typeName,
    scanText,
    neverExpires,
    extras,
    reminderOffsets,
    attachments,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Document &&
          other.id == this.id &&
          other.type == this.type &&
          other.label == this.label &&
          other.holder == this.holder &&
          other.documentNumber == this.documentNumber &&
          other.issuingCountry == this.issuingCountry &&
          other.issueDate == this.issueDate &&
          other.expiryDate == this.expiryDate &&
          other.renewalLeadDays == this.renewalLeadDays &&
          other.imagePath == this.imagePath &&
          other.imageCount == this.imageCount &&
          other.details == this.details &&
          other.typeName == this.typeName &&
          other.scanText == this.scanText &&
          other.neverExpires == this.neverExpires &&
          other.extras == this.extras &&
          other.reminderOffsets == this.reminderOffsets &&
          other.attachments == this.attachments &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DocumentsCompanion extends UpdateCompanion<Document> {
  final Value<String> id;
  final Value<DocumentType> type;
  final Value<String> label;
  final Value<String?> holder;
  final Value<String?> documentNumber;
  final Value<String?> issuingCountry;
  final Value<DateTime?> issueDate;
  final Value<DateTime> expiryDate;
  final Value<int> renewalLeadDays;
  final Value<String?> imagePath;
  final Value<int> imageCount;
  final Value<String?> details;
  final Value<String?> typeName;
  final Value<String?> scanText;
  final Value<bool> neverExpires;
  final Value<String?> extras;
  final Value<String?> reminderOffsets;
  final Value<String?> attachments;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DocumentsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.label = const Value.absent(),
    this.holder = const Value.absent(),
    this.documentNumber = const Value.absent(),
    this.issuingCountry = const Value.absent(),
    this.issueDate = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.renewalLeadDays = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.imageCount = const Value.absent(),
    this.details = const Value.absent(),
    this.typeName = const Value.absent(),
    this.scanText = const Value.absent(),
    this.neverExpires = const Value.absent(),
    this.extras = const Value.absent(),
    this.reminderOffsets = const Value.absent(),
    this.attachments = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentsCompanion.insert({
    required String id,
    required DocumentType type,
    required String label,
    this.holder = const Value.absent(),
    this.documentNumber = const Value.absent(),
    this.issuingCountry = const Value.absent(),
    this.issueDate = const Value.absent(),
    required DateTime expiryDate,
    required int renewalLeadDays,
    this.imagePath = const Value.absent(),
    this.imageCount = const Value.absent(),
    this.details = const Value.absent(),
    this.typeName = const Value.absent(),
    this.scanText = const Value.absent(),
    this.neverExpires = const Value.absent(),
    this.extras = const Value.absent(),
    this.reminderOffsets = const Value.absent(),
    this.attachments = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       label = Value(label),
       expiryDate = Value(expiryDate),
       renewalLeadDays = Value(renewalLeadDays),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Document> custom({
    Expression<String>? id,
    Expression<int>? type,
    Expression<String>? label,
    Expression<String>? holder,
    Expression<String>? documentNumber,
    Expression<String>? issuingCountry,
    Expression<DateTime>? issueDate,
    Expression<DateTime>? expiryDate,
    Expression<int>? renewalLeadDays,
    Expression<String>? imagePath,
    Expression<int>? imageCount,
    Expression<String>? details,
    Expression<String>? typeName,
    Expression<String>? scanText,
    Expression<bool>? neverExpires,
    Expression<String>? extras,
    Expression<String>? reminderOffsets,
    Expression<String>? attachments,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (label != null) 'label': label,
      if (holder != null) 'holder': holder,
      if (documentNumber != null) 'document_number': documentNumber,
      if (issuingCountry != null) 'issuing_country': issuingCountry,
      if (issueDate != null) 'issue_date': issueDate,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (renewalLeadDays != null) 'renewal_lead_days': renewalLeadDays,
      if (imagePath != null) 'image_path': imagePath,
      if (imageCount != null) 'image_count': imageCount,
      if (details != null) 'details': details,
      if (typeName != null) 'type_name': typeName,
      if (scanText != null) 'scan_text': scanText,
      if (neverExpires != null) 'never_expires': neverExpires,
      if (extras != null) 'extras': extras,
      if (reminderOffsets != null) 'reminder_offsets': reminderOffsets,
      if (attachments != null) 'attachments': attachments,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentsCompanion copyWith({
    Value<String>? id,
    Value<DocumentType>? type,
    Value<String>? label,
    Value<String?>? holder,
    Value<String?>? documentNumber,
    Value<String?>? issuingCountry,
    Value<DateTime?>? issueDate,
    Value<DateTime>? expiryDate,
    Value<int>? renewalLeadDays,
    Value<String?>? imagePath,
    Value<int>? imageCount,
    Value<String?>? details,
    Value<String?>? typeName,
    Value<String?>? scanText,
    Value<bool>? neverExpires,
    Value<String?>? extras,
    Value<String?>? reminderOffsets,
    Value<String?>? attachments,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DocumentsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      holder: holder ?? this.holder,
      documentNumber: documentNumber ?? this.documentNumber,
      issuingCountry: issuingCountry ?? this.issuingCountry,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      renewalLeadDays: renewalLeadDays ?? this.renewalLeadDays,
      imagePath: imagePath ?? this.imagePath,
      imageCount: imageCount ?? this.imageCount,
      details: details ?? this.details,
      typeName: typeName ?? this.typeName,
      scanText: scanText ?? this.scanText,
      neverExpires: neverExpires ?? this.neverExpires,
      extras: extras ?? this.extras,
      reminderOffsets: reminderOffsets ?? this.reminderOffsets,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
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
    if (type.present) {
      map['type'] = Variable<int>(
        $DocumentsTable.$convertertype.toSql(type.value),
      );
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (holder.present) {
      map['holder'] = Variable<String>(holder.value);
    }
    if (documentNumber.present) {
      map['document_number'] = Variable<String>(documentNumber.value);
    }
    if (issuingCountry.present) {
      map['issuing_country'] = Variable<String>(issuingCountry.value);
    }
    if (issueDate.present) {
      map['issue_date'] = Variable<DateTime>(issueDate.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<DateTime>(expiryDate.value);
    }
    if (renewalLeadDays.present) {
      map['renewal_lead_days'] = Variable<int>(renewalLeadDays.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (imageCount.present) {
      map['image_count'] = Variable<int>(imageCount.value);
    }
    if (details.present) {
      map['details'] = Variable<String>(details.value);
    }
    if (typeName.present) {
      map['type_name'] = Variable<String>(typeName.value);
    }
    if (scanText.present) {
      map['scan_text'] = Variable<String>(scanText.value);
    }
    if (neverExpires.present) {
      map['never_expires'] = Variable<bool>(neverExpires.value);
    }
    if (extras.present) {
      map['extras'] = Variable<String>(extras.value);
    }
    if (reminderOffsets.present) {
      map['reminder_offsets'] = Variable<String>(reminderOffsets.value);
    }
    if (attachments.present) {
      map['attachments'] = Variable<String>(attachments.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('label: $label, ')
          ..write('holder: $holder, ')
          ..write('documentNumber: $documentNumber, ')
          ..write('issuingCountry: $issuingCountry, ')
          ..write('issueDate: $issueDate, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('renewalLeadDays: $renewalLeadDays, ')
          ..write('imagePath: $imagePath, ')
          ..write('imageCount: $imageCount, ')
          ..write('details: $details, ')
          ..write('typeName: $typeName, ')
          ..write('scanText: $scanText, ')
          ..write('neverExpires: $neverExpires, ')
          ..write('extras: $extras, ')
          ..write('reminderOffsets: $reminderOffsets, ')
          ..write('attachments: $attachments, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DocumentsTable documents = $DocumentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [documents];
}

typedef $$DocumentsTableCreateCompanionBuilder =
    DocumentsCompanion Function({
      required String id,
      required DocumentType type,
      required String label,
      Value<String?> holder,
      Value<String?> documentNumber,
      Value<String?> issuingCountry,
      Value<DateTime?> issueDate,
      required DateTime expiryDate,
      required int renewalLeadDays,
      Value<String?> imagePath,
      Value<int> imageCount,
      Value<String?> details,
      Value<String?> typeName,
      Value<String?> scanText,
      Value<bool> neverExpires,
      Value<String?> extras,
      Value<String?> reminderOffsets,
      Value<String?> attachments,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DocumentsTableUpdateCompanionBuilder =
    DocumentsCompanion Function({
      Value<String> id,
      Value<DocumentType> type,
      Value<String> label,
      Value<String?> holder,
      Value<String?> documentNumber,
      Value<String?> issuingCountry,
      Value<DateTime?> issueDate,
      Value<DateTime> expiryDate,
      Value<int> renewalLeadDays,
      Value<String?> imagePath,
      Value<int> imageCount,
      Value<String?> details,
      Value<String?> typeName,
      Value<String?> scanText,
      Value<bool> neverExpires,
      Value<String?> extras,
      Value<String?> reminderOffsets,
      Value<String?> attachments,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$DocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<DocumentType, DocumentType, int> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get holder => $composableBuilder(
    column: $table.holder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentNumber => $composableBuilder(
    column: $table.documentNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issuingCountry => $composableBuilder(
    column: $table.issuingCountry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get issueDate => $composableBuilder(
    column: $table.issueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get renewalLeadDays => $composableBuilder(
    column: $table.renewalLeadDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get imageCount => $composableBuilder(
    column: $table.imageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get typeName => $composableBuilder(
    column: $table.typeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scanText => $composableBuilder(
    column: $table.scanText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get neverExpires => $composableBuilder(
    column: $table.neverExpires,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extras => $composableBuilder(
    column: $table.extras,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderOffsets => $composableBuilder(
    column: $table.reminderOffsets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachments => $composableBuilder(
    column: $table.attachments,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableOrderingComposer({
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

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get holder => $composableBuilder(
    column: $table.holder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentNumber => $composableBuilder(
    column: $table.documentNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issuingCountry => $composableBuilder(
    column: $table.issuingCountry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get issueDate => $composableBuilder(
    column: $table.issueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get renewalLeadDays => $composableBuilder(
    column: $table.renewalLeadDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get imageCount => $composableBuilder(
    column: $table.imageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get typeName => $composableBuilder(
    column: $table.typeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scanText => $composableBuilder(
    column: $table.scanText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get neverExpires => $composableBuilder(
    column: $table.neverExpires,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extras => $composableBuilder(
    column: $table.extras,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderOffsets => $composableBuilder(
    column: $table.reminderOffsets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachments => $composableBuilder(
    column: $table.attachments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DocumentType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get holder =>
      $composableBuilder(column: $table.holder, builder: (column) => column);

  GeneratedColumn<String> get documentNumber => $composableBuilder(
    column: $table.documentNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get issuingCountry => $composableBuilder(
    column: $table.issuingCountry,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get issueDate =>
      $composableBuilder(column: $table.issueDate, builder: (column) => column);

  GeneratedColumn<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get renewalLeadDays => $composableBuilder(
    column: $table.renewalLeadDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<int> get imageCount => $composableBuilder(
    column: $table.imageCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get details =>
      $composableBuilder(column: $table.details, builder: (column) => column);

  GeneratedColumn<String> get typeName =>
      $composableBuilder(column: $table.typeName, builder: (column) => column);

  GeneratedColumn<String> get scanText =>
      $composableBuilder(column: $table.scanText, builder: (column) => column);

  GeneratedColumn<bool> get neverExpires => $composableBuilder(
    column: $table.neverExpires,
    builder: (column) => column,
  );

  GeneratedColumn<String> get extras =>
      $composableBuilder(column: $table.extras, builder: (column) => column);

  GeneratedColumn<String> get reminderOffsets => $composableBuilder(
    column: $table.reminderOffsets,
    builder: (column) => column,
  );

  GeneratedColumn<String> get attachments => $composableBuilder(
    column: $table.attachments,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocumentsTable,
          Document,
          $$DocumentsTableFilterComposer,
          $$DocumentsTableOrderingComposer,
          $$DocumentsTableAnnotationComposer,
          $$DocumentsTableCreateCompanionBuilder,
          $$DocumentsTableUpdateCompanionBuilder,
          (Document, BaseReferences<_$AppDatabase, $DocumentsTable, Document>),
          Document,
          PrefetchHooks Function()
        > {
  $$DocumentsTableTableManager(_$AppDatabase db, $DocumentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DocumentType> type = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String?> holder = const Value.absent(),
                Value<String?> documentNumber = const Value.absent(),
                Value<String?> issuingCountry = const Value.absent(),
                Value<DateTime?> issueDate = const Value.absent(),
                Value<DateTime> expiryDate = const Value.absent(),
                Value<int> renewalLeadDays = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<int> imageCount = const Value.absent(),
                Value<String?> details = const Value.absent(),
                Value<String?> typeName = const Value.absent(),
                Value<String?> scanText = const Value.absent(),
                Value<bool> neverExpires = const Value.absent(),
                Value<String?> extras = const Value.absent(),
                Value<String?> reminderOffsets = const Value.absent(),
                Value<String?> attachments = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion(
                id: id,
                type: type,
                label: label,
                holder: holder,
                documentNumber: documentNumber,
                issuingCountry: issuingCountry,
                issueDate: issueDate,
                expiryDate: expiryDate,
                renewalLeadDays: renewalLeadDays,
                imagePath: imagePath,
                imageCount: imageCount,
                details: details,
                typeName: typeName,
                scanText: scanText,
                neverExpires: neverExpires,
                extras: extras,
                reminderOffsets: reminderOffsets,
                attachments: attachments,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DocumentType type,
                required String label,
                Value<String?> holder = const Value.absent(),
                Value<String?> documentNumber = const Value.absent(),
                Value<String?> issuingCountry = const Value.absent(),
                Value<DateTime?> issueDate = const Value.absent(),
                required DateTime expiryDate,
                required int renewalLeadDays,
                Value<String?> imagePath = const Value.absent(),
                Value<int> imageCount = const Value.absent(),
                Value<String?> details = const Value.absent(),
                Value<String?> typeName = const Value.absent(),
                Value<String?> scanText = const Value.absent(),
                Value<bool> neverExpires = const Value.absent(),
                Value<String?> extras = const Value.absent(),
                Value<String?> reminderOffsets = const Value.absent(),
                Value<String?> attachments = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion.insert(
                id: id,
                type: type,
                label: label,
                holder: holder,
                documentNumber: documentNumber,
                issuingCountry: issuingCountry,
                issueDate: issueDate,
                expiryDate: expiryDate,
                renewalLeadDays: renewalLeadDays,
                imagePath: imagePath,
                imageCount: imageCount,
                details: details,
                typeName: typeName,
                scanText: scanText,
                neverExpires: neverExpires,
                extras: extras,
                reminderOffsets: reminderOffsets,
                attachments: attachments,
                createdAt: createdAt,
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

typedef $$DocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocumentsTable,
      Document,
      $$DocumentsTableFilterComposer,
      $$DocumentsTableOrderingComposer,
      $$DocumentsTableAnnotationComposer,
      $$DocumentsTableCreateCompanionBuilder,
      $$DocumentsTableUpdateCompanionBuilder,
      (Document, BaseReferences<_$AppDatabase, $DocumentsTable, Document>),
      Document,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DocumentsTableTableManager get documents =>
      $$DocumentsTableTableManager(_db, _db.documents);
}
