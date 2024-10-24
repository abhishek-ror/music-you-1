module BxBlockAppleLogin
  class AppleAccountsController < ApplicationController
    require 'uri'
    def validate
      user_identity = params[:user]
      # Modify according to FE
      # jwt = params[:identityToken]

      begin
        account = BxBlockAppleLogin::AppleAccount.create_account(user_identity, apple_account_params)
        if account
          render json: AppleAccountSerializer.new(account, meta: {
            message: 'User Signed in Successfully',
          }).serializable_hash, status: :created
        else
          render json: { data: { verified: false, message: 'user not found' } }, status: 200
        end
      rescue StandardError => e
        return render json: {errors: [e]}, status: :unprocessable_entity
      end
    end

    private

    def apple_account_params
      params.permit(:first_name, :last_name, :email)
    end
  end
end
