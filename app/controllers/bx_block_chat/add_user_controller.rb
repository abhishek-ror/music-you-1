module BxBlockChat
  module Chats
    class AddUserController < ApplicationController
      def add
        @new_cats = []
        accounts = AccountBlock::Account.where(id: params[:accounts_id])
        if accounts.present?
          accounts.each do |account|
            chat_user = BxBlockChat::AccountsChatsBlock.new(chat_id: params[:chat_id],
              account_id: account.id)

            if chat_user.save
              @new_cats.push(chat_user.chat)
            else
              return render json: {errors: chat_user.errors}, status: :unprocessable_entity
            end
          end

          render json: ChatOnlySerializer.new(@new_cats, meta: {}).serializable_hash, status: :created
        else
          not_found
        end
      end

      def index
        subscriptions = AccountBlock::Account.find(current_user.id)&.subscriptions&.order(id: :desc)
        account_ids = subscriptions.includes("subscrible").pluck("accounts.id")
        @accounts = AccountBlock::Account.where(id: account_ids)
        render json: ::AccountBlock::AccountSerializer.new(@accounts, meta: {}).serializable_hash, status: :ok
      end
    end
  end
end
