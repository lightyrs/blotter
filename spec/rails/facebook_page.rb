class FacebookPage

  attr_accessor :name

  def initialize(name = nil)
    @name = name
  end

  def active_giveaway
    giveaway = Hash.new
    giveaway[:title] = "Powered by Blotter"
    giveaway
  end
end
