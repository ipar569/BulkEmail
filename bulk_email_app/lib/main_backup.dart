import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bulk_email_app/splash_screen.dart'; // Import the SplashScreen
import 'package:excel/excel.dart'; // Import for Excel files
import 'package:csv/csv.dart'; // Import for CSV files
import 'dart:typed_data'; // Required for byte data
import 'dart:convert'; // Required for UTF-8 decoding
import 'dart:io'; // Required for File operations
import 'package:shared_preferences/shared_preferences.dart'; // Import for persistent storage
import 'package:mailer/mailer.dart'; // Import for sending emails
import 'package:mailer/smtp_server.dart'; // Import for SmtpServer

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized
  print('main: Application started.');
  runApp(
    ChangeNotifierProvider(
      create: (context) =>
          EmailSettingsProvider()
            ..loadSettings(), // Load settings when provider is created
      child: const MyApp(),
    ),
  );
}

class EmailSettingsProvider with ChangeNotifier {
  String _senderEmail = '';
  String _senderPassword = ''; // Or API Key

  String get senderEmail => _senderEmail;
  String get senderPassword => _senderPassword;

  EmailSettingsProvider() {
    print('EmailSettingsProvider: Constructor called.');
    // No need to call loadSettings here as it's called in main
  }

  Future<void> loadSettings() async {
    print('EmailSettingsProvider: Loading settings...');
    final prefs = await SharedPreferences.getInstance();
    _senderEmail = prefs.getString('senderEmail') ?? '';
    _senderPassword = prefs.getString('senderPassword') ?? '';
    print(
      'EmailSettingsProvider: Loaded - Email: $_senderEmail, Password: $_senderPassword',
    );
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    print(
      'EmailSettingsProvider: Saving - Email: $_senderEmail, Password: $_senderPassword',
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('senderEmail', _senderEmail);
    await prefs.setString('senderPassword', _senderPassword);
    print('EmailSettingsProvider: Settings saved.');
  }

  void updateSettings(String email, String password) {
    _senderEmail = email;
    _senderPassword = password;
    _saveSettings(); // Save settings immediately
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bulk Email Sender',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(), // Set SplashScreen as the initial home
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _fileName;
  List<List<dynamic>>? _fileData; // To store parsed data
  Map<String, int?> _columnMappings = {
    'Recipient Email': null,
    'Subject': null,
    'Body': null,
    'Attachments': null,
  };

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );

    if (result != null) {
      // print('File selected: ${result.files.single.name}'); // Removed old debug print
      PlatformFile file = result.files.single;
      setState(() {
        _fileName = file.name;
      });

      Uint8List? fileBytes;
      if (file.bytes != null) {
        fileBytes = file.bytes!;
        print('File bytes loaded directly from PlatformFile.');
      } else if (file.path != null) {
        try {
          File f = File(file.path!);
          fileBytes = await f.readAsBytes();
          print('File bytes loaded from file path: ${file.path}');
        } catch (e) {
          print('Error reading file from path: $e');
        }
      }

      if (fileBytes != null) {
        // print('File bytes are not null. Extension: ${file.extension}'); // Removed old debug print
        if (file.extension == 'csv') {
          _parseCsvFile(fileBytes);
        } else if (file.extension == 'xlsx') {
          _parseExcelFile(fileBytes);
        } else {
          print('Unsupported file extension: ${file.extension}');
        }
      } else {
        print('Could not get file bytes for ${file.name}');
      }
    } else {
      print('File picker canceled by user.');
      // User canceled the picker
    }
  }

  void _parseCsvFile(Uint8List bytes) {
    print('Parsing CSV file...');
    try {
      final String csvString = utf8.decode(bytes);
      List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter()
          .convert(csvString);
      setState(() {
        _fileData = rowsAsListOfValues;
      });
      print('CSV parsed successfully. Data rows: ${_fileData?.length}');
      _showColumnMappingDialog(rowsAsListOfValues);
    } catch (e) {
      print('Error parsing CSV: $e');
    }
  }

  void _parseExcelFile(Uint8List bytes) {
    print('Parsing Excel file...');
    try {
      var excel = Excel.decodeBytes(bytes);
      for (var table in excel.tables.keys) {
        var rowsAsListOfValues = excel.tables[table]!.rows
            .map((row) => row.map((cell) => cell?.value).toList())
            .toList();
        setState(() {
          _fileData = rowsAsListOfValues;
        });
        print(
          'Excel parsed successfully for sheet $table. Data rows: ${_fileData?.length}',
        );
        _showColumnMappingDialog(rowsAsListOfValues);
        break; // Assuming we only care about the first sheet for now
      }
    } catch (e) {
      print('Error parsing Excel: $e');
    }
  }

