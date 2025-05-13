module BxBlockLikeAPost
  class LikePostsController < ApplicationController
    include BuilderJsonWebToken::JsonWebTokenValidation
    before_action :current_user
    before_action :validate_params, only: [:create]

    def index
      authorize BxBlockLikeAPost::LikePost

      if params[:query].present?
        account_ids = AccountBlock::Account.where('first_name LIKE :search OR
                                                   last_name LIKE :search OR
                                                   email LIKE :search OR
                                                   full_phone_number LIKE :search',
          search: "%#{params[:query]}%")
        likes = LikePost.where(account_id: account_ids)
      else
        likes = LikePost.where('account_id = ?', current_user.id)
      end
      if likes.present?
        render json: LikePostSerializer.new(likes, meta: {message: 'List of posts you likes.'}).serializable_hash, status: :ok
      else
        render json: {
          errors: [
            {message: 'No posts liked yet.'}
          ]
        }, status: :ok
      end
    end

    def show
      # Check if you like this post, get total likes of this post
      like = LikePost.find_by(
        account_id: current_user.id,
        post_id: params[:id]
      )

      if like.present?
        authorize like
        render json: LikePostSerializer.new(
          like,
          meta: {
            success: true,
            message: 'Liked this post.',
            total_likes: post_total_likes(params[:id])
          }
        ).serializable_hash, status: :ok
      else
        render json: {
          meta: [
            {
              success: false,
              message: 'Not liked this post.',
              total_likes: post_total_likes(params[:id])
            }
          ]
        }, status: :ok
      end
    end

    def create
      authorize BxBlockLikeAPost::LikePost

      case params[:data][:type]
      when 'like'
        likepost_params = jsonapi_deserialize(params)
        post_service = BxBlockLikeAPost::PostService.new(likepost_params, current_user)
        result, errors = post_service.like

        if result
          render json: LikePostSerializer.new(
            post_service.like_post, meta: {message: 'Successfully liked.'}
          ).serializable_hash, status: :created
        else
          render json: {errors: errors}, status: :unprocessable_entity
        end

      when 'unlike'
        likepost_params = jsonapi_deserialize(params)
        post_service = BxBlockLikeAPost::PostService.new(likepost_params, current_user)
        result, errors = post_service.unlike

        if result
          render json: {message: 'Removed from like.'}, status: :ok
        else
          render json: {errors: errors}, status: :unprocessable_entity
        end

      else
        render json: {
          errors: [
            {message: 'Invalid Type'}
          ]
        }, status: :unprocessable_entity
      end
    end

    private

    def validate_params
      if params[:data][:attributes][:post_id].nil?
        render json: {
          errors: [
            {message: 'Parameter missing.'}
          ]
        }, status: :unprocessable_entity
      end
    end

    def post_total_likes(postid)
      LikePost.where('post_id = ?', postid).count

    end
  end
end
