class ApiConfig {
  static const String baseUrl = 'https://web-production-9625a.up.railway.app';
  static const String wsUrl = 'wss://web-production-9625a.up.railway.app';

  // User Module
  static String get register => '$baseUrl/auth/register';
  static String get login => '$baseUrl/auth/login';
  static String get profile => '$baseUrl/auth/profile';

  // Bus Management
  static String get searchBuses => '$baseUrl/buses';
  static String get createBus => '$baseUrl/buses';
  static String busById(String busId) => '$baseUrl/buses/$busId';
  static String busStops(String busId) => '$baseUrl/buses/$busId/stops';

  // Booking Management
  static String get createBookingRequest => '$baseUrl/booking/request';
  static String bookingById(String bookingId) => '$baseUrl/booking/$bookingId';
  static String get getMyBookings => '$baseUrl/booking/my-requests';
  static String get getBookingRequests => '$baseUrl/booking/requests';
  static String get acceptBooking => '$baseUrl/booking/accept';
  static String get rejectBooking => '$baseUrl/booking/reject';
  static String get cancelBooking => '$baseUrl/booking/cancel';
  static String get confirmTicket => '$baseUrl/booking/ticket/confirm';
  static String get getMyTickets => '$baseUrl/booking/tickets/mine';
  static String get cancelTicket => '$baseUrl/booking/ticket/cancel';

  // Owner Dashboard
  static String get ownerDashboard => '$baseUrl/owner/dashboard';
  static String get ownerBuses => '$baseUrl/owner/buses';
  static String get ownerTickets => '$baseUrl/owner/tickets';
  static String get ownerSupervisors => '$baseUrl/owner/supervisors';
  static String get registerSupervisor => '$baseUrl/owner/register-supervisor';
  static String get ownerBookings => '$baseUrl/owner/bookings';
  static String get ownerRevenueSummary => '$baseUrl/owner/revenue-summary';

  // Location Services
  static String updateBusLocation(String busId) => '$baseUrl/location/bus/$busId/update';
  static String getBusLocation(String busId) => '$baseUrl/location/bus/$busId';
  static String getEtaToBoardingPoint(String busId, String boardingPointId) =>
      '$baseUrl/location/bus/$busId/eta/$boardingPointId';
  static String getNearbyPlaces(String boardingPointId) =>
      '$baseUrl/location/boarding-points/$boardingPointId/nearby';
  static String get geocodeAddress => '$baseUrl/location/geocode';
  static String getBusRoute(String busId) => '$baseUrl/location/route/$busId';

  // Real-Time (WebSocket)
  static String get bookingWebSocket => '$wsUrl/ws/booking';
  static String locationWebSocket(String busId) => '$wsUrl/ws/location/$busId';
}
