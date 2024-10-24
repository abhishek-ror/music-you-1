module BxBlockBlockUsers
  class BlockUsersController < ApplicationController
    include BuilderJsonWebToken::JsonWebTokenValidation

    before_action :validate_json_web_token
    before_action :current_user


    def index
      @list_blocked_users = BlockUser.where('current_user_id = ?', current_user.id)
      if @list_blocked_users.present?
        render json: BlockUsersSerializer.new(@list_blocked_users, meta: {
          message: 'List of blocked users.'
        }).serializable_hash, status: :ok
      else
        render json: {errors: [{message: 'No user blocked.'}]}, status: :ok
      end
    end

    def show
      #Check if user blocked or not
      @blocked_account =
        BlockUser.find_by(current_user_id: current_user.id, account_id: params[:id])
      if @blocked_account.present?
        render json: BlockUsersSerializer.new(@blocked_account, meta: {success: true
        }).serializable_hash, status: :ok
      else
        render json: {errors: [{success: false}]}, status: :ok
      end
    end

    def create
      account_params = jsonapi_deserialize(params)
      account_id = params[:data][:attributes][:account_id].to_i
      #If user try to block self
      return render json: {errors: [{message: 'You cannot block yourself.'},
      ]}, status: :unprocessable_entity if current_user.id == account_id

      #Check if blocked user present
      begin
        @account = AccountBlock::Account.find(account_id)
      rescue ActiveRecord::RecordNotFound => e
        return render json: {errors: [{message: 'User does not exist.'},
        ]}, status: :unprocessable_entity
      end
      #If user already blocked
      @user_blocked = BlockUser.find_by(current_user_id: current_user.id, account_id: account_id)
      return render json: {errors: [{message: 'User already blocked.'},
      ]}, status: :unprocessable_entity if @user_blocked.present?

      @blocked_account = BlockUser.new(account_params.merge(current_user_id: current_user.id))
      if @blocked_account.save!
        render json: BlockUsersSerializer.new(@blocked_account, meta: {message: 'User blocked.'
        }).serializable_hash, status: :created
      else
        render json: {errors: format_activerecord_errors(@blocked_account.errors)},
               status: :unprocessable_entity
      end
    end

    def destroy
      @block_user = BlockUser.find_by(id: params[:id])
      return render json: {errors: [{message: 'User not found.'}
      ]}, status: :unprocessable_entity unless @block_user.present?

      if @block_user.destroy
        render json: {message: 'User unblocked.'}, status: :ok
      else
        render json: {errors: [{message: 'User not unblock.'}]}, status: :unprocessable_entity
      end
    end

    private

    def encode(id)
      BuilderJsonWebToken.encode id
    end

    def current_user
      @current_user ||= AccountBlock::Account.find(@token.id) if @token.present?
    end
  end
end
