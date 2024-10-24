module BxBlockChat
  class ChatsController < ApplicationController
    before_action :find_chat, only: [:read_messages, :block_user, :unblock_user, :report_user]

    def unread_messages
      profile_id = current_user.profiles&.last&.id
      unread_messages = ChatMessage.joins(:chat).where(chats: { sender_id: profile_id }).where(is_mark_read: false)

      messages_response = unread_messages.map do |message|
        formatted_message = {
          message_id: message.id,
          sent_by: message.chat.sender_id == profile_id ? 'me' : 'other',
          time: message.created_at.strftime("%I:%M %p"),
          message: message.message.present? ? message.message : nil,
          song_name: message.song_name,
          artist_name: message.artist_name,
          song_url: message.song_url,
          image_url: message.image_url,
        }.compact

        formatted_message[:message] = nil if formatted_message[:type] == 'song'
        formatted_message
      end

      render json: { data: messages_response }, status: :ok
    end

    def unread_messages_count
      profile_id = current_user.profiles&.last&.id
      unread_count = ChatMessage.joins(:chat).where(chats: { sender_id: profile_id }).where(is_mark_read: false).count
      render json: { unread_messages_count: unread_count }, status: :ok
    end

    def index
      profile_id = current_user.profiles&.last&.id

      chat_send_messages = current_user.chats
      send_msg_data = BxBlockChat::ChatSerializer.new(chat_send_messages, serialization_options).serializable_hash

      chat_receive_messages = BxBlockChat::Chat.where(sender_id: profile_id)
      received_msg_data = BxBlockChat::ChatSerializer.new(chat_receive_messages, serialization_options).serializable_hash

      render json: { received_msg_data: received_msg_data, send_msg_data: send_msg_data }, status: :ok
    end

    def show
      chat = BxBlockChat::Chat.includes(:accounts).find(params[:id])
      render json: ::BxBlockChat::ChatSerializer.new(chat, serialization_options).serializable_hash, status: :ok
    end

    def create
      chat = BxBlockChat::Chat.new(chat_params)
      chat.chat_type = "single_user"
      profile = current_user&.profiles&.last
      if chat.save

        BxBlockChat::AccountsChatsBlock.create(account_id: current_user.id, chat_id: chat.id, status: :admin)
        create_twilio_channel(chat)
        send_notification(profile, chat)
        render json: ::BxBlockChat::ChatSerializer.new(chat, serialization_options).serializable_hash, status: :created
      else
        render json: {errors: chat.errors}, status: :unprocessable_entity
      end
    end

    def history
      chat_ids = AccountBlock::Account.find(params[:receiver_id]).chats.pluck(:id)
      chats = current_user.chats.where(id: chat_ids)
      if chats.present?
        render json: ::BxBlockChat::ChatHistorySerializer.new(chats, chat_message_serialization_options).serializable_hash, status: :ok
      else
        render json: {message: "They don't have any chat history"}
      end
    end

    def read_messages
      @chat.messages&.all&.update(is_mark_read: true)
      render json: ::BxBlockChat::ChatSerializer.new(@chat, serialization_options).serializable_hash, status: :ok
    rescue => e
      render json: {error: e}
    end

    def update
      chat = Chat.find(params[:id])
      if !params[:chat][:name].nil?
        Chat.where(id: chat.id).update(name:params[:chat][:name])
      end
      if !params[:chat][:muted].nil?
        current_user.accounts_chats.where(chat_id: chat.id).first.update(muted: params[:chat][:muted])
      end
      chat.reload
      if chat.present?
        render json: ::BxBlockChat::ChatSerializer.new(
          chat, serialization_options
        ).serializable_hash, status: :ok
      else
        render json: {errors: format_activerecord_errors(chat.errors)},
          status: :unprocessable_entity
      end
    end

    def search
      @chats = current_user
        .chats
        .where("name ILIKE :search", search: "%#{search_params[:query]}%")
      render json: ChatSerializer.new(@chats, serialization_options).serializable_hash, status: :ok
    end

    def search_messages
      @messages = ChatMessage
        .where(chat_id: current_user.chat_ids)
        .where("message ILIKE :search", search: "%#{search_params[:query]}%")
      render json: ChatMessageSerializer.new(@messages, serialization_options).serializable_hash, status: :ok
    end

    def block_user
      @block_user = AccountBlock::Account.find(params[:account_id])

      if BxBlockBlockUsers::BlockUser.exists?(account_id: current_user.id, current_user_id: @block_user.id)
        #  comment hai niche ki dono line
        block = BxBlockBlockUsers::BlockUser.find_by(account_id: current_user.id, current_user_id: @block_user.id)
        block.update!(blocked: true)
      else
        block = BxBlockBlockUsers::BlockUser.create(account_id: @block_user.id, current_user_id: current_user.id, blocked: true)
      end

      render json: { message: "User blocked successfully" }, status: :ok
    rescue => e
      render json: { error: "Failed to block user" }, status: :unprocessable_entity
    end

    def unblock_user
      @unblock_user = AccountBlock::Account.find(params[:account_id])
      @block_user = BxBlockBlockUsers::BlockUser.find_by(account_id: @unblock_user.id, current_user_id: current_user.id)
      if @block_user
        @block_user.destroy
        render json: { message: "User unblocked successfully" }, status: :ok
      else
        render json: { error: "User is not blocked" }, status: :unprocessable_entity
      end
    end

    def report_user
      @report_user = AccountBlock::Account.find(params[:account_id])

      if BxBlockBlockUsers::BlockUser.exists?(account_id: current_user.id, current_user_id: @report_user.id)
        #comment hai niche ki dono line
        report = BxBlockBlockUsers::BlockUser.find_by(account_id: current_user.id, current_user_id: @report_user.id)
        report.update!(reported: true)
      else
        report = BxBlockBlockUsers::BlockUser.create(account_id: @report_user.id, current_user_id: current_user.id, reported: true)
      end

      render json: { message: "User reported successfully" }, status: :ok
    rescue => e
      render json: { error: "Failed to report user" }, status: :unprocessable_entity
    end

    def format_attachments(message)
      attachments = message.attachments
      return nil unless attachments.any?

      attachments.map do |attachment|
        {
          message_type: attachment.message_type,
          attachment: attachment.attachment,
          song_name: attachment.song_name,
          artist_name: attachment.artist_name,
          image_url: attachment.image_url,
          song_url: attachment.song_url
        }.reject { |key, value| value.nil? }
      end
    end

    private

    def chat_params
      params.require(:chat).permit(:name, :sender_id)
    end

    def search_params
      params.permit(:query)
    end

    def find_chat
      @chat = Chat.find_by_id(params[:id]) # Replace chat_id changed to id
      render json: {message: "Chat room is not valid or no longer exists"} unless @chat
    end

    def create_twilio_channel(chat)
      service = TwilioTokenService.new
      service.create_channel(chat)
    rescue Twilio::REST::TwilioError => e
      Rails.logger.error "Failed to create Twilio channel: #{e.message}"
      raise
    end

    def send_notification(profile, chat)
      if profile
        receiver_account_id = BxBlockProfile::Profile.find_by(id: chat.sender_id).account_id
        setting = BxBlockNotifsettings::NotificationSetting.find_by(account_id: receiver_account_id, title: "New messages")

        BxBlockPushNotifications::PushNotification.create(
          account_id: receiver_account_id,
          push_notificable_type: chat.class.name,
          push_notificable_id: chat.id,
          remarks: "#{profile.first_name} sent you a message.",
          content: chat.name,
          notify_type: setting&.title,
          in_app: setting&.in_app_notifications
        )
      end
    end
  end
end
