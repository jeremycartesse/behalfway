module OffersHelper
  def departure_css_class_name(filter)
    return "active" if filter == @filters[:departure_time_there]
  end

  def arrival_css_class_name(filter)
    return "active" if filter == @filters[:arrival_time_back]
  end

  def price_difference_styling(price1, price2)
    if price2 > price1
      return "#239422"
    elsif price1 > price2
      return "red"
    else
      return "black"
    end
  end

  def price_difference_text(price1, price2)
    if price2 > price1
      "Save €#{(price2 - price1).round}"
    elsif price1 > price2
      "Add €#{(price1 - price2).round}"
    else
      "Same price"
    end
  end

  def background_color_option(index)
    if index.odd?
      return "pink-background"
    end
  end
end
#What is this helper ?  it is only for design ?
