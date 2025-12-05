// browser_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BrowserPage extends StatefulWidget {
  const BrowserPage({super.key});

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  bool _isScanning = false;
  bool _processingScan = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      formats: [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.noDuplicates,
      detectionTimeoutMs: 500,
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _toggleScan() {
    setState(() {
      _isScanning = !_isScanning;
    });
  }

  void _onQRCodeDetect(BarcodeCapture capture) {
    if (_processingScan) return;

    setState(() {
      _processingScan = true;
    });

    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String code = barcodes.first.rawValue ?? '';

      // Close scanner first
      setState(() {
        _isScanning = false;
      });

      // Process the scanned QR code
      _processScannedQR(code);
    }

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _processingScan = false;
        });
      }
    });
  }

  void _processScannedQR(String code) {
    // Show processing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('QR Code Detected'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Processing: ${code.length > 50 ? '${code.substring(0, 50)}...' : code}',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    // Simulate processing delay
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context); // Close processing dialog

      // Parse QR code format
      if (code.startsWith('restaurant:')) {
        final restaurantId = code.replaceFirst('restaurant:', '');
        _navigateToRestaurant(restaurantId);
      } else if (code.startsWith('table:')) {
        final tableInfo = code.replaceFirst('table:', '');
        final parts = tableInfo.split(':');
        if (parts.length >= 2) {
          final restaurantId = parts[0];
          final tableId = parts[1];
          _navigateToRestaurantTable(restaurantId, tableId);
        } else {
          _showQRResult(code);
        }
      } else if (code.startsWith('menu:')) {
        final menuId = code.replaceFirst('menu:', '');
        _navigateToMenu(menuId);
      } else {
        _showQRResult(code);
      }
    });
  }

  void _showQRResult(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code Scanned'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Scanned Content:'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  code,
                  style: const TextStyle(fontFamily: 'Monospace'),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Note: This QR code doesn\'t match expected DineTrack formats.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (Uri.tryParse(code)?.hasAbsolutePath ?? false)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Open URL in browser
              },
              child: const Text('Open URL'),
            ),
        ],
      ),
    );
  }

  void _navigateToRestaurant(String restaurantId) {
    // TODO: Implement navigation to restaurant details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Restaurant ID: $restaurantId'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'VIEW',
          onPressed: () {
            // TODO: Navigate to restaurant
          },
        ),
      ),
    );
  }

  void _navigateToRestaurantTable(String restaurantId, String tableId) {
    // TODO: Implement navigation to table
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Table $tableId at Restaurant $restaurantId'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'ORDER',
          onPressed: () {
            // TODO: Navigate to menu/ordering
          },
        ),
      ),
    );
  }

  void _navigateToMenu(String menuId) {
    // TODO: Implement navigation to menu
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Menu ID: $menuId'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openBrowseRestaurants() {
    // TODO: Implement restaurant browsing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening restaurant browser...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _openFavorites() {
    // TODO: Implement favorites
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening favorites...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _openProfile() {
    // TODO: Implement profile
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening profile...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DineTrack'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _openProfile,
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isScanning ? _buildScannerView() : _buildMainView(),
    );
  }

  Widget _buildMainView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.restaurant_menu,
                      size: 60,
                      color: Color(0xFF4F46E5),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Welcome to DineTrack',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scan QR codes or browse restaurants',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // QR Scan Button
            SizedBox(
              height: 120,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: _toggleScan,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner,
                            size: 40,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Scan QR Code',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Scan restaurant or table QR codes',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Browse Restaurants Button
            SizedBox(
              height: 120,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: _openBrowseRestaurants,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.search,
                            size: 40,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Browse Restaurants',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Discover restaurants near you',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAction(
                  icon: Icons.favorite,
                  label: 'Favorites',
                  onTap: _openFavorites,
                ),
                _buildQuickAction(
                  icon: Icons.history,
                  label: 'History',
                  onTap: () {
                    // TODO: Implement history
                  },
                ),
                _buildQuickAction(
                  icon: Icons.location_on,
                  label: 'Nearby',
                  onTap: () {
                    // TODO: Implement nearby
                  },
                ),
                _buildQuickAction(
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: () {
                    // TODO: Implement settings
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Help Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to use DineTrack:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Scan a restaurant QR code to view menu and order\n'
                        '2. Scan a table QR code to order at your table\n'
                        '3. Browse restaurants to discover new places\n'
                        '4. Save your favorites for quick access',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: const Color(0xFF4F46E5)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _onQRCodeDetect,
          fit: BoxFit.cover,
        ),

        // Scanner overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 0.8,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Scanner frame
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF4F46E5),
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Instructions
                const Text(
                  'Align QR code within the frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                if (_processingScan)
                  const Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Processing QR code...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        // Close button
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 10,
          child: IconButton(
            onPressed: _toggleScan,
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.5),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ),

        // Torch button
        Positioned(
          bottom: 50,
          right: 20,
          child: FloatingActionButton(
            onPressed: () {
              _scannerController?.toggleTorch();
            },
            backgroundColor: Colors.black.withOpacity(0.5),
            child: const Icon(Icons.flash_on, color: Colors.white),
          ),
        ),
      ],
    );
  }
}