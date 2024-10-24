module BxBlockChat
  module Chats
    class LeaveChatController < ApplicationController
      def leave
        chat = BxBlockChat::Chat.find(params[:chat_id])
        if chat&.last_admin?(current_user)
          return render json: {errors: [
            {account: "Add new admin before leaving this chat"}
          ]}, status: :unprocessable_entity
        end

        if chat.accounts.count <= 2
          chat.destroy
        else
          BxBlockChat::AccountsChatsBlock
            .where(account_id: current_user.id, chat_id: params[:chat_id])
            .last
            .delete
        end

        render json: {data: {message: "Left the chat successfully"}}, status: :ok
      end
    end
  end
end
