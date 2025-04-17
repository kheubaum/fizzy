class Cards::ReadingsController < ApplicationController
  include CardScoped

  def create
    Current.user.notifications.unread.where(card: @card).read_all
    @notifications = Current.user.notifications.unread.ordered.limit(20)
  end
end
