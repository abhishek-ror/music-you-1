module BxBlockLike
  class LikesController < ApplicationController
    def index
      likes = if likeable_type
        BxBlockLike::Like.where(
          like_by_id: current_user.id,
          likeable_type: likeable_type
        )
      else
        BxBlockLike::Like.where(like_by_id: current_user.id)
      end

      if likes.present?
        render json: BxBlockLike::LikeSerializer.new(likes).serializable_hash,
          status: :ok
      else
        render json: {data: []}, status: :ok
      end
    end

    #This API is used to like a post or comment.
    def create
      like = BxBlockLike::Like.new(
        like_params.merge({like_by_id: current_user.id})
      )
      like.save
      handle_create_response(like)
    rescue => like
      render json: {errors: [{like: like.message}]},
        status: :unprocessable_entity
    end

    def destroy
      like = BxBlockLike::Like.find_by(
        id: params[:id], like_by_id: current_user.id
      )

      if like.present?
        like.destroy
        render json: {message: "Successfully destroy"},
          status: :ok
      else
        render json: {message: "Not found"},
          status: :not_found
      end
    end

    def mutual_likes
      mutual_profiles = BxBlockLike::Like.mutual_likes(current_user)
      response_data = []

      mutual_profiles.each do |profile|
        blocked = BxBlockBlockUsers::BlockUser.where(current_user_id: current_user.id, account_id: profile.account_id, blocked: true).exists?
        reported = BxBlockBlockUsers::BlockUser.where(current_user_id: current_user.id, account_id: profile.account_id, reported: true).exists?

        response_data << {
          id: profile.id,
          account_id: profile.account_id,
          last_message: "I've been listening to a lot of music",
          last_time_seen: Date.today.strftime("%d %b"),
          name: profile&.name,
          profile_picture: profile.profile_picture || "",
          profile_verified: profile.profile_verified? || false,
          readed: false,
          blocked: blocked,
          reported: reported
        }
      end

      render json: response_data, status: :ok
    end

    def unlike
      dislike = BxBlockLike::Like.find_by(like_params)
      if dislike
        dislike.update(disliked: true)
        render json: { message: "Successfully unliked" }, status: :ok
      else
        BxBlockLike::Like.create(like_params.merge(like_by_id: current_user.id).merge(disliked: true))
        render json: { message: "Successfully unliked" }, status: :ok
      end
    rescue => e
      render json: { errors: [e.message] }, status: :internal_server_error
    end

    private

    def like_params
      params.require(:data)[:attributes].permit \
        :likeable_id, :likeable_type
    end

    def likeable_type
      return if params[:like_type].blank?
      (params[:like_type] == "profile") ?
      ["BxBlockProfile::Profile", "BxBlockProfile::CareerExperience",
        "BxBlockProfile::Award", "BxBlockProfile::TestScoreAndCourse",
        "BxBlockProfile::Course", "BxBlockProfile::EducationalQualification",
        "BxBlockProfile::Project", "BxBlockComments::comment"] : "BxBlockPosts::Post"
    end

    def handle_create_response(like)
      if like.persisted?
        render json: BxBlockLike::LikeSerializer.new(like).serializable_hash,
          status: :ok
      else
        render json: {errors: [{like: like.errors.full_messages}]},
          status: :unprocessable_entity
      end
    end
  end
end
