# An API agnostic version of QPXTripOption we use to refer inside of Offer.
# A converter class. Use more initialization options with different APIs later
class RoundTrip < ApplicationRecord
attr_reader :price, :destination_city, :destination_airport,
              :origin_airport, :departure_time_there, :arrival_time_there,
              :departure_time_back, :arrival_time_back, :currency, :carrier, :trip_id,
              :flight_number_there, :flight_number_back

  def initialize(args={})
    #why are you unless fonction?
    #What is the QPXTripOption ?
    #What is qpx :qpx_trip_option?
    #what is really args ??
      unless args[:qpx_trip_option].nil?
        qpx = args[:qpx_trip_option]
        @currency = qpx.currency
        @price = qpx.price
        @destination_city = qpx.destination_city
        @destination_airport = qpx.destination_airport
        @origin_airport = qpx.origin_airport
        @departure_time_there = qpx.departure_time_there
        @arrival_time_there = qpx.arrival_time_there
        @departure_time_back = qpx.departure_time_back
        @arrival_time_back = qpx.arrival_time_back
        @carrier = qpx.carrier
        @flight_number_there = qpx.flight_number_there
        @flight_number_back = qpx.flight_number_back
        @trip_id = qpx.trip_id
      end
    end
end
