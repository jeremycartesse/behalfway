# Airport list: %w(PAR LON ROM MAD BER BRU VCE AMS LIS BCN MIL VIE)

class OffersController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :disable_browser_cache, only: :show
  before_action :assert_show_params, only: :show
  before_action :assert_index_params, only: :index

  def show
    options = extract_options_from_stamp(params[:stamp])
    # All offers for one route sorted by price
    @offers = Avion::SmartQPXAgent.new(options).obtain_offers.sort_by { |offer| offer.total }
    @offer = @offers[params[:start].to_i]
    # extract two arrays of roundtrips, one from each city to destination
    @trips_a = @offers.reduce([]) {|a, e| a << e.roundtrips.first }.uniq { |t| t.trip_id }
    @trips_b = @offers.reduce([]) {|a, e| a << e.roundtrips.last }.uniq { |t| t.trip_id }
    @trip_a = @trips_a[params[:left].to_i] # set the first roundtrip from city A
    @trip_b = @trips_b[params[:right].to_i] # set the second roundtrip from city B
  end

  def index
    airports = Constants::AIRPORTS.keys
    date_there = params[:date_there]
    date_back = params[:date_back]

    # generate routes
    routes = Avion.generate_triple_routes(airports, params[:origin_a], params[:origin_b])
    # Test all routes against cache
    uncached_routes = Avion.compare_routes_against_cache(routes, date_there, date_back)

    # Do we have something that is not cached?
    if uncached_routes.empty?
      # This won't do any requests as we work with cache
      @offers = get_offers_for_routes(routes, date_there, date_back)
      # clone unfiltered results to check against later
      @unfiltered_offers = @offers.clone
      # do filtering
      apply_index_filters
      # remove duplicate cities
      @offers = @offers.uniq { |offer| offer.destination_city }
      # and sort by total price
      @offers = @offers.sort_by { |offer| offer.total }
    else # we have to build a new cache
      # save url to redirect back from wait.html.erb via JS
      session[:url_for_wait] = request.original_url
      # render wait view without any routing
      render :wait
      # Send requests and build the cache in the background
      QueryRoutesJob.perform_later(uncached_routes, date_there, date_back)
    end
    session[:search_url] = request.original_url
  end

  private

  def get_offers_for_routes(routes, date_there, date_back)
    offers = []
    # This won't do any API requests at all as we work only with cache
    routes.each do |route|
      options = {
        origin_a: route.first,
        origin_b: route[1],
        destination_city: route.last,
        date_there: date_there,
        date_back: date_back
      }
      offers.concat(Avion::SmartQPXAgent.new(options).obtain_offers)
    end
    return offers
  end

  def apply_index_filters
    # set filters
    @filters = params.to_hash.slice("origin_a", "date_there", "date_back", "origin_b")

    # filter by departure time if asked
    if params["departure_time_there"].present? && params["departure_time_there"] != ""
      @filters = @filters.merge(departure_time_there: params[:departure_time_there])
      @offers = filter_by_departure_time(@offers)
    end

    #filter by arrival time if asked
    if params["arrival_time_back"].present? && params["arrival_time_back"] != ""
      @filters = @filters.merge(arrival_time_back: params[:arrival_time_back])
      @offers = filter_by_arrival_time(@offers)
    end
  end

  def assert_show_params
    # safeguard agains random urls starting with offers/
    unless params[:stamp] =~ /\w{3}_\w{3}_\w{3}_\d{4}-\d{2}-\d{2}_\d{4}-\d{2}-\d{2}/
      redirect_to root_path
      return
    end
    # Don't bother making requests if corresponding stamp not found in cache
    if $redis.get(params[:stamp]).nil?
      redirect_to root_path
      return
    end
  end

  def assert_index_params
    # if there are no query params in URL or they don't make sense - send user to home page
    if URI(request.original_url).query.blank? || params_fail?
      redirect_to root_path
      return
    end
  end

  def disable_browser_cache
    # do not cache the page to avoid caching waiting animation
    response.headers['Cache-Control'] = "no-cache, max-age=0, must-revalidate, no-store"
  end

  def extract_options_from_stamp(stamp)
    from_stamp = params[:stamp].split('_')
    {
      origin_a: from_stamp.first,
      origin_b: from_stamp[1],
      destination_city: from_stamp[2],
      date_there: from_stamp[3],
      date_back: from_stamp.last
    }
  end

  # TODO: verify if date_there is not later than date_back
  def params_fail?
    params[:origin_a].blank? || params[:origin_b].blank? || params[:date_there].blank? || params[:date_back].blank?
  end

  def departure_time_choice
    if params[:departure_time_there] == "earlybird"
      return [5,8]
    elsif params[:departure_time_there] == "morning"
      return [8,12]
    elsif params[:departure_time_there] == "afternoon"
      return [12,18]
    elsif params[:departure_time_there] == "afterwork"
      return [18,24]
    end
  end

  def arrival_time_choice
    if params[:arrival_time_back] == "earlybird"
      return [5,8]
    elsif params[:arrival_time_back] == "morning"
      return [8,12]
    elsif params[:arrival_time_back] == "afternoon"
      return [12,18]
    elsif params[:arrival_time_back] == "evening"
      return [18,24]
    end
  end

  def departure_range
    departure_as_date = Time.new(Time.parse(params[:date_there]).to_a[5],Time.parse(params[:date_there]).to_a[4],Time.parse(params[:date_there]).to_a[3])
    (departure_as_date + departure_time_choice.first.hours .. departure_as_date + departure_time_choice.last.hours)
  end

  def arrival_range
    arrival_as_date = Time.new(Time.parse(params[:date_back]).to_a[5],Time.parse(params[:date_back]).to_a[4],Time.parse(params[:date_back]).to_a[3])
    (arrival_as_date + arrival_time_choice.first.hours .. arrival_as_date + arrival_time_choice.last.hours)
  end

  def filter_by_departure_time(offers)
    offers.select { |offer|
      departure_range.include?(offer.roundtrips.first.departure_time_there) && departure_range.include?(offer.roundtrips.last.departure_time_there)
    }
  end

  def filter_by_arrival_time(offers)
    offers.select { |offer|
      arrival_range.include?(offer.roundtrips.first.arrival_time_back) && arrival_range.include?(offer.roundtrips.last.arrival_time_back)
    }
  end
end
