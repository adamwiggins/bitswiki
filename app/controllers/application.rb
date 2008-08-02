class ApplicationController < ActionController::Base
  before_filter :authenticate

  def authenticate
    if local_request?
      @user = User.find(:first)
    else
      @user = User.find_or_create(heroku_user.email.split(/@|\./)[0])

      if !heroku_user.logged_in? and (WikiOptions[:allow_anonymous_read] == false)
        redirect_to WikiOptions[:access_denied_url] + "?url=http://#{request.env['HTTP_HOST']}#{request.env['REQUEST_URI']}"
      end
    end
  end
end
