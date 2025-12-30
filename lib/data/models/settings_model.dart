class SystemSettings {
  // Configurações Gerais
  final String currency;
  final String currencySymbol;
  final String dateFormat;
  final String timeZone;
  final String language;
  
  // Configurações Financeiras
  final double? defaultTaxRate;
  final double? defaultInterestRate;
  final int defaultPaymentDays;
  final bool autoGenerateReceivables;
  
  // Configurações de Notificações
  final bool enableEmailNotifications;
  final bool enableSmsNotifications;
  final int daysBeforeDueDateAlert;
  final bool notifyOnNewOrder;
  final bool notifyOnPayment;
  
  // Configurações de Segurança
  final int sessionTimeoutMinutes;
  final bool requireStrongPassword;
  final bool enableTwoFactorAuth;
  final int maxLoginAttempts;
  
  // Configurações de Backup
  final bool enableAutoBackup;
  final int backupFrequencyDays;
  final String? backupEmail;
  
  // Configurações de Relatórios
  final bool enableReports;
  final String reportDateFormat;
  final bool includeInactiveItems;
  
  SystemSettings({
    // Gerais
    this.currency = 'BRL',
    this.currencySymbol = 'R\$',
    this.dateFormat = 'dd/MM/yyyy',
    this.timeZone = 'America/Sao_Paulo',
    this.language = 'pt_BR',
    
    // Financeiras
    this.defaultTaxRate,
    this.defaultInterestRate,
    this.defaultPaymentDays = 30,
    this.autoGenerateReceivables = true,
    
    // Notificações
    this.enableEmailNotifications = false,
    this.enableSmsNotifications = false,
    this.daysBeforeDueDateAlert = 7,
    this.notifyOnNewOrder = false,
    this.notifyOnPayment = false,
    
    // Segurança
    this.sessionTimeoutMinutes = 60,
    this.requireStrongPassword = false,
    this.enableTwoFactorAuth = false,
    this.maxLoginAttempts = 5,
    
    // Backup
    this.enableAutoBackup = false,
    this.backupFrequencyDays = 7,
    this.backupEmail,
    
    // Relatórios
    this.enableReports = true,
    this.reportDateFormat = 'dd/MM/yyyy',
    this.includeInactiveItems = false,
  });

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    final general = json['general'] as Map<String, dynamic>? ?? {};
    final financial = json['financial'] as Map<String, dynamic>? ?? {};
    final notifications = json['notifications'] as Map<String, dynamic>? ?? {};
    final security = json['security'] as Map<String, dynamic>? ?? {};
    final backup = json['backup'] as Map<String, dynamic>? ?? {};
    final reports = json['reports'] as Map<String, dynamic>? ?? {};

    return SystemSettings(
      currency: general['currency'] as String? ?? 'BRL',
      currencySymbol: general['currencySymbol'] as String? ?? 'R\$',
      dateFormat: general['dateFormat'] as String? ?? 'dd/MM/yyyy',
      timeZone: general['timeZone'] as String? ?? 'America/Sao_Paulo',
      language: general['language'] as String? ?? 'pt_BR',
      
      defaultTaxRate: financial['defaultTaxRate'] != null
          ? (financial['defaultTaxRate'] as num).toDouble()
          : null,
      defaultInterestRate: financial['defaultInterestRate'] != null
          ? (financial['defaultInterestRate'] as num).toDouble()
          : null,
      defaultPaymentDays: financial['defaultPaymentDays'] as int? ?? 30,
      autoGenerateReceivables: financial['autoGenerateReceivables'] as bool? ?? true,
      
      enableEmailNotifications: notifications['enableEmailNotifications'] as bool? ?? false,
      enableSmsNotifications: notifications['enableSmsNotifications'] as bool? ?? false,
      daysBeforeDueDateAlert: notifications['daysBeforeDueDateAlert'] as int? ?? 7,
      notifyOnNewOrder: notifications['notifyOnNewOrder'] as bool? ?? false,
      notifyOnPayment: notifications['notifyOnPayment'] as bool? ?? false,
      
      sessionTimeoutMinutes: security['sessionTimeoutMinutes'] as int? ?? 60,
      requireStrongPassword: security['requireStrongPassword'] as bool? ?? false,
      enableTwoFactorAuth: security['enableTwoFactorAuth'] as bool? ?? false,
      maxLoginAttempts: security['maxLoginAttempts'] as int? ?? 5,
      
      enableAutoBackup: backup['enableAutoBackup'] as bool? ?? false,
      backupFrequencyDays: backup['backupFrequencyDays'] as int? ?? 7,
      backupEmail: backup['backupEmail'] as String?,
      
      enableReports: reports['enableReports'] as bool? ?? true,
      reportDateFormat: reports['reportDateFormat'] as String? ?? 'dd/MM/yyyy',
      includeInactiveItems: reports['includeInactiveItems'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'general': {
        'currency': currency,
        'currencySymbol': currencySymbol,
        'dateFormat': dateFormat,
        'timeZone': timeZone,
        'language': language,
      },
      'financial': {
        'defaultTaxRate': defaultTaxRate,
        'defaultInterestRate': defaultInterestRate,
        'defaultPaymentDays': defaultPaymentDays,
        'autoGenerateReceivables': autoGenerateReceivables,
      },
      'notifications': {
        'enableEmailNotifications': enableEmailNotifications,
        'enableSmsNotifications': enableSmsNotifications,
        'daysBeforeDueDateAlert': daysBeforeDueDateAlert,
        'notifyOnNewOrder': notifyOnNewOrder,
        'notifyOnPayment': notifyOnPayment,
      },
      'security': {
        'sessionTimeoutMinutes': sessionTimeoutMinutes,
        'requireStrongPassword': requireStrongPassword,
        'enableTwoFactorAuth': enableTwoFactorAuth,
        'maxLoginAttempts': maxLoginAttempts,
      },
      'backup': {
        'enableAutoBackup': enableAutoBackup,
        'backupFrequencyDays': backupFrequencyDays,
        'backupEmail': backupEmail,
      },
      'reports': {
        'enableReports': enableReports,
        'reportDateFormat': reportDateFormat,
        'includeInactiveItems': includeInactiveItems,
      },
    };
  }

  SystemSettings copyWith({
    String? currency,
    String? currencySymbol,
    String? dateFormat,
    String? timeZone,
    String? language,
    double? defaultTaxRate,
    double? defaultInterestRate,
    int? defaultPaymentDays,
    bool? autoGenerateReceivables,
    bool? enableEmailNotifications,
    bool? enableSmsNotifications,
    int? daysBeforeDueDateAlert,
    bool? notifyOnNewOrder,
    bool? notifyOnPayment,
    int? sessionTimeoutMinutes,
    bool? requireStrongPassword,
    bool? enableTwoFactorAuth,
    int? maxLoginAttempts,
    bool? enableAutoBackup,
    int? backupFrequencyDays,
    String? backupEmail,
    bool? enableReports,
    String? reportDateFormat,
    bool? includeInactiveItems,
  }) {
    return SystemSettings(
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      dateFormat: dateFormat ?? this.dateFormat,
      timeZone: timeZone ?? this.timeZone,
      language: language ?? this.language,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
      defaultInterestRate: defaultInterestRate ?? this.defaultInterestRate,
      defaultPaymentDays: defaultPaymentDays ?? this.defaultPaymentDays,
      autoGenerateReceivables: autoGenerateReceivables ?? this.autoGenerateReceivables,
      enableEmailNotifications: enableEmailNotifications ?? this.enableEmailNotifications,
      enableSmsNotifications: enableSmsNotifications ?? this.enableSmsNotifications,
      daysBeforeDueDateAlert: daysBeforeDueDateAlert ?? this.daysBeforeDueDateAlert,
      notifyOnNewOrder: notifyOnNewOrder ?? this.notifyOnNewOrder,
      notifyOnPayment: notifyOnPayment ?? this.notifyOnPayment,
      sessionTimeoutMinutes: sessionTimeoutMinutes ?? this.sessionTimeoutMinutes,
      requireStrongPassword: requireStrongPassword ?? this.requireStrongPassword,
      enableTwoFactorAuth: enableTwoFactorAuth ?? this.enableTwoFactorAuth,
      maxLoginAttempts: maxLoginAttempts ?? this.maxLoginAttempts,
      enableAutoBackup: enableAutoBackup ?? this.enableAutoBackup,
      backupFrequencyDays: backupFrequencyDays ?? this.backupFrequencyDays,
      backupEmail: backupEmail ?? this.backupEmail,
      enableReports: enableReports ?? this.enableReports,
      reportDateFormat: reportDateFormat ?? this.reportDateFormat,
      includeInactiveItems: includeInactiveItems ?? this.includeInactiveItems,
    );
  }
}

