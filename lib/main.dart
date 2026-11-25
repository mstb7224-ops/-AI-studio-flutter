// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL',
    defaultValue: 'https://xewxigpmvuxkuqtxhxha.supabase.co');
const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_C-f5NVBKOhZBXXb45ybjvw_JKpCpI8h');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty) {
    await Supabase.initialize(
        url: supabaseUrl, anonKey: supabasePublishableKey);
  }
  runApp(const DailyGloApp());
}

class DailyGloApp extends StatelessWidget {
  const DailyGloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DailyGlo',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xff3b82f6), brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xff08111f),
        inputDecorationTheme:
            const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      home: supabaseUrl.isEmpty || supabasePublishableKey.isEmpty
          ? const ConfigurationPage()
          : const AuthGate(),
    );
  }
}

class ConfigurationPage extends StatelessWidget {
  const ConfigurationPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
                'Supabase configuration is missing. Add SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY to the build secrets.',
                textAlign: TextAlign.center),
          ),
        ),
      );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (!snapshot.hasData && client.auth.currentSession == null) {
          return const SplashPage();
        }
        final session = snapshot.data?.session ?? client.auth.currentSession;
        return session == null ? const HomePage() : const DashboardPage();
      },
    );
  }
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('DailyGlo'), centerTitle: true),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 30),
            const Icon(Icons.auto_awesome, size: 72, color: Color(0xff60a5fa)),
            const SizedBox(height: 20),
            Text('DailyGlo',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
                'Membership, verified draw updates, and premium predictions.',
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            FilledButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AuthPage(register: true))),
                icon: const Icon(Icons.person_add),
                label: const Text('Create account')),
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AuthPage(register: false))),
                icon: const Icon(Icons.login),
                label: const Text('Member login')),
            const SizedBox(height: 32),
            const FeatureCard(
                icon: Icons.verified_user,
                title: 'Secure membership',
                text:
                    'Your member account is protected by Supabase Auth and database policies.'),
            const FeatureCard(
                icon: Icons.payment,
                title: 'Payment review',
                text:
                    'Submit your payment reference and optional bank screenshot for review.'),
            const FeatureCard(
                icon: Icons.emoji_events,
                title: 'Premium predictions',
                text:
                    'Verified paid members can view published prediction rounds.'),
          ],
        ),
      );
}

