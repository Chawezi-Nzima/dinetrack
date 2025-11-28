import 'supabase_service.dart';

class OrderService {
  final SupabaseService _supabase = SupabaseService();

  Stream<List<Map<String, dynamic>>> watchEstablishmentOrders(String establishmentId) {
    return _supabase.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('establishment_id', establishmentId)
        .order('created_at', ascending: false);
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    final response = await _supabase.client
        .from('orders')
        .insert(orderData)
        .select()
        .single();

    return response;
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _supabase.client
        .from('orders')
        .update({'status': status})
        .eq('id', orderId);
  }
}