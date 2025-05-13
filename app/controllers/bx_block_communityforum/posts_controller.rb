module BxBlockCommunityforum

  class PostsController < ApplicationController
    include BuilderJsonWebToken::JsonWebTokenValidation
    before_action :validate_json_web_token
    before_action :set_post, only: [:destroy, :update]
    before_action :check_post_owner, only: [:destroy, :update]

    def index
      posts = BxBlockCommunityforum::Post.where(approved: true).order(created_at: :desc)
      if posts.present?
        render json: PostSerializer.new(posts, params: {current_user_id: current_user.id}).serializable_hash
      else
        render json: {data: []},
            status: :ok
      end
    end

    def conversations_details
      post = BxBlockCommunityforum::Post.find(params[:id])
      if post
        comments = BxBlockComments::Comment.where(commentable_type: post.class.name, commentable_id: post.id).order(created_at: :desc)
        comments_data = BxBlockComments::CommentSerializer.new(comments, params: {current_user_id: current_user.id}).serializable_hash
        post_data = PostSerializer.new(post, params: {current_user_id: current_user.id}).serializable_hash
        render json: { post: post_data, comments: comments_data }
      end
    rescue ActiveRecord::RecordNotFound => e
      render json: { errors: [e.message] }, status: :not_found
    end

    def sort_post_comments
      post = BxBlockCommunityforum::Post.find(params[:post_id])

      if post
        comments = BxBlockComments::Comment.where(commentable_type: post.class.name, commentable_id: post.id)
        comments = comments.order(created_at: :desc) if params[:sort] == 'recent'
        comments = comments.order(created_at: :asc) if params[:sort] == 'oldest'

        comments_data = BxBlockComments::CommentSerializer.new(comments, params: {current_user_id: current_user.id}).serializable_hash
        render json: { comments: comments_data }
      end
    rescue ActiveRecord::RecordNotFound => e
      render json: { errors: [e.message] }, status: :not_found
    end

    def create
      new_post = BxBlockCommunityforum::Post.new(post_params.except(:songs))
      new_post.account_id = current_user.id
      post_songs = post_params[:songs]
      if post_songs.present?
        post_songs.each do |song|
          new_post.post_songs.build(song_name: song["song_name"], artist_name: song["artist_name"], image_url: song["image_url"], song_url: song["song_url"])
        end
      end

      if new_post.save
        render json: PostSerializer.new(new_post, params: {current_user_id: current_user.id}).serializable_hash,
               status: :ok
      else
        render json: ErrorSerializer.new(new_post, params: {current_user_id: current_user.id}).serializable_hash,
               status: :unprocessable_entity
      end
    end

    def destroy
      post = BxBlockCommunityforum::Post.find(params[:id])
      if post.destroy
        render json: { message: 'Post deleted successfully' }
      else
        render json: { message: 'Failed to delete post' }, status: :unprocessable_entity
      end
    end

    def update
      post = BxBlockCommunityforum::Post.find(params[:id])
      post_songs = post_params[:songs]
      if post_songs.present?
        post_songs.each do |song|
          post.post_songs.create(song_name: song["song_name"], artist_name: song["artist_name"], image_url: song["image_url"], song_url: song["song_url"])
        end
      end
      if post.update(post_params.except(:songs))
        render json: { message: 'Post updated successfully' }, status: :ok
      else
        render json: { message: 'Failed to update post' }, status: :unprocessable_entity
      end
    end

    private

    def post_params
      params.permit(:name, :description, :body, :location, category: [], songs: [:song_name, :artist_name, :image_url, :song_url])
    end

    def check_admin
      unless current_user && current_user.role && current_user.role.name == "admin"
        render json: { error: "You are not authorised user or proper role admin" }, status: :unauthorized
      end
    end

    def set_post
      @post = Post.find(params[:id])
    end

    def check_post_owner
      unless @post.account_id == current_user.id
        render json: { error: "You are not authorized to perform this action. Only the post owner can perform this action." }, status: :unauthorized
      end
    end
  end
end
