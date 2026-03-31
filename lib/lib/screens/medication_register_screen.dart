// lib/screens/medication_register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/medication_model.dart';
import '../db/medication_db.dart';

class MedicationRegisterScreen extends StatefulWidget {
  final MedicationModel? existing;
  const MedicationRegisterScreen({Key? key, this.existing}) : super(key: key);

  @override
  State<MedicationRegisterScreen> createState() =>
      _MedicationRegisterScreenState();
}

class _MedicationRegisterScreenState extends State<MedicationRegisterScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCon   = TextEditingController();
  final _amountCon = TextEditingController();
  final _dailyCon  = TextEditingController(text: '1');

  MedicationType _type = MedicationType.days;
  bool _saving = false;

  static const _green = Color(0xFF66BB6A);

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final m = widget.existing!;
      _nameCon.text   = m.name;
      _type           = m.type;
      _amountCon.text = (m.type == MedicationType.days
              ? m.totalDays
              : m.totalPills)
          .toString();
      _dailyCon.text  = m.dailyCount.toString();
    }
  }

  @override
  void dispose() {
    _nameCon.dispose();
    _amountCon.dispose();
    _dailyCon.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final amount = int.parse(_amountCon.text);
    final daily  = int.parse(_dailyCon.text);

    final med = MedicationModel(
      id:         widget.existing?.id,
      name:       _nameCon.text.trim(),
      type:       _type,
      totalDays:  _type == MedicationType.days  ? amount : 0,
      totalPills: _type == MedicationType.pills ? amount : 0,
      dailyCount: daily,
      takenCount: widget.existing?.takenCount ?? 0,
      startDate:  widget.existing?.startDate ?? DateTime.now(),
    );

    if (widget.existing == null) {
      await MedicationDB().insert(med);
    } else {
      await MedicationDB().update(med);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: Text(widget.existing == null ? '약 등록' : '약 수정',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('약 이름'),
              _textField(
                controller: _nameCon,
                hint: '예) 혈압약, 비타민C',
                validator: (v) => v!.isEmpty ? '약 이름을 입력해주세요' : null,
              ),
              const SizedBox(height: 24),

              _label('수량 입력 방식'),
              _typeSelector(),
              const SizedBox(height: 24),

              _label(_type == MedicationType.days ? '총 며칠분인가요?' : '총 몇 알인가요?'),
              _numberField(
                controller: _amountCon,
                hint: _type == MedicationType.days ? '예) 30' : '예) 90',
                suffix: _type == MedicationType.days ? '일분' : '알',
                validator: (v) {
                  if (v!.isEmpty) return '수량을 입력해주세요';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return '올바른 숫자를 입력해주세요';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              _label('하루 복용 횟수'),
              _dailySelector(),
              const SizedBox(height: 24),

              if (_amountCon.text.isNotEmpty && _dailyCon.text.isNotEmpty)
                _preview(),

              const SizedBox(height: 32),
              _saveButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333))),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        validator: validator,
        style: const TextStyle(fontSize: 18),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _green, width: 2)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red)),
        ),
      );

  Widget _numberField({
    required TextEditingController controller,
    required String hint,
    required String suffix,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 18),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          suffixText: suffix,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _green, width: 2)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red)),
        ),
      );

  Widget _typeSelector() => Container(
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          _typeBtn('📅 며칠분', MedicationType.days),
          _typeBtn('💊 몇 알', MedicationType.pills),
        ]),
      );

  Widget _typeBtn(String label, MedicationType t) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() {
            _type = t;
            _amountCon.clear();
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _type == t ? _green : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _type == t ? Colors.white : Colors.black54)),
          ),
        ),
      );

  Widget _dailySelector() => Row(
        children: List.generate(4, (i) {
          final n = i + 1;
          final selected = _dailyCon.text == '$n';
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _dailyCon.text = '$n'),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? _green : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${n}회',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: selected ? Colors.white : Colors.black54)),
              ),
            ),
          );
        }),
      );

  Widget _preview() {
    final amount = int.tryParse(_amountCon.text) ?? 0;
    final daily  = int.tryParse(_dailyCon.text) ?? 1;
    final total  = _type == MedicationType.days ? amount * daily : amount;
    final days   = daily > 0 ? (total / daily).floor() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _green.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📋 등록 미리보기',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Text('총 복용 횟수: $total회', style: const TextStyle(fontSize: 15)),
        Text('예상 복용 기간: $days일', style: const TextStyle(fontSize: 15)),
        Text('하루 $daily번씩 복용', style: const TextStyle(fontSize: 15)),
      ]),
    );
  }

  Widget _saveButton() => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: _green,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: _saving
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  widget.existing == null ? '등록하기' : '수정하기',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
        ),
      );
}
