class My::PinsController < ApplicationController
  def index
    @pins = Current.user.pins.includes(:card).ordered.limit(20)
    fresh_when etag: [ @pins, @pins.collect(&:card) ]
  end
end
