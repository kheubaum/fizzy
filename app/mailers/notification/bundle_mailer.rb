class Notification::BundleMailer < ApplicationMailer
  include Mailers::Unsubscribable

  helper NotificationsHelper

  def notification(bundle)
    @user = bundle.user
    @bundle = bundle
    @notifications = bundle.notifications
    @unsubscribe_token = @user.generate_token_for(:unsubscribe)

    mail \
      to: bundle.user.identity.email_address,
      subject: "Fizzy#{ " (#{ Current.account.name })" if @user.identity.accounts.many? }: Latest Activity"
  end
end
