/// Absolute route patterns, also used as names for named navigation.
abstract final class RouteNames {
  static const login = '/login';
  static const otp = '/otp';
  static const onboarding = '/onboarding';
  static const orders = '/orders';
  static const orderDetails = '/orders/:id';
  static const deliveryDetails = '/orders/:id/delivery';
  static const inventory = '/inventory';
  static const addProduct = '/inventory/add';
  static const manageStock = '/inventory/:id/stock';
  static const settings = '/settings';
}
