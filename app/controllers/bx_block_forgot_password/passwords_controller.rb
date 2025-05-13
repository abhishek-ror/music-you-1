module BxBlockForgotPassword
  class PasswordsController < ApplicationController
    include BuilderJsonWebToken::JsonWebTokenValidation
    before_action :validate_json_web_token, only: [:change_password]

    # def create
    #   if create_params[:token].present? && create_params[:new_password].present?
    #     # Try to decode token with OTP information
    #     begin
    #       token = BuilderJsonWebToken.decode(create_params[:token])
    #     rescue JWT::DecodeError => e
    #       return render json: {
    #         errors: [{
    #           token: 'Invalid token',
    #         }],
    #       }, status: :bad_request
    #     end

    #     # Try to get OTP object from token
    #     begin
    #       otp = token.type.constantize.find(token.id)
    #     rescue ActiveRecord::RecordNotFound => e
    #       return render json: {
    #         errors: [{
    #           otp: 'Token invalid',
    #         }],
    #       }, status: :unprocessable_entity
    #     end

    #     # Check if OTP was validated
    #     unless otp.activated?
    #       return render json: {
    #         errors: [{
    #           otp: 'OTP code not validated',
    #         }],
    #       }, status: :unprocessable_entity
    #     else
    #       # Check new password requirements
    #       password_validation = AccountBlock::PasswordValidation
    #         .new(create_params[:new_password])

    #       is_valid = password_validation.valid?
    #       error_message = password_validation.errors.full_messages.first

    #       unless is_valid
    #         return render json: {
    #           errors: [{
    #             password: error_message,
    #           }],
    #         }, status: :unprocessable_entity
    #       else
    #         # Update account with new password
    #         account = AccountBlock::Account.find(token.account_id)

    #         if account.update(:password => create_params[:new_password])
    #           # Delete OTP object as it's not needed anymore
    #           otp.destroy

    #           serializer = AccountBlock::AccountSerializer.new(account)
    #           serialized_account = serializer.serializable_hash

    #           render json: serialized_account, status: :created
    #         else
    #           render json: {
    #             errors: [{
    #               profile: 'Password change failed',
    #             }],
    #           }, status: :unprocessable_entity
    #         end
    #       end
    #     end
    #   else
    #     return render json: {
    #       errors: [{
    #         otp: 'Token and new password are required',
    #       }],
    #     }, status: :unprocessable_entity
    #   end
    # end

    def create
      @account = AccountBlock::Account.find_by(email: create_params[:email])

      if @account.nil?
        render json: { errors: "Account not found." }, status: :unprocessable_entity
      elsif create_params[:new_password].blank?
        render json: { errors: "New password is missing." }, status: :unprocessable_entity
      elsif @account.update(password: create_params[:new_password])
        # BxBlockForgotPassword::ForgotPasswordMailer.with(email: @account.email).forgot_password_you.deliver_now
        render json: { message: "Password has been updated successfully." }, status: :ok
      end
    end

    def change_password
        if create_params[:new_password].present?
            account = AccountBlock::EmailAccount.find(@token.id)
            if account.update(:password => create_params[:new_password])
              render json: {
                Message: "Password has been changed successfully.",
                account: AccountBlock::EmailAccountSerializer.new(account).serializable_hash
              }, status: :ok
            else
              render json: {errors: format_activerecord_errors(account.errors)}, status: :unprocessable_entity
            end
        else
            return render json: {
              errors: [{
                otp: 'New password are required',
              }],
            }, status: :unprocessable_entity
        end
    end

    private

    def format_activerecord_errors(errors)
      result = []
      errors.each do |attribute, error|
        result << { attribute => error }
      end
      result
    end

    def create_params
      params.require(:data)
      .permit(*[
        :email,
        :full_phone_number,
        :token,
        :otp_code,
        :new_password,
      ])
    end
  end
end
