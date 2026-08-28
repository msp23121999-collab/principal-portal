// ignore_for_file: deprecated_member_use, unused_element, unused_field, prefer_final_fields
import 'package:flutter/material.dart';
import '../models/app_state.dart';

class TransportScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const TransportScreen({super.key, this.onNavigate});

  @override
  State<TransportScreen> createState() => _TransportScreenState();
}

class _TransportScreenState extends State<TransportScreen> {
  bool _showRouteChangeForm = false;

  String? _selectedRoute = '-- Select Route --';
  String? _selectedStop = '-- Select Stop --';
  final _reasonController = TextEditingController();

  final List<String> _routes = [
    '-- Select Route --',
    'Route 01 - Anna Nagar',
    'Route 04 - Tambaram',
    'Route 08 - Porur',
    'Route 12 - Velachery',
    'Route 15 - Adyar',
  ];

  final List<String> _stops = [
    '-- Select Stop --',
    'Anna Nagar Roundtana',
    'Koyambedu Bus Stand',
    'Porur Junction',
    'Tambaram Railway Station',
    'Velachery Checkpost',
  ];

  void _submitRouteChangeRequest() {
    setState(() {
      _showRouteChangeForm = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Route change request submitted successfully to Bus Coordinator!'),
        backgroundColor: Color(0xFF0D9488),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final pass = appState.studentTransportPass;
    final busId = pass?['bus_id']?.toString() ?? '';
    Map<String, dynamic>? bus;
    if (busId.isNotEmpty && appState.transportBuses.isNotEmpty) {
      bus = appState.transportBuses.firstWhere(
        (b) => b['id']?.toString() == busId,
        orElse: () => appState.transportBuses.first,
      );
    } else if (appState.transportBuses.isNotEmpty) {
      bus = appState.transportBuses.first;
    }

    final routeName = bus?['route_name']?.toString() ?? bus?['route_no']?.toString() ?? 'Route 04 - Tambaram';
    final stopName = pass?['stop_name']?.toString() ?? 'Koyambedu Junction';
    final busNo = bus?['bus_no']?.toString() ?? 'TN 37 B 4521';
    final pickupTime = bus?['pickup_time']?.toString() ?? '07:30 AM';
    final driverName = bus?['driver_name']?.toString() ?? 'M. Murugan';
    final driverPhone = bus?['driver_phone']?.toString() ?? '9876543210';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Main Card: ALLOTTED TRANSPORT DETAILS
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Header Row
                LayoutBuilder(builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 650;
                  final titleCol = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        children: const [
                          Text(
                            'ALLOTTED ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'TRANSPORT DETAILS',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF4338CA),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'REAL-TIME STATUS SYNCED FROM BUS COORDINATOR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  );

                  final btn = OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showRouteChangeForm = !_showRouteChangeForm;
                      });
                    },
                    icon: Icon(
                      _showRouteChangeForm ? Icons.close : Icons.sync_alt,
                      size: 16,
                      color: const Color(0xFF2563EB),
                    ),
                    label: Text(
                      _showRouteChangeForm ? 'CLOSE FORM' : 'ROUTE CHANGE',
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      side: const BorderSide(color: Color(0xFFDBEAFE)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: const Color(0xFFEFF6FF),
                    ),
                  );

                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleCol,
                        const SizedBox(height: 14),
                        btn,
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: titleCol),
                      const SizedBox(width: 12),
                      btn,
                    ],
                  );
                }),
                const SizedBox(height: 28),

                // 4 Detail Box Cards Row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double width = constraints.maxWidth;
                    final int crossAxisCount = width > 1100 ? 4 : (width > 650 ? 2 : 1);
                    final double ratio = width > 1100 ? 2.2 : (width > 650 ? 2.5 : 3.0);

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: ratio,
                      children: [
                        _buildDetailBox(
                          label: 'ROUTE NAME',
                          value: routeName,
                          valueColor: const Color(0xFF0F172A),
                        ),
                        _buildDetailBox(
                          label: 'YOUR STOP',
                          value: stopName,
                          valueColor: const Color(0xFF0F172A),
                        ),
                        _buildDetailBox(
                          label: 'BUS NUMBER',
                          value: busNo,
                          valueColor: const Color(0xFF4338CA),
                        ),
                        _buildDetailBox(
                          label: 'BOARDING TIME',
                          value: pickupTime,
                          valueColor: const Color(0xFF0F172A),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Route Change Request Box (Displayed when ROUTE CHANGE is clicked)
          if (_showRouteChangeForm) ...[
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text(
                        'SUBMIT ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'ROUTE CHANGE REQUEST',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF0D9488),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'SUBMIT ROUTE/STOP TRANSITION TO BUS COORDINATOR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Route & Boarding Stop Selectors Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SELECT NEW ROUTE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedRoute,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                                  items: _routes.map((r) {
                                    return DropdownMenuItem<String>(
                                      value: r,
                                      child: Text(
                                        r,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: r.startsWith('--') ? FontWeight.bold : FontWeight.w500,
                                          color: r.startsWith('--') ? const Color(0xFF0F172A) : const Color(0xFF334155),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedRoute = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SELECT BOARDING STOP',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedStop,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                                  items: _stops.map((s) {
                                    return DropdownMenuItem<String>(
                                      value: s,
                                      child: Text(
                                        s,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: s.startsWith('--') ? FontWeight.bold : FontWeight.w500,
                                          color: s.startsWith('--') ? const Color(0xFF94A3B8) : const Color(0xFF334155),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedStop = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Reason text field
                  const Text(
                    'REASON FOR ROUTE CHANGE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Please describe why you need this route or stop adjustment...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.4),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF0D9488)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Submit button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _submitRouteChangeRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6EE7B7), // Mint green as per image
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'SUBMIT REQUEST',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Driver & Coordinator Contact Details Card
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person_pin_circle_outlined, color: Color(0xFF2563EB), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'BUS DRIVER & COORDINATOR DETAILS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Contact details of driver and transport coordinator assigned to your route',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double width = constraints.maxWidth;
                    final isDesktop = width > 750;

                    return Flex(
                      direction: isDesktop ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Driver Info Card
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: const Color(0xFFDBEAFE),
                                  child: const Icon(Icons.directions_bus, color: Color(0xFF2563EB), size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'ASSIGNED BUS DRIVER',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF64748B),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        driverName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.phone, size: 14, color: Color(0xFF16A34A)),
                                          const SizedBox(width: 6),
                                          Text(
                                            '+91 $driverPhone',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF16A34A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isDesktop) const SizedBox(width: 20) else const SizedBox(height: 16),

                        // Transport Coordinator Info Card
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: const Color(0xFFFEE2E2),
                                  child: const Icon(Icons.support_agent, color: Color(0xFFE11D48), size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'TRANSPORT COORDINATOR',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF64748B),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Prof. S. Ranganathan',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: const [
                                          Icon(Icons.phone, size: 14, color: Color(0xFFE11D48)),
                                          SizedBox(width: 6),
                                          Text(
                                            '+91 9443210987',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFFE11D48),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBox({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