  void _showColumnMappingDialog(List<List<dynamic>> data) {
    if (data.isEmpty) {
      print('No data to map columns.');
      return;
    }

    List<String> columns = data[0].map((e) => e.toString()).toList();
    Map<String, int?> currentSelections = Map.from(_columnMappings);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Map Columns'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ['Recipient Email', 'Subject', 'Body', 'Attachments']
                  .map(
                    (field) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: DropdownButtonFormField<int?>(
                        decoration: InputDecoration(
                          labelText: field,
                          border: const OutlineInputBorder(),
                        ),
                        value: currentSelections[field],
                        items:
                            [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Select Column'),
                              ),
                            ] +
                            columns
                                .asMap()
                                .entries
                                .map(
                                  (entry) => DropdownMenuItem<int?>(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                                )
                                .toList(),
                        onChanged: (int? newValue) {
                          setState(() {
                            currentSelections[field] = newValue;
                          });
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Save Mappings'),
              onPressed: () {
                setState(() {
                  _columnMappings = currentSelections;
                });
                print('Column Mappings Saved: $_columnMappings');
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final emailSettings = Provider.of<EmailSettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showSettingsDialog(context, emailSettings);
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.upload_file,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 20),
                      if (_fileName != null)
                        Text(
                          'File Selected: $_fileName',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                        )
                      else
                        Text(
                          'Upload your CSV or Excel file to start',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Browse Files'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                          textStyle: const TextStyle(fontSize: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      if (_fileName != null &&
                          _columnMappings['Recipient Email'] != null &&
                          _columnMappings['Subject'] != null &&
                          _columnMappings['Body'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: ElevatedButton.icon(
                            onPressed: _sendBulkEmails,
                            icon: const Icon(Icons.send),
                            label: const Text('Send Emails'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                              textStyle: const TextStyle(fontSize: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendBulkEmails() async {
    print('Initiating bulk email sending...');

    final emailSettings = Provider.of<EmailSettingsProvider>(
      context,
      listen: false,
    );

    if (emailSettings.senderEmail.isEmpty ||
        emailSettings.senderPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set sender email and password in settings.'),
        ),
      );
      print('Error: Sender email or password not set.');
      return;
    }

    if (_fileData == null || _fileData!.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid data to send emails.')),
      );
      print('Error: No valid file data to send emails.');
      return;
    }

    if (_columnMappings['Recipient Email'] == null ||
        _columnMappings['Subject'] == null ||
        _columnMappings['Body'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete column mappings.')),
      );
      print('Error: Incomplete column mappings.');
      return;
    }

    final smtpServer = SmtpServer(
      'smtp.gmail.com', // Example SMTP server, replace with yours
      port: 587,
      username: emailSettings.senderEmail,
      password: emailSettings.senderPassword,
      ssl: false,
      // ignoreBadCert: true, // Removed unsupported parameter
    );

    int emailsSent = 0;
    int emailsFailed = 0;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting email sending process...')),
    );

    // Start from index 1 to skip header row
    for (int i = 1; i < _fileData!.length; i++) {
      final row = _fileData![i];
      try {
        final recipientEmail = row[_columnMappings['Recipient Email']!]
            .toString();
        final subject = row[_columnMappings['Subject']!].toString();
        final body = row[_columnMappings['Body']!].toString();
        final attachmentPath = _columnMappings['Attachments'] != null
            ? row[_columnMappings['Attachments']!].toString()
            : null;

        final message =
            Message() // Corrected instantiation
              ..from = Address(emailSettings.senderEmail, 'Bulk Email App')
              ..recipients.add(recipientEmail)
              ..subject = subject
              ..text = body;

        if (attachmentPath != null && attachmentPath.isNotEmpty) {
          final attachmentFile = File(attachmentPath);
          if (await attachmentFile.exists()) {
            message.attachments.add(FileAttachment(attachmentFile));
          } else {
            print('Warning: Attachment file not found: $attachmentPath');
          }
        }

        try {
          await send(message, smtpServer); // Use global send function
          emailsSent++;
          print('Email sent successfully to $recipientEmail');
        } on MailerException catch (e) {
          emailsFailed++;
          print('Failed to send email to $recipientEmail: ${e.message}');
          for (var p in e.problems) {
            print('Problem: ${p.code}: ${p.msg}');
          }
        }
      } catch (e) {
        emailsFailed++;
        print(
          'Failed to send email to ${row[_columnMappings['Recipient Email']!]}: $e',
        );
      }
    }

    // The send function handles closing its own connection, so no need for client.close()

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Emails sent: $emailsSent, Failed: $emailsFailed'),
      ),
    );
    print(
      'Bulk email sending complete. Sent: $emailsSent, Failed: $emailsFailed',
    );
  }

  void _showSettingsDialog(
    BuildContext context,
    EmailSettingsProvider emailSettings,
  ) {
    print(
      '_showSettingsDialog: Initializing with Email: ${emailSettings.senderEmail}, Password: ${emailSettings.senderPassword}',
    );
    final TextEditingController emailController = TextEditingController(
      text: emailSettings.senderEmail,
    );
    final TextEditingController passwordController = TextEditingController(
      text: emailSettings.senderPassword,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Email Settings'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Sender Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'App Password / API Key',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                emailSettings.updateSettings(
                  emailController.text,
                  passwordController.text,
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
