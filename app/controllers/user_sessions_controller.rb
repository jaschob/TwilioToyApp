class UserSessionsController < ApplicationController
  include TwilioAuthHelper

  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      flash[:notice] = "Successfully logged in."
      redirect_to root_url
    else
      render :action => 'new'
    end
  end

  def find
    #debugger
    session = super             # find normally by cookie
    unless session              # try to identify twilio user
      twilio_user = identify_twilio_user
    end

    session ||
      twilio_user && UserSession.create(twilio_user, false)
  end

  def destroy
    @user_session = UserSession.find

    if @user_session
      @user_session.destroy
      flash[:notice] = "Successfully logged out."
    end
  end
end
