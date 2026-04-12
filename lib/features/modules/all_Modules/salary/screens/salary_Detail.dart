// lib/features/modules/all_Modules/salary/screens/salary_detail_screen.dart
//
// Usage – single employee:
//   SalaryDetailScreen.single(model: salaryModel)
//
// Usage – list (e.g. from fetchSalaryBySite / fetchSalaryByEmployee):
//   SalaryDetailScreen.list(models: salaryModelList)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled2/features/modules/all_Modules/salary/service-provider/salaryModel/salary_model.dart';

// ---------------------------------------------------------------------------
// ENTRY POINT
// ---------------------------------------------------------------------------

class SalaryDetailScreen extends StatefulWidget {
  final List<SalaryModel> models;

  const SalaryDetailScreen._({required this.models});

  factory SalaryDetailScreen.single({required SalaryModel model}) =>
      SalaryDetailScreen._(models: [model]);

  factory SalaryDetailScreen.list({required List<SalaryModel> models}) =>
      SalaryDetailScreen._(models: models);

  @override
  State<SalaryDetailScreen> createState() => _SalaryDetailScreenState();
}

// ---------------------------------------------------------------------------
// STATE
// ---------------------------------------------------------------------------

class _SalaryDetailScreenState extends State<SalaryDetailScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late final AnimationController _slideCtrl;
  late final AnimationController _fadeCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(_fadeCtrl);
    _slideCtrl.forward();
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _selectEmployee(int index) {
    if (index == _selectedIndex) return;
    _slideCtrl.reset();
    _fadeCtrl.reset();
    setState(() => _selectedIndex = index);
    _slideCtrl.forward();
    _fadeCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isList = widget.models.length > 1;
    final current = widget.models[_selectedIndex];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Column(
          children: [
            _Header(model: current, onBack: () => Navigator.pop(context)),
            if (isList)
              _EmployeeStrip(
                models: widget.models,
                selectedIndex: _selectedIndex,
                onSelect: _selectEmployee,
              ),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _DetailBody(model: current),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HEADER
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final SalaryModel model;
  final VoidCallback onBack;

  const _Header({required this.model, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final mp = model.manpowerDetails;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF3B82F6), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.24),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.24),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Salary Slip',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w500)),
                  const Spacer(),
                  _MonthBadge(
                      monthName: model.monthName, year: '${model.year}'),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(name: mp.fullName),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mp.fullName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3)),
                        const SizedBox(height: 3),
                        Text(mp.designation,
                            style: TextStyle(
                                color: Colors.blue.shade100, fontSize: 13)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.24),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(mp.employeeCode,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  letterSpacing: 0.8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Net Pay',
                          style: TextStyle(
                              color: Colors.blue.shade100,
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(
                        '${model.isDeficit ? '-' : ''}₹${model.netPay.abs().toStringAsFixed(0)}',
                        style: TextStyle(
                            color: model.isDeficit
                                ? const Color(0xFFFCA5A5)
                                : Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5),
                      ),
                      if (model.isDeficit)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Deficit',
                              style: TextStyle(
                                  color: Color(0xFFFCA5A5),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EMPLOYEE STRIP  (list mode only)
// ---------------------------------------------------------------------------

class _EmployeeStrip extends StatefulWidget {
  final List<SalaryModel> models;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _EmployeeStrip({
    required this.models,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  State<_EmployeeStrip> createState() => _EmployeeStripState();
}

class _EmployeeStripState extends State<_EmployeeStrip> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    const int columns = 3;
    const int collapsedRows = 1;
    const int expandedRows = 3;
    const double tileHeight = 40;
    const double spacing = 8;

    final rowsToShow = _expanded ? expandedRows : collapsedRows;
    final maxVisibleItems = rowsToShow * columns;
    final shouldScroll = widget.models.length > maxVisibleItems;

    final indices = List<int>.generate(widget.models.length, (i) => i);
    if (!_expanded && widget.selectedIndex >= columns) {
      indices.remove(widget.selectedIndex);
      indices.insert(0, widget.selectedIndex);
    }

    final gridHeight = (rowsToShow * tileHeight) + ((rowsToShow - 1) * spacing);

    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Manpower (${widget.models.length})',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              if (widget.models.length > columns)
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Row(
                    children: [
                      Text(
                        _expanded ? 'Show Less' : 'Show More',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: gridHeight,
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: 2.8,
              ),
              physics: shouldScroll
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemCount: indices.length,
              itemBuilder: (_, itemPosition) {
                final i = indices[itemPosition];
                final selected = i == widget.selectedIndex;
                final name = widget.models[i].manpowerDetails.fullName;
                final initials = name
                    .split(' ')
                    .take(2)
                    .map((w) => w.isNotEmpty ? w[0] : '')
                    .join()
                    .toUpperCase();

                return GestureDetector(
                  onTap: () => widget.onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF60A5FA)
                            : Colors.transparent,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 9,
                          backgroundColor: selected
                              ? Colors.white.withOpacity(0.3)
                              : const Color(0xFF475569),
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 7,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            name.split(' ').first,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.white70,
                              fontSize: 11,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DETAIL BODY
// ---------------------------------------------------------------------------

class _DetailBody extends StatelessWidget {
  final SalaryModel model;
  const _DetailBody({required this.model});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mp = model.manpowerDetails;
    final co = model.companyDetails;
    final e = model.earnings;
    final d = model.deductions;

    return Container(
      color: colorScheme.surfaceContainerLowest,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _SectionCard(
            title: 'ATTENDANCE',
            icon: Icons.calendar_month_rounded,
            iconColor: colorScheme.primary,
            child: _AttendanceSection(model: model),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'EMPLOYEE INFO',
            icon: Icons.person_rounded,
            iconColor: colorScheme.secondary,
            child: Column(
              children: [
                _InfoRow('Full Name', mp.fullName),
                _InfoRow('Designation', mp.designation),
                _InfoRow('Employee Code', mp.employeeCode, mono: true),
                _InfoRow('Department', _capitalize(mp.type ?? '')),
                _InfoRow('Date of Joining', _formatDate(mp.dateOfJoining)),
                _InfoRow('Date of Birth', _formatDate(mp.dateOfBirth)),
                _InfoRow('Pay Basis', _capitalize(mp.payBasics ?? '')),
                _InfoRow('Phone', mp.phoneNumber ?? ''),
                _InfoRow('Address', mp.address ?? ''),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'STATUTORY DETAILS',
            icon: Icons.shield_rounded,
            iconColor: colorScheme.tertiary,
            child: Column(
              children: [
                _InfoRow('UAN Number', mp.uanNumber ?? '', mono: true),
                _InfoRow('EPF Number', mp.epfNumber ?? '', mono: true),
                _InfoRow('ESIC Number', mp.esicNumber ?? '', mono: true),
                _InfoRow('PAN Number', mp.panNumber ?? '', mono: true),
                _InfoRow('Aadhar Number', mp.aaddharNumber ?? '', mono: true),
                _InfoRow('PF Applicable', mp.pfApplicable ? 'Yes' : 'No'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'BANK DETAILS',
            icon: Icons.account_balance_rounded,
            iconColor: colorScheme.secondary,
            child: Column(
              children: [
                _InfoRow('Account Number', mp.bankAccountNumber ?? '',
                    mono: true),
                _InfoRow('IFSC Code', mp.ifscCode ?? '', mono: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'COMPANY',
            icon: Icons.business_rounded,
            iconColor: colorScheme.primary,
            child: Column(
              children: [
                _InfoRow('Company Name', co.name),
                _InfoRow('Bank', co.bankName ?? ''),
                _InfoRow('Account No.', co.accountNumber ?? '', mono: true),
                _InfoRow('IFSC', co.ifscCode ?? '', mono: true),
                _InfoRow('PAN', co.panNumber ?? '', mono: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SectionCard(
                  title: 'EARNINGS',
                  icon: Icons.trending_up_rounded,
                  iconColor: colorScheme.tertiary,
                  child: Column(
                    children: [
                      _AmountRow('Basic', e.basic),
                      _AmountRow('HRA', e.hra),
                      _AmountRow('DA', e.da),
                      _AmountRow('Special\nAllow.', e.specialAllowance),
                      _AmountRow('Travel\nAllow.', e.travelAllowance),
                      _AmountRow('Medical\nAllow.', e.medicalAllowance),
                      _AmountRow('OT', e.ot),
                      const Divider(height: 16, thickness: 1),
                      _AmountRow('Total', e.total,
                          isBold: true, color: colorScheme.tertiary),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SectionCard(
                  title: 'DEDUCTIONS',
                  icon: Icons.trending_down_rounded,
                  iconColor: colorScheme.error,
                  child: Column(
                    children: [
                      _AmountRow('PF', d.pf),
                      _AmountRow('ESI', d.esi),
                      _AmountRow('P. Tax', d.ptax),
                      _AmountRow('LWF', d.lwf),
                      _AmountRow('Advance', d.advance),
                      const Divider(height: 16, thickness: 1),
                      _AmountRow('Total', d.total,
                          isBold: true, color: colorScheme.error),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _NetPayCard(model: model),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ATTENDANCE SECTION
// ---------------------------------------------------------------------------

class _AttendanceSection extends StatelessWidget {
  final SalaryModel model;
  const _AttendanceSection({required this.model});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pct = model.attendancePercentage;
    return Column(
      children: [
        Row(
          children: [
            _AttStat(
                value: '${model.presentDays}',
                label: 'Present',
                color: colorScheme.tertiary),
            const SizedBox(width: 8),
            _AttStat(
                value: '${model.absentDays}',
                label: 'Absent',
                color: colorScheme.error),
            const SizedBox(width: 8),
            _AttStat(
                value: '${model.totalDays}',
                label: 'Total',
                color: colorScheme.primary),
            const SizedBox(width: 8),
            _AttStat(
                value: '${model.totalHours}h',
                label: 'Hours',
                color: colorScheme.secondary),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              pct >= 0.75
                  ? colorScheme.tertiary
                  : pct >= 0.5
                      ? colorScheme.secondary
                      : colorScheme.error,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${(pct * 100).toStringAsFixed(0)}% attendance',
            style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// NET PAY CARD
// ---------------------------------------------------------------------------

class _NetPayCard extends StatelessWidget {
  final SalaryModel model;
  const _NetPayCard({required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: model.isDeficit
              ? [const Color(0xFF7F1D1D), const Color(0xFFB91C1C)]
              : [const Color(0xFF1E3A8A), const Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (model.isDeficit ? Colors.red : const Color(0xFF2563EB))
                .withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  model.isDeficit
                      ? Icons.warning_amber_rounded
                      : Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text('SALARY SUMMARY',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _SummaryTile('Gross Earnings',
                  '₹${model.grossEarnings.toStringAsFixed(2)}'),
              const SizedBox(width: 10),
              _SummaryTile('Total Deductions',
                  '₹${model.totalDeductions.toStringAsFixed(2)}',
                  sub: true),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SummaryTile(
                  'Monthly CTC', '₹${model.monthlyCTC.toStringAsFixed(2)}'),
              const SizedBox(width: 10),
              _SummaryTile(
                'Net Pay',
                '${model.isDeficit ? '-' : ''}₹${model.netPay.abs().toStringAsFixed(2)}',
                highlight: true,
                isNeg: model.isDeficit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// REUSABLE WIDGETS
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: colorScheme.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const _InfoRow(this.label, this.value, {this.mono = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEmpty = value.trim().isEmpty || value == 'null' || value == '—';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isEmpty ? '—' : value,
              style: TextStyle(
                  fontSize: 12,
                  color: isEmpty ? colorScheme.outline : colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontFamily: mono ? 'monospace' : null,
                  letterSpacing: mono ? 0.5 : 0),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBold;
  final Color? color;

  const _AmountRow(this.label, this.amount, {this.isBold = false, this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isZero = amount == 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: isZero && !isBold
                        ? colorScheme.outline
                        : colorScheme.onSurfaceVariant,
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w500)),
          ),
          Text('₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 12,
                  color: color ??
                      (isZero && !isBold
                          ? colorScheme.outline
                          : colorScheme.onSurface),
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }
}

class _AttStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _AttStat(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _MonthBadge extends StatelessWidget {
  final String monthName;
  final String year;
  const _MonthBadge({required this.monthName, required this.year});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Text('$monthName $year',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3)),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();
    final hue = (name.codeUnits.fold(0, (a, b) => a + b) % 360).toDouble();
    final color = HSLColor.fromAHSL(1, hue, 0.6, 0.55).toColor();

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Center(
        child: Text(initials,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final bool sub;
  final bool highlight;
  final bool isNeg;

  const _SummaryTile(this.label, this.value,
      {this.sub = false, this.highlight = false, this.isNeg = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: highlight
              ? Colors.white.withOpacity(0.15)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: highlight
              ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: isNeg ? const Color(0xFFFCA5A5) : Colors.white,
                    fontSize: highlight ? 16 : 14,
                    fontWeight: highlight ? FontWeight.w800 : FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HELPERS
// ---------------------------------------------------------------------------

String _formatDate(String? s) {
  if (s == null || s.isEmpty || s == 'null') return '—';
  try {
    final d = DateTime.parse(s);
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  } catch (_) {
    return s;
  }
}

String _capitalize(String s) => s
    .split('_')
    .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');
