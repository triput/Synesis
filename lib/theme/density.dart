/// View density (SPEC §7.8). Calm is the product default.
enum ViewDensity {
  calm,
  compact,
}

extension ViewDensityMetrics on ViewDensity {
  double get listRowPaddingV => this == ViewDensity.calm ? 14 : 8;
  double get listRowPaddingH => this == ViewDensity.calm ? 14 : 10;
  double get listGap => this == ViewDensity.calm ? 8 : 0;
  double get subjectSize => this == ViewDensity.calm ? 15 : 13;
  double get snippetSize => this == ViewDensity.calm ? 13 : 12;
  double get bodySize => this == ViewDensity.calm ? 16 : 14;
  double get chromeLabelSize => this == ViewDensity.calm ? 12 : 11;
  double get emptyStateTitleSize => this == ViewDensity.calm ? 16 : 14;
  double get emptyStateBodySize => this == ViewDensity.calm ? 13 : 12;
  double get emptyStateIconSize => this == ViewDensity.calm ? 40 : 32;
  double get messageRadius => this == ViewDensity.calm ? 14 : 0;
  double get sidebarWidth => this == ViewDensity.calm ? 230 : 200;
  double get listWidth => this == ViewDensity.calm ? 340 : 320;
}
