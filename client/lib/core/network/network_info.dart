import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Abstract network info interface
abstract class NetworkInfo {
  /// Check if device is connected to internet
  Future<bool> get isConnected;

  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged;

  /// Get current connection type
  Future<ConnectionType> get connectionType;

  /// Check actual internet connectivity (not just network)
  Future<bool> checkInternetAccess();
}

/// Connection type enum
enum ConnectionType {
  wifi,
  mobile,
  ethernet,
  vpn,
  bluetooth,
  other,
  none,
}

/// Network info implementation using connectivity_plus
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;
  final SharedPreferences _prefs;

  // Stream controller for connectivity changes
  StreamController<bool>? _connectivityController;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  NetworkInfoImpl(this._connectivity, this._prefs) {
    _initConnectivityStream();
  }

  /// Initialize connectivity stream
  void _initConnectivityStream() {
    _connectivityController = StreamController<bool>.broadcast();

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (result) {
        _updateConnectivity(result);
      },
      onError: (error) {
        debugPrint('Connectivity error: $error');
        _connectivityController?.add(false);
      },
    );
  }

  void _updateConnectivity(ConnectivityResult result) {
    final isConnected = _checkConnectivity(result);
    final isForcedOffline =
        _prefs.getBool(AppConstants.offlineModeKey) ?? false;

    _connectivityController?.add(isConnected && !isForcedOffline);
  }

  @override
  Future<bool> get isConnected async {
    try {
      final isForcedOffline =
          _prefs.getBool(AppConstants.offlineModeKey) ?? false;
      if (isForcedOffline) return false;

      final result = await _connectivity.checkConnectivity();
      return _checkConnectivity(result);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return _connectivityController?.stream ?? const Stream.empty();
  }

  @override
  Future<ConnectionType> get connectionType async {
    try {
      final isForcedOffline =
          _prefs.getBool(AppConstants.offlineModeKey) ?? false;
      if (isForcedOffline) return ConnectionType.none;

      final result = await _connectivity.checkConnectivity();
      return _mapConnectionType(result);
    } catch (e) {
      debugPrint('Error getting connection type: $e');
      return ConnectionType.none;
    }
  }

  @override
  Future<bool> checkInternetAccess() async {
    final isForcedOffline =
        _prefs.getBool(AppConstants.offlineModeKey) ?? false;
    if (isForcedOffline) return false;

    // First check network connectivity
    if (!await isConnected) {
      return false;
    }

    // Then verify actual internet access by trying to reach a reliable host
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 2));

      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (e) {
      debugPrint('Error checking internet access: $e');
      return false;
    }
  }

  /// Check if any connectivity result indicates connection
  bool _checkConnectivity(ConnectivityResult result) {
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn;
  }

  /// Map connectivity results to connection type
  ConnectionType _mapConnectionType(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return ConnectionType.wifi;
      case ConnectivityResult.ethernet:
        return ConnectionType.ethernet;
      case ConnectivityResult.vpn:
        return ConnectionType.vpn;
      case ConnectivityResult.mobile:
        return ConnectionType.mobile;
      case ConnectivityResult.bluetooth:
        return ConnectionType.bluetooth;
      case ConnectivityResult.other:
        return ConnectionType.other;
      case ConnectivityResult.none:
        return ConnectionType.none;
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController?.close();
  }
}

/// Network status listener mixin for widgets/blocs
mixin NetworkStatusListener {
  StreamSubscription<bool>? _networkSubscription;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  /// Start listening to network changes
  void startNetworkListener(NetworkInfo networkInfo) {
    // Get initial status
    networkInfo.isConnected.then((connected) {
      _isOnline = connected;
      onNetworkStatusChanged(connected);
    });

    // Listen for changes
    _networkSubscription =
        networkInfo.onConnectivityChanged.listen((connected) {
      if (_isOnline != connected) {
        _isOnline = connected;
        onNetworkStatusChanged(connected);
      }
    });
  }

  /// Stop listening to network changes
  void stopNetworkListener() {
    _networkSubscription?.cancel();
    _networkSubscription = null;
  }

  /// Override this to handle network status changes
  void onNetworkStatusChanged(bool isConnected);
}

/// Network aware widget wrapper
class NetworkAwareBuilder extends StatefulWidget {
  final NetworkInfo networkInfo;
  final Widget Function(BuildContext context, bool isConnected) builder;
  final Widget? offlineWidget;
  final void Function(bool isConnected)? onStatusChanged;

  const NetworkAwareBuilder({
    super.key,
    required this.networkInfo,
    required this.builder,
    this.offlineWidget,
    this.onStatusChanged,
  });

  @override
  State<NetworkAwareBuilder> createState() => _NetworkAwareBuilderState();
}

class _NetworkAwareBuilderState extends State<NetworkAwareBuilder> {
  bool _isConnected = true;
  StreamSubscription<bool>? _subscription;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
    _listenToChanges();
  }

  void _checkInitialStatus() async {
    final isConnected = await widget.networkInfo.isConnected;
    if (mounted && isConnected != _isConnected) {
      setState(() => _isConnected = isConnected);
    }
  }

  void _listenToChanges() {
    _subscription =
        widget.networkInfo.onConnectivityChanged.listen((isConnected) {
      if (mounted && isConnected != _isConnected) {
        setState(() => _isConnected = isConnected);
        widget.onStatusChanged?.call(isConnected);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected && widget.offlineWidget != null) {
      return widget.offlineWidget!;
    }
    return widget.builder(context, _isConnected);
  }
}

/// Offline banner widget
class OfflineBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const OfflineBanner({
    super.key,
    this.message = 'No internet connection',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.red.shade700,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(
              Icons.wifi_off,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('RETRY'),
              ),
          ],
        ),
      ),
    );
  }
}

