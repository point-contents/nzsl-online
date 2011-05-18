class Sign

  require 'open-uri'
  require 'nokogiri'

  ELEMENT_NAME = 'entry'
  RESULTS_PER_PAGE = 9
  VIDEO_EXAMPLES_TOTAL = 4
  #Sign attributes
  attr_accessor :id, :video, :video_slow, :drawing, :handshape, :location_name,
                :gloss_main, :gloss_secondary, :gloss_minor, :gloss_maori, 
                :word_classes, :inflection, :contains_numbers, :is_fingerspelling, :is_directional, :is_locatable, :one_or_two_handed,
                :age_groups, :gender_groups, :hint, :usage_notes, :related_to, :usage,
                :examples
  # instance #
  def initialize(data = nil)
    if data
      self.id = data.value_for_tag('headwordid')
      self.video = "#{ASSET_URL}#{data.value_for_tag('ASSET glossmain')}"
      self.video_slow = "#{ASSET_URL}#{data.value_for_tag('ASSET glossmain_slow')}" if data.value_for_tag('ASSET glossmain_slow').present?
      self.drawing = data.value_for_tag('ASSET picture')
      self.handshape = data.value_for_tag('handshape')
      self.location_name = data.value_for_tag('location')
      
      #gloss
      self.gloss_main = data.value_for_tag('glossmain')
      self.gloss_secondary = data.value_for_tag('glosssecondary')
      self.gloss_minor = data.value_for_tag('gloss_minor')
      self.gloss_maori = data.value_for_tag('gloss_maori')
      
      #grammar
      self.word_classes = data.value_for_tag('SECONDARYWORDCLASS')
      self.inflection = data.value_for_tag('INFLECTION')
      self.contains_numbers = data.value_for_tag('number_incorp').to_bool
      self.is_fingerspelling = data.value_for_tag('fingerspelling').to_bool
      self.is_directional = data.value_for_tag('directional').to_bool
      self.is_locatable = data.value_for_tag('locatable').to_bool
      self.one_or_two_handed = data.value_for_tag('one_or_two_hand').to_bool
      
      #notes
      self.age_groups = data.value_for_tag('VARIATIONAGE')
      self.gender_groups = data.value_for_tag('VARIATIONGENDER')
      self.hint = data.value_for_tag('hint')
      self.usage = data.value_for_tag('usage')
      self.usage_notes = data.value_for_tag('essay')
      self.related_to = data.value_for_tag('RELATEDTO')
      
      #examples
      self.examples = []
      VIDEO_EXAMPLES_TOTAL.times do |i|
        if data.value_for_tag("ASSET finalexample#{i}").present?
          self.examples << {:transcription => parse_transcription(data, "videoexample#{i}"), 
                            :translation => data.value_for_tag("videoexample#{i}translation"),
                            :video => "#{ASSET_URL}#{data.value_for_tag("ASSET finalexample#{i}")}",
                            :video_slow => (data.value_for_tag("ASSET finalexample#{i}_slow").present? ? "#{ASSET_URL}#{data.value_for_tag("ASSET finalexample#{i}_slow")}" : nil)}
        end
      end
    end
    self
  end
  
  def inflection_temporal
    !!inflection.match('temporal')
  end
  
  def inflection_manner_and_degree
    !!inflection.match('manner')
  end
  
  def inflection_plural
    !!inflection.match('plural')
  end
  def borrowed_from
    related_to unless related_to == 'nzsl'
  end
  
  def location
    Sign.locations.flatten.find{|l|l.split('.')[2].downcase == location_name}
  end
  
  # class #
  
  def self.first(params)
    count, entries = self.search(params)
    return nil if entries.empty?
    Sign.new(entries.first)
  end

  def self.all(params)
    return self.all_with_count(params)[1]
  end
  
  def self.all_with_count(params)
    signs = []
    count, entries = self.search(params)
    entries.each do |entry|
      signs << Sign.new(entry)
    end
    return [count, signs]
  end
  
  def self.find(all_or_first = :first, params)
    if all_or_first == :all || all_or_first == :first
      self.send(all_or_first, params) 
    end
  end
  
  def self.random
    return self.first({:random => 1})
  end

  def self.paginate(search_query, page_number)
    start_index = RESULTS_PER_PAGE * (page_number - 1) + 1
    start_index = 1 if start_index < 1
    self.all_with_count(search_query.merge(:start => start_index, :num => RESULTS_PER_PAGE))
  end
  
  def self.current_page(per_page, last_result_index, all_result_length)
    ((last_result_index / all_result_length.to_f) * (all_result_length / per_page.to_f)).round
  end
  
  # MENUS
  def self.handshapes
    [[['1.1.1', '1.1.2', '1.1.3'], ['1.2.1', '1.2.2'], ['1.3.1', '1.3.2'], ['1.4.1']], 
     [['2.1.1', '2.1.2'], ['2.2.1', '2.2.2'], ['2.3.1', '2.3.2', '2.3.3'], ['8.1.1', '8.1.2', '8.1.3']], 
     [['3.1.1'], ['3.2.1'], ['3.3.1'], ['3.4.1', '3.4.2'], ['3.5.1', '3.5.2']], 
     [['4.1.1', '4.1.2'], ['4.2.1', '4.2.2'], ['4.3.1', '4.3.2']], 
     [['5.1.1', '5.1.2'], ['5.2.1'], ['5.3.1', '5.3.2'], ['5.4.1']], 
     [['6.1.1', '6.1.2', '6.1.3', '6.1.4'], ['6.2.1', '6.2.2', '6.2.3', '6.2.4'], ['6.3.1', '6.3.2'], ['6.4.1', '6.4.2'], ['6.5.1', '6.5.2'], ['6.6.1', '6.6.2']], 
     [['7.1.1', '7.1.2', '7.1.3', '7.1.4'], ['7.2.1'], ['7.3.1', '7.3.2', '7.3.3'], ['7.4.1', '7.4.2']]]
  end
  
  def self.locations
    [['1.1.In front of body', '2.2.In front of face'], 
     ['3.3.Head', '3.4.Top of Head', '3.5.Eyes', '3.6.Nose', '3.7.Ear', '3.8.Cheek', '3.9.Lower Head'], 
     ['4.0.Body', '4.10.Neck/Throat', '4.11.Shoulders', '4.12.Chest', '4.13.Abdomen', '4.14.Hips/Pelvis/Groin', '4.15.Upper Leg'],
     ['5.0.Arm', '5.16.Upper Arm', '5.17.Elbow', '5.18.Lower Arm'], 
     ['6.0.Hand', '6.19.Wrist', '6.20.Fingers/Thumb', '6.21.Palm of Hand', '6.22.Back of Hand', '6.23.Blades of Hand']]
  end
  
  def self.location_groups
    Sign.locations.map.with_index{|r, i| i.zero? ? r : r[0]}.flatten
  end
  
  def self.usage_tags
    [['archaic',   1],
     ['neologism', 2],
     ['obscene',   3],
     ['informal',  4],
     ['rare',      5]]
  end
  
  def self.topic_tags
    [['Actions and activities',                    5 ],
     ['Communication and cognition',               6 ],
     ['Animals',                                   7 ],
     ['House and garden',                          8 ],
     ['Body and appearance',                       9 ],
     ['Clothes',                                   10],
     ['Colours',                                   11],
     ['Deaf-related',                              12],
     ['Direction, location and spatial relations', 13],        
     ['Events and celebrations',                   14],
     ['Food and drink',                            16],
     ['Education',                                 17],
     ['Emotions',                                  18],
     ['Nature and environment',                    19],
     ['Family',                                    20],
     ['Countries, cities and nationalities',       21],  
     ['Government and politics',                   22],
     ['Health',                                    23],
     ['Idioms and phrases',                        24],
     ['Law and crime',                             25],
     ['Maori culture and concepts',                26],
     ['Materials',                                 27],
     ['Money',                                     28],
     ['Numbers',                                   29],
     ['Places',                                    30],
     ['Pronouns',                                  31],
     ['Religions',                                 32],
     ['Qualities, description and comparison',     33],
     ['Quantity and measure',                      34],
     ['Questions',                                 35],
     ['Sex and sexuality',                         36],
     ['Sports, recreation and hobbies',            37],
     ['Science',                                   38],
     ['Time',                                      39],
     ['Travel and transportation',                 40],
     ['Weather',                                   41],
     ['Work',                                      42],
     ['Miscellaneous',                             44],
     ['Language and Linguistics',                  45],
     ['People and relationships',                  46],
     ['Maths',                                     47],
     ['Computers',                                 48]]
  end
  
private

  def self.search(params)
    xml_document = Nokogiri::XML(open(url_for_search(params)))
    entries = xml_document.css(ELEMENT_NAME)
    count = xml_document.css("totalhits").inner_text.to_i
    return [count, entries]
  end
  
  def self.url_for_search(query)
    #todo: handle quotes, handle special characters, handle encoding.
    # The handling of arrays in query strings is different in the API than in rails
    return SIGN_URL unless query.is_a?(Hash)
    query_string = []
    query.each do |k, v|
      if v.is_a?(Array)
        v.each {|ea| query_string << "#{k}=#{CGI::escape(ea.to_s)}" if ea.present?} 
      elsif v.present?
        query_string << "#{k}=#{CGI::escape(v.to_s)}"
      end
    end
    "#{SIGN_URL}?#{query_string.join("&")}"
  end
    
  def parse_transcription(data, tag)
    transcription = []
    data.css(tag).children.each do |item|
      if item.is_a?(Nokogiri::XML::Text) 
        transcription += item.content.split(' ')
      else 
        transcription << {:id => item['id'], :gloss => item.children.first.content}
      end
    end
    transcription
  end
  
  #Extend Nokogiri with helper method for fetching value
  Nokogiri::XML::Element.class_eval do
    def value_for_tag(tag_name)
      tag = self.css(tag_name).first
      tag.is_a?(Nokogiri::XML::Node) ? tag.content() : ""
    end
  end
  
end