class FeatureCard extends StatelessWidget {
  const FeatureCard(
      {super.key, required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
            leading: Icon(icon, color: const Color(0xff60a5fa)),
            title: Text(title),
            subtitle: Text(text)),
      );
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.register});
  final bool register;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final emailOrMobile = TextEditingController();
  final fullName = TextEditingController();
  final mobile = TextEditingController();
  final city = TextEditingController();
  final password = TextEditingController();
  String country = 'Saudi Arabia';
  bool loading = false;
  bool obscure = true;

  SupabaseClient get client => Supabase.instance.client;

  @override
  void dispose() {
    emailOrMobile.dispose();
    fullName.dispose();
    mobile.dispose();
    city.dispose();
    password.dispose();
    super.dispose();
  }

  String authEmailFromMobile(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return '$digits@members.dailyglo.local';
  }

  Future<void> submit() async {
    if (password.text.length < 6 ||
        (widget.register &&
            (fullName.text.trim().isEmpty ||
                mobile.text.trim().isEmpty ||
                city.text.trim().isEmpty))) {
      showMessage(context,
          'Please complete all fields. Password must be at least 6 characters.');
      return;
    }
    setState(() => loading = true);
    try {
      if (widget.register) {
        final email = authEmailFromMobile(mobile.text);
        final result = await client.auth
            .signUp(email: email, password: password.text, data: {
          'full_name': fullName.text.trim(),
          'mobile': mobile.text.trim(),
          'city': city.text.trim(),
          'country': country
        });
        if (result.user == null) {
          throw AuthException('Supabase did not create the account.');
        }
        if (result.session == null) {
          throw AuthException(
              'Account created. Email confirmation is enabled; confirm the account before logging in.');
        }
        await client.from('members').upsert({
          'id': result.user!.id,
          'email': email,
          'mobile': mobile.text.trim(),
          'user_type': 'free'
        }, onConflict: 'id');
        if (mounted) {
          showMessage(context, 'Registration successful. You can now log in.',
              error: false);
        }
      } else {
        var email = emailOrMobile.text.trim();
        if (!email.contains('@')) {
          final lookup = await client
              .rpc('resolve_login_email', params: {'p_mobile': email});
          email = (lookup as String?) ?? authEmailFromMobile(email);
        }
        await client.auth
            .signInWithPassword(email: email, password: password.text);
      }
    } catch (error) {
      if (mounted) showMessage(context, friendlyError(error));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(widget.register ? 'Create account' : 'Member login')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (widget.register) ...[
              TextField(
                  controller: fullName,
                  decoration: const InputDecoration(labelText: 'Full name')),
              const SizedBox(height: 12),
              TextField(
                  controller: mobile,
                  keyboardType: TextInputType.phone,
                  decoration:
                      const InputDecoration(labelText: 'Mobile number')),
              const SizedBox(height: 12),
              TextField(
                  controller: city,
                  decoration: const InputDecoration(labelText: 'City')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                  value: country,
                  decoration: const InputDecoration(labelText: 'Country'),
                  items: const [
                    'Saudi Arabia',
                    'Bangladesh',
                    'India',
                    'Pakistan',
                    'UAE',
                    'Qatar',
                    'Kuwait',
                    'Bahrain',
                    'Oman',
                    'Other'
                  ]
                      .map((value) =>
                          DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => country = value ?? country)),
              const SizedBox(height: 12),
            ] else
              TextField(
                  controller: emailOrMobile,
                  decoration: const InputDecoration(
                      labelText: 'Email or mobile number')),
            const SizedBox(height: 12),
            TextField(
                controller: password,
                obscureText: obscure,
                decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                        onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(obscure
                            ? Icons.visibility
                            : Icons.visibility_off)))),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: loading ? null : submit,
                child: loading
                    ? const CircularProgressIndicator()
                    : Text(widget.register ? 'Register' : 'Login')),
            const SizedBox(height: 12),
            TextButton(
                onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AuthPage(register: !widget.register))),
                child: Text(widget.register
                    ? 'Already have an account? Login'
                    : 'New member? Register')),
          ],
        ),
      );
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? member;
  bool loading = true;
  SupabaseClient get client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    loadMember();
  }

  Future<void> loadMember() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) return;
      final result = await client
          .from('members')
          .select('email,mobile,user_type,created_at')
          .eq('id', user.id)
          .maybeSingle();
      if (mounted) setState(() => member = result);
    } catch (error) {
      if (mounted) showMessage(context, friendlyError(error));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> logout() async => client.auth.signOut();

  @override
  Widget build(BuildContext context) {
    final paid = member?['user_type'] == 'paid';
    return Scaffold(
      appBar: AppBar(title: const Text('DailyGlo Dashboard'), actions: [
        IconButton(onPressed: logout, icon: const Icon(Icons.logout))
      ]),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadMember,
              child: ListView(padding: const EdgeInsets.all(24), children: [
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Welcome back',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                              const SizedBox(height: 8),
                              Text(member?['email']?.toString() ??
                                  client.auth.currentUser?.email ??
                                  ''),
                              const SizedBox(height: 12),
                              Chip(
                                  label: Text(
                                      paid ? 'Paid Member' : 'Free Member'),
                                  avatar: Icon(
                                      paid ? Icons.verified : Icons.person,
                                      size: 18))
                            ]))),
                const SizedBox(height: 16),
                FilledButton.icon(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PaymentPage())),
                    icon: const Icon(Icons.payment),
                    label: Text(paid
                        ? 'Submit another payment'
                        : 'Upgrade to paid membership')),
                const SizedBox(height: 12),
                if (paid)
                  OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PredictionsPage())),
                      icon: const Icon(Icons.emoji_events),
                      label: const Text('View premium predictions')),
              ])),
    );
  }
}

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final reference = TextEditingController();
  final amountPaid = TextEditingController(text: '980');
  final discountCode = TextEditingController();
  final picker = ImagePicker();
  String method = 'bkash';
  double discountPercent = 0;
  XFile? screenshot;
  Uint8List? screenshotBytes;
  bool loading = false;
  SupabaseClient get client => Supabase.instance.client;
  double get finalAmount =>
      double.parse((980 * (1 - discountPercent / 100)).toStringAsFixed(2));

  @override
  void dispose() {
    reference.dispose();
    amountPaid.dispose();
    discountCode.dispose();
    super.dispose();
  }

  Future<void> applyDiscount() async {
    final code = discountCode.text.trim().toUpperCase();
    if (code.isEmpty) return setState(() => discountPercent = 0);
    try {
      final row = await client
          .from('discount_codes')
          .select('code,percent_off,max_uses,used_count,expires_at')
          .eq('code', code)
          .eq('active', true)
          .maybeSingle();
      if (row == null) {
        throw PostgrestException(message: 'Discount code is not active.');
      }
      final expires = row['expires_at'] == null
          ? null
          : DateTime.tryParse(row['expires_at'].toString());
      final maxUses = row['max_uses'] as int?;
      final used = (row['used_count'] as num?)?.toInt() ?? 0;
      if (expires != null && expires.isBefore(DateTime.now().toUtc())) {
        throw PostgrestException(message: 'Discount code has expired.');
      }
      if (maxUses != null && used >= maxUses) {
        throw PostgrestException(
            message: 'Discount code has reached its usage limit.');
      }
      setState(() => discountPercent = (row['percent_off'] as num).toDouble());
      showMessage(context,
          'Discount applied: ${discountPercent.toStringAsFixed(0)}% off.',
          error: false);
    } catch (error) {
      setState(() => discountPercent = 0);
      showMessage(context, friendlyError(error));
    }
  }

  Future<void> chooseScreenshot() async {
    final image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      return showMessage(context, 'Screenshot must be 5 MB or smaller.');
    }
    setState(() {
      screenshot = image;
      screenshotBytes = bytes;
    });
  }

  Future<void> submit() async {
    final ref = reference.text.trim();
    final paid = double.tryParse(amountPaid.text.trim());
    if (!RegExp(r'^\d{4}$').hasMatch(ref)) {
      return showMessage(context,
          'Enter exactly the last four digits of the transaction reference.');
    }
    if (paid == null || paid <= 0) {
      return showMessage(context, 'Enter the amount actually sent.');
    }
    if (method != 'bkash' && screenshotBytes == null) {
      return showMessage(context, 'Choose the bank payment screenshot.');
    }
    setState(() => loading = true);
    String? path;
    try {
      final user = client.auth.currentUser;
      if (user == null) throw AuthException('Please log in again.');
      if (screenshotBytes != null && screenshot != null) {
        final extension =
            screenshot!.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
        path =
            'iqama/${user.id}/payment-${DateTime.now().millisecondsSinceEpoch}.$extension';
        await client.storage.from('iqama_documents').uploadBinary(
            path, screenshotBytes!,
            fileOptions: FileOptions(
                contentType: extension == 'png' ? 'image/png' : 'image/jpeg',
                upsert: false));
      }
      await client.from('payments').insert({
        'user_id': user.id,
        'amount': paid,
        'tx_id': '[$method] $ref',
        'status': 'unverified',
        'method': method,
        'final_amount': finalAmount,
        'discount_code': discountCode.text.trim().toUpperCase().isEmpty
            ? null
            : discountCode.text.trim().toUpperCase(),
        'discount_percent': discountPercent,
        'transaction_reference': ref,
        'screenshot_url': path
      });
      if (mounted) {
        showMessage(context, 'Payment submitted and is awaiting admin review.',
            error: false);
      }
      reference.clear();
      amountPaid.text = finalAmount.toStringAsFixed(0);
      discountCode.clear();
      setState(() {
        discountPercent = 0;
        screenshot = null;
        screenshotBytes = null;
      });
    } catch (error) {
      if (path != null) {
        try {
          await client.storage.from('iqama_documents').remove([path]);
        } catch (_) {}
      }
      if (mounted) showMessage(context, friendlyError(error));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Payment verification')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Membership fee: 980 SAR'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
              value: method,
              decoration: const InputDecoration(labelText: 'Payment method'),
              items: const [
                DropdownMenuItem(value: 'bkash', child: Text('bKash')),
                DropdownMenuItem(
                    value: 'alrajhi', child: Text('Al Rajhi Bank')),
                DropdownMenuItem(
                    value: 'bangkok_bank', child: Text('Kasikornbank / KBank'))
              ],
              onChanged: (value) => setState(() => method = value ?? method)),
          const SizedBox(height: 12),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(method == 'bkash'
                      ? 'Use the configured bKash payment instruction. Never enter a PIN or OTP.'
                      : 'Use the configured bank transfer instruction. Upload the payment screenshot below.'))),
          const SizedBox(height: 12),
          TextField(
              controller: reference,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                  labelText: 'Last 4 digits of reference')),
          TextField(
              controller: amountPaid,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Amount sent (SAR)')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: discountCode,
                    textCapitalization: TextCapitalization.characters,
                    decoration:
                        const InputDecoration(labelText: 'Discount code'))),
            const SizedBox(width: 8),
            FilledButton(
                onPressed: loading ? null : applyDiscount,
                child: const Text('Apply'))
          ]),
          const SizedBox(height: 12),
          Text('Current payable: ${finalAmount.toStringAsFixed(2)} SAR'),
          Text(
              'Remaining: ${((finalAmount - (double.tryParse(amountPaid.text) ?? 0)).clamp(0, finalAmount)).toStringAsFixed(2)} SAR'),
          if (method != 'bkash') ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
                onPressed: loading ? null : chooseScreenshot,
                icon: const Icon(Icons.upload_file),
                label: Text(screenshot == null
                    ? 'Choose bank screenshot'
                    : screenshot!.name))
          ],
          const SizedBox(height: 24),
          FilledButton(
              onPressed: loading ? null : submit,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Submit payment')),
        ],
      ));
}

