module BxBlockInvitefriends2
  class InviteFriendsController < ApplicationController
    include BuilderJsonWebToken::JsonWebTokenValidation
    before_action :validate_json_web_token, except: [:redirect]

    def create
      invitation = current_user.invite_friends.build(invitation_params)
      if invitation.save
        render json: {
          message: "Invitation sent successfully!",
          invitation_id: invitation.id,
          unique_url: invitation.unique_url
        }, status: :ok
      else
        render json: { error: "Failed to send invitation" }, status: :unprocessable_entity
      end
    end

    def redirect
      token = params[:token]
      invitation = InviteFriend.find_by(unique_url: redirect_url(token))
      if invitation
        device_type = detect_device_type
        case device_type
        when :android
          redirect_to "https://play.google.com/store/apps/details?id=com.ludo.king&hl=en-IN", allow_other_host: true
        when :ios
          redirect_to "https://apps.apple.com/in/app/ludo-king/id993090598", allow_other_host: true
        else
          redirect_to "https://apps.microsoft.com/detail/9mz6x24qcpn7?hl=en-us&gl=IN", allow_other_host: true
        end
      else
        render json: { error: "Invalid invitation token" }, status: :unprocessable_entity
      end
    end

    private

    def current_user
      @current_user ||= AccountBlock::EmailAccount.find_by(id: @token.id)
    end

    def invitation_params
      params.require(:invitation).permit(:recipient_email, :message)
    end

    def redirect_url(token)
      host = Rails.application.config.action_mailer.default_url_options[:host]
      port = Rails.application.config.action_mailer.default_url_options[:port]
      logger.debug "Host: #{host}, Port: #{port}"
      "#{host}:#{port}/bx_block_invitefriends2/redirect?token=#{token}"
    end

    def detect_device_type
      ua = request.user_agent
      if ua =~ /Android|android/i
        :android
      elsif ua =~ /iPhone/i
        :ios
      elsif ua =~ /Windows/i
        :windows
      else
        :unknown
      end
    end
  end
end
