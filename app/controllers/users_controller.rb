class UsersController < ApplicationController
  before_filter :require_user, except: [:new, :create]
  before_action :set_user

  respond_to :html, :json, :twiml

  def index
    @known_balances = Coin::Account.all_balances
    @users = User.all.sort do |a, b|
      a.username <=> b.username
    end

    if exclude_current_user?
      @users = @users.reject {|u| u == current_user }
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
    @user.notify_tx = User::NOTIFY_NEVER
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)
    respond_to do |format|
      if @user.save
        donated = donate_welcome_amount @user
        format.html {
          redirect_to root_url,
          notice: donated ?
          "Registration successful - you received #{donated} BTC as a welcome gift!"
          : "Registration successful."
        }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = current_user
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      p = params.require(:user).permit(:username, :phone,
                                       :password, :password_confirmation,
                                       :notify_tx)
      return p
    end

    def exclude_current_user?
      ApplicationHelper::TRUE_WORDS.include? params[:exclude_current_user]
    end

    # Donates an amount defined in the application configuration to a user.
    # This money comes from the core account.
    def donate_welcome_amount(user)
      core_account = Coin::Account.core
      available = core_account.balance
      Rails.logger.debug "Available is #{available}"
      donation_amount = Rails.application.new_user_donation_amount
      if available.sign === BigDecimal::SIGN_POSITIVE_FINITE
        if donation_amount > available
          donation_amount = available
        end

        core_account.move donation_amount, user
      else
        donation_amount = nil
      end

      donation_amount
    end
end
