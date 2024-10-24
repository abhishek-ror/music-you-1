module BxBlockChat
  class MessagesController < ApplicationController
    before_action :set_chat, only: [:index, :create]

    def index_all
      messages = current_user.chats.includes(:messages).flat_map(&:messages).sort_by(&:created_at).reverse
      render json: ChatMessageSerializer.new(messages).serializable_hash[:data]
    end

    def index
      messages = @chat.messages.order(created_at: :desc)
      response_data = {
        user_id: current_user.id,
        user_name: current_user.name,
        profile_url: current_user.profiles.first&.profile_picture || "",
        messages: messages.map { |msg| format_message(msg) }
      }
      render json: response_data, status: :ok
    end

    def create
      return render_not_found unless @chat

      message_type = params[:message][:song_name].present?? 'song' : 'text'
      if message_type == 'song'
        return handle_song_message
      end

      message = @chat.messages.new(message_params.merge(account_id: current_user.id, message_type: message_type))
      if message.save
        attach_files(message) if params[:message][:attachments].present?
        render json: format_message(message), status: :created
      else
        render json: { errors: message.errors }, status: :unprocessable_entity
      end
    end

    private

    def message_params
      params.require(:message).permit(:message, :song_name, :artist_name, :image_url, :song_url, attachments: [])
    end

    def handle_song_message
      subscription = current_user.recurring_subscription

      if subscription&.song_count == 0
        return render_song_limit_reached_error
      end

      message = @chat.messages.new(message_params.merge(account_id: current_user.id, message_type: 'song'))
      if message.save
        updated_song_count = subscription.song_count - 1
        subscription.update(song_count: updated_song_count)
        render json: format_message(message), status: :created
      else
        render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
      end
    end


    def set_chat
      @chat = BxBlockChat::Chat.find_by(id: params[:chat_id])
      render_not_found unless @chat
    end

    def render_not_found
      render json: { message: "Chat room is not valid or no longer exists" }, status: :not_found
    end

    def format_message(message)
      {
        message_id: message.id,
        sent_by: message.account_id == current_user.id ? "me" : "other",
        time: message.created_at.strftime("%-l:%M %p"),
        type: message.song_name.present? ? "song" : "text",
        message: message.message,
        song_name: message.song_name,
        artist_name: message.artist_name,
        song_url: message.song_url,
        image_url: message.image_url
      }
    end

    def attach_files(message)
      params[:message][:attachments].each do |attachment|
        message.attachments.attach(attachment)
      end
    end

    def render_song_limit_reached_error
      render json: { error: "You have reached the song sending limit for your subscription plan this week" }, status: :forbidden
    end
  end
end
