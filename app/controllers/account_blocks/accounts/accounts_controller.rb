module AccountBlock
  class AccountsController < ApplicationController
    include BuilderJsonWebToken::JsonWebTokenValidation

    before_action :validate_json_web_token, only: [:search, :change_email_address, :change_phone_number, :specific_account, :logged_user, :verify_otp, :update_account, :safeties]

    def account_deletion_steps
      # This method is intentionally left empty as it serves as a template for displaying the steps for account deletion.
    end

    def create
      case params[:data][:type] #### rescue invalid API format
      # when "sms_account"
      #   validate_json_web_token

      #   unless valid_token?
      #     return render json: {errors: [
      #       {token: "Invalid Token"}
      #     ]}, status: :bad_request
      #   end

      #   begin
      #     @sms_otp = SmsOtp.find(@token[:id])
      #   rescue ActiveRecord::RecordNotFound => e
      #     return render json: {errors: [
      #       {phone: "Confirmed Phone Number was not found"}
      #     ]}, status: :unprocessable_entity
      #   end

      #   params[:data][:attributes][:full_phone_number] =
      #     @sms_otp.full_phone_number
      #   @account = SmsAccount.new(jsonapi_deserialize(params))
      #   @account.activated = true
      #   if @account.save
      #     render json: SmsAccountSerializer.new(@account, meta: {
      #       token: encode(@account.id)
      #     }).serializable_hash, status: :created
      #   else
      #     render json: {errors: format_activerecord_errors(@account.errors)},
      #       status: :unprocessable_entity
      #   end

      when "email_account"
        account_params = jsonapi_deserialize(params)

        query_email = account_params["email"].downcase
        account = EmailAccount.where("LOWER(email) = ?", query_email).first

        validator = EmailValidation.new(account_params["email"])

        if account&.activated
          render_existing_email_error
          return
        end

        if !validator.valid?
          render_invalid_email_error
          return
        end

        if account.present?
          email_otp = EmailOtp.where(email: account.email, activated: false).first_or_create
          email_otp.update(pin: rand(1_000..9_999), valid_until: Time.current + 1.minute)

          send_email_for(email_otp, account)

          render_existing_email_unactivated(account, email_otp)
        else
          create_new_email_account(account_params)
        end

      when "social_account"
        account_params = jsonapi_deserialize(params)

        # Check if social account already exists
        @account = SocialAccount.find_by("LOWER(platform) = LOWER(?) AND unique_auth_id = ?", account_params["platform"], account_params["unique_auth_id"])

        if @account.present?
          @account.update_login_time
          # Return existing account and token with success message
          @account.update(fcm_device_token: account_params['fcm_device_token'])
          render json: {
            message: "Login successful",
            data: SocialAccountSerializer.new(@account).serializable_hash[:data],
            meta: {
              token: encode(@account.id)
            }
          }, status: :ok
          return
        end

        # Create new social account
        # Platform is according to the Frontend it will be Facebook, Google
        @account = SocialAccount.new(account_params)
        @account.password = @account.email

        if @account.save
          @account.update_login_time
          render json: SocialAccountSerializer.new(@account, meta: {
            token: encode(@account.id)
          }).serializable_hash, status: :created
        else
          render json: {errors: format_activerecord_errors(@account.errors)},
            status: :unprocessable_entity
        end

      else
        render json: {errors: [
          {account: "Invalid Account Type"}
        ]}, status: :unprocessable_entity
      end
    end

    def verify_otp
      account = EmailAccount.find(@token.id)

      if account.activated
        render_already_activated_account_error
        return
      end

      otp_params = jsonapi_deserialize(params)
      email_otp = AccountBlock::EmailOtp.find_by(email: account.email, pin: otp_params["otp"])

      if email_otp.nil?
        render_invalid_otp_error
        return
      end

      if email_otp.valid_until < Time.current
        render_expired_otp_error
        return
      end

      account.update(activated: true)
      email_otp.update(activated: true)

      render json: {
        Message: "OTP verification successfull",
        account: EmailAccountSerializer.new(account, meta: {
          token: encode(account.id)
        }).serializable_hash
      }, status: :ok

      # Send NewsLetter Mail after otp verification
      if account.opt_in_email_notifications?
        SendNewsletterJob.perform_later(account)
      end
    end

    # def resend_otp
    #   account = EmailAccount.find(@token.id)

    #   email_otp = AccountBlock::EmailOtp.where(email: account.email, activated: false).first
    #   if email_otp
    #     email_otp.update(pin: rand(1_000..9_999), valid_until: Time.current + 1.minute)
    #   else
    #     email_otp = AccountBlock::EmailOtp.create(email: account.email)
    #   end

    #   send_email_for(email_otp, account)

    #   render json: {
    #     Message: "OTP has been resent",
    #     otp: email_otp.pin
    #   }, status: :ok
    # end

    def safeties
      safety = BxBlockAdmin::Safety.last
      if safety.present?
        last_updated = safety.updated_at.strftime('%B %e, %Y')
        render json: { last_updated: last_updated, safety_description: safety.description }, status: :ok
      else
        render json: {message: "safety data not found"}, status: :not_found
      end
    end

    def search
      @accounts = Account.where(activated: true)
        .where("first_name ILIKE :search OR " \
                           "last_name ILIKE :search OR " \
                           "email ILIKE :search", search: "%#{search_params[:query]}%")
      if @accounts.present?
        render json: AccountSerializer.new(@accounts, meta: {message: "List of users."}).serializable_hash, status: :ok
      else
        render json: {errors: [{message: "Not found any user."}]}, status: :ok
      end
    end

    def update_account
      account = AccountBlock::Account.find_by(id: @token.id)
      if account.nil?
        render json: { message: 'Token invalid' }, status: :unauthorized
      else
        if account.update(update_account_params)
          render json: { message: 'Account updated successfully' }
        else
          render json: { errors: account.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end

    def change_email_address
      query_email = params["email"]
      confirm_email = params["confirm_email"]

      # Check if confirm_email is present
      unless confirm_email.present?
        return render json: { errors: "Confirm email is required" }, status: :unprocessable_entity
      end

      # Check if the new email and confirm email match
      if query_email != confirm_email
        return render json: { errors: "New email and confirm email do not match" }, status: :unprocessable_entity
      end

      account = EmailAccount.where("LOWER(email) = ?", query_email).first
      validator = EmailValidation.new(query_email)

      if account || !validator.valid?
        return render json: { errors: "Email invalid" }, status: :unprocessable_entity
      end

      @account = Account.find(@token.id)
      if @account.update(email: query_email)
        render json: AccountSerializer.new(@account).serializable_hash, status: :ok
      else
        render json: { errors: "Failed to update email address" }, status: :unprocessable_entity
      end
    end

    def change_phone_number
      @account = Account.find(@token.id)
      if @account.update(full_phone_number: params["full_phone_number"])
        render json: AccountSerializer.new(@account).serializable_hash, status: :ok
      else
        render json: {errors: "account user phone_number is not updated"}, status: :ok
      end
    end

    def specific_account
      @account = Account.find(@token.id)
      if @account.present?
        render json: AccountSerializer.new(@account).serializable_hash, status: :ok
      else
        render json: {errors: "account does not exist"}, status: :ok
      end
    end

    def index
      @accounts = Account.all
      if @accounts.present?
        render json: AccountSerializer.new(@accounts).serializable_hash, status: :ok
      else
        render json: {errors: "accounts data does not exist"}, status: :ok
      end
    end

    def logged_user
      @account = Account.find(@token.id)
      if @account.present?
        render json: AccountSerializer.new(@account).serializable_hash, status: :ok
      else
        render json: {errors: "account does not exist"}, status: :ok
      end
    end

    private

    def update_account_params
      params.require(:data).require(:attributes).permit(
        :activated, :country_code, :email, :first_name, :full_phone_number, :last_name, :phone_number, :type, :created_at,
        :updated_at, :device_id, :unique_auth_id, :opt_in_email_notifications
      )
    end

    def encode(id)
      BuilderJsonWebToken.encode id
    end

    def search_params
      params.permit(:query)
    end

    def format_activerecord_errors(errors)
      result = []
      errors.each do |attribute, error|
        result << { attribute => error }
      end
      result
    end

    def send_email_for(otp_record, account)
      BxBlockForgotPassword::EmailOtpMailer
        .with(otp: otp_record, host: request.base_url, user_name: account&.first_name)
        .otp_email.deliver
    end

    def render_existing_email_error
      render json: {errors: [{account: "Email address already exists"}]}, status: :unprocessable_entity
    end

    def render_existing_email_unactivated(account, email_otp)
      render json: {
        Message: "The email address already exists but has not been activated. Please activate your account using the OTP sent to your email.",
        otp: email_otp.pin,
        account: EmailAccountSerializer.new(account, meta: {
          token: encode(account.id)
        }).serializable_hash
      }, status: :created
    end

    def render_invalid_email_error
      render json: {errors: [{account: "Invalid email address"}]}, status: :unprocessable_entity
    end

    def create_new_email_account(account_params)
      @account = EmailAccount.new(account_params)
      @account.platform = request.headers["platform"].downcase if request.headers.include?("platform")

      if @account.save
        @account.update_login_time
        email_otp = AccountBlock::EmailOtp.new(email: @account.email)
        if email_otp.save
          send_email_for(email_otp, @account)
          render json: {
            Message: "Account verification OTP has been sent to your email",
            otp: email_otp.pin,
            account: EmailAccountSerializer.new(@account, meta: {
              token: encode(@account.id)
            }).serializable_hash
          }, status: :created
        end
      else
        render json: {errors: format_activerecord_errors(@account.errors)}, status: :unprocessable_entity
      end
    end

    def render_expired_otp_error
      render json: {errors: [{otp: "OTP has expired, please request a new one."}]}, status: :unprocessable_entity
    end

    def render_invalid_otp_error
      render json: {errors: [{otp: "Invalid OTP"}]}, status: :unprocessable_entity
    end

    def render_already_activated_account_error
      render json: {errors: [{account: "Account is already activated"}]}, status: :unprocessable_entity
    end
  end
end