class PredictionsPage extends StatefulWidget {
  const PredictionsPage({super.key});

  @override
  State<PredictionsPage> createState() => _PredictionsPageState();
}

class _PredictionsPageState extends State<PredictionsPage> {
  Future<List<Map<String, dynamic>>> load() async {
    final rows = await Supabase.instance.client
        .from('predictions')
        .select('id,round_number,winning_number,created_at')
        .eq('is_published', true)
        .order('round_number', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Premium predictions')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: load(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(friendlyError(snapshot.error!)));
            }
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) {
              return const Center(child: Text('No published predictions yet.'));
            }
            return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return Card(
                      child: ListTile(
                          leading:
                              const Icon(Icons.bolt, color: Color(0xff60a5fa)),
                          title: Text('Round #${row['round_number']}'),
                          subtitle:
                              Text('Published: ${row['created_at'] ?? ''}'),
                          trailing: Text('${row['winning_number']}',
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold))));
                });
          },
        ),
      );
}

void showMessage(BuildContext context, String message, {bool error = true}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error ? Colors.red.shade800 : Colors.green.shade800,
      content: Text(message)));
}

String friendlyError(Object error) {
  if (error is AuthException) return error.message;
  if (error is PostgrestException) return error.message;
  if (error is StorageException) return error.message;
  return 'Something went wrong. Please check your internet connection and try again.';
}
