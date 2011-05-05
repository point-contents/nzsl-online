module SearchHelper
  # Sign Attribute Image Helpers
  
  def handshape_image number, main=false
    sign_attribute_image :handshape, number, main
  end
  
  def location_image number, main=false, label=false
    sign_attribute_image :location, number, main, label
  end
  
  def sign_attribute_image attribute, number, main, label=false
    classes = 'image ir rounded'
    classes << ' main_image' if main
    if attribute == :handshape
      classes << ' transition' unless main
      if main
        #if it's the first, just search on the first two numbers
        value = number.split('.')[0,2].join('.')
      else
        value = number
      end
    elsif main
      value = number.split('.')[0]
    else
      value = number.split('.')[1]
    end
    output = content_tag :div, value, {:style => "background-image:url('/images/#{attribute.to_s}s/#{attribute.to_s}.#{number.downcase.gsub(/[ \/]/, '_')}.png')", :class => classes}
    output << number.split('.').last if attribute == :location && label
    output
  end
  
  # Sign Attribute is Selected?
  
  def handshape_selected?(shape)
    if @query[:hs].present?
      query_hs = @query[:hs]
      # if it's the first, the search is just on the first two numbers
      query_hs = @query[:hs].map {|q| "#{q}.1"} if shape.split('.').last == '1'
      'selected' if query_hs.include?(shape)
    end
  end
  
  def location_selected?(location)
    'selected' if @query[:l].present? && @query[:l].include?(location.split('.')[1])
  end
  def location_group_selected?(location_group)
    'selected' if @query[:lg].present? && @query[:lg].include?(location_group.split('.')[0])
  end
  
  def selected_tab?(tab)
    keys = @query.select{|k,v| v.present? }.keys
    if %w(tag usage).any? {|k| keys.include?(k)} || (keys.include?('s') && keys.length > 1)
      'selected' if tab == :advanced
    elsif %w(hs l lg).any? {|k| keys.include?(k)}
      'selected' if tab == :signs
    else 
      'selected' if tab == :keywords
    end
  end
  
  def display_locations_search_term
    # reduce the list to the selected, turn them all into images. 
    Sign.locations.flatten.select{|l| location_selected?(l) }.map{|l| location_image l, false }.join(' ').html_safe unless @query[:l].blank?
  end
  def display_handshapes_search_term
    Sign.handshapes.flatten.flatten.select{|hs| handshape_selected?(hs) }.map{|hs| handshape_image hs, (hs.split('.').last == '1') }.join(' ').html_safe unless @query[:hs].blank?
  end
  def display_location_groups_search_term
    Sign.location_groups.select{|lg| location_group_selected?(lg)}.map{|lg| location_image lg, true }.join(' ').html_safe unless @query[:lg].blank?
  end
  def display_usage_tag_search_term
    # reduce the list to the selected
    h Sign.usage_tags.select{|u| @query[:usage].include?(u.last.to_s) }.map(&:first).join(' ') unless @query[:usage].blank?
  end
  def display_topic_tag_search_term
    h Sign.topic_tags.select{|u| @query[:tag].include?(u.last.to_s) }.map(&:first).join(' ') unless @query[:tag].blank?
  end

  def search_term(key)
    h @query[key].join(' ') unless @query[key].blank?
  end
end