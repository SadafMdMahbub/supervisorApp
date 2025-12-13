/// A centralized configuration class for managing all API endpoints and base URLs.
/// This class provides a single source of truth for all network requests.
class ApiConfig {
  /// The base URL for all REST API endpoints.
  static const String baseUrl = 'https://web-production-9625a.up.railway.app';
  
  /// The base URL for all WebSocket connections.
  static const String wsUrl = 'wss://web-production-9625a.up.railway.app';

  // User Module
  /// Endpoint to register a new user.
  static String get register => '$baseUrl/auth/register';
  /// Endpoint for user login.
  static String get login => '$baseUrl/auth/login';
  /// Endpoint to fetch the user's profile.
  static String get profile => '$baseUrl/auth/profile';

  // Bus Management
  /// Endpoint to search for buses.
  static String get searchBuses => '$baseUrl/buses';
  /// Endpoint to create a new bus.
  static String get createBus => '$baseUrl/buses';
  /// Endpoint to fetch a bus by its ID.
  static String busById(String busId) => '$baseUrl/buses/$busId';
  /// Endpoint to get the stops for a specific bus.
  static String busStops(String busId) => '$baseUrl/buses/$busId/stops';

  // Booking Management
  /// Endpoint to create a new booking request.
  static String get createBookingRequest => '$baseUrl/booking/request';
  /// Endpoint to fetch a booking by its ID.
  static String bookingById(String bookingId) => '$baseUrl/booking/$bookingId';
  /// Endpoint for a user to get their own booking requests.
  static String get getMyBookings => '$baseUrl/booking/my-requests';
  /// Endpoint for a supervisor to get booking requests for a bus.
  static String get getBookingRequests => '$baseUrl/booking/requests';
  /// Endpoint to accept a booking request.
  static String get acceptBooking => '$baseUrl/booking/accept';
  /// Endpoint to reject a booking request.
  static String get rejectBooking => '$baseUrl/booking/reject';
  /// Endpoint to cancel a booking.
  static String get cancelBooking => '$baseUrl/booking/cancel';
  /// Endpoint to confirm a ticket.
  static String get confirmTicket => '$baseUrl/booking/ticket/confirm';
  /// Endpoint for a user to get their own tickets.
  static String get getMyTickets => '$baseUrl/booking/tickets/mine';
  /// Endpoint to cancel a ticket.
  static String get cancelTicket => '$baseUrl/booking/ticket/cancel';

  // Owner Dashboard
  /// Endpoint for the owner's main dashboard.
  static String get ownerDashboard => '$baseUrl/owner/dashboard';
  /// Endpoint for an owner to get their buses.
  static String get ownerBuses => '$baseUrl/owner/buses';
  /// Endpoint for an owner to get tickets.
  static String get ownerTickets => '$baseUrl/owner/tickets';
  /// Endpoint for an owner to get their supervisors.
  static String get ownerSupervisors => '$baseUrl/owner/supervisors';
  /// Endpoint for an owner to register a new supervisor.
  static String get registerSupervisor => '$baseUrl/owner/register-supervisor';
  /// Endpoint for an owner to get bookings.
  static String get ownerBookings => '$baseUrl/owner/bookings';
  /// Endpoint for an owner to get a revenue summary.
  static String get ownerRevenueSummary => '$baseUrl/owner/revenue-summary';

  // Location Services
  /// Endpoint to update the location of a bus.
  static String updateBusLocation(String busId) => '$baseUrl/location/bus/$busId/update';
  /// Endpoint to get the location of a bus.
  static String getBusLocation(String busId) => '$baseUrl/location/bus/$busId';
  /// Endpoint to get the estimated time of arrival (ETA) to a boarding point.
  static String getEtaToBoardingPoint(String busId, String boardingPointId) =>
      '$baseUrl/location/bus/$busId/eta/$boardingPointId';
  /// Endpoint to get nearby places for a boarding point.
  static String getNearbyPlaces(String boardingPointId) =>
      '$baseUrl/location/boarding-points/$boardingPointId/nearby';
  /// Endpoint for geocoding an address.
  static String get geocodeAddress => '$baseUrl/location/geocode';
  /// Endpoint to get the route of a bus.
  static String getBusRoute(String busId) => '$baseUrl/location/route/$busId';

  // Real-Time (WebSocket)
  /// WebSocket endpoint for real-time booking updates.
  static String get bookingWebSocket => '$wsUrl/ws/booking';
  /// WebSocket endpoint for real-time location updates for a specific bus.
  static String locationWebSocket(String busId) => '$wsUrl/ws/location/$busId';
}
