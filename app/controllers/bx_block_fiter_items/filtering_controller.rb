# frozen_string_literal: true

module BxBlockFilterItems
  class FilteringController < ApplicationController
    def index
      @catalogues = CatalogueFilter.new(
        ::BxBlockCatalogue::Catalogue, params[:q]
      ).call

      render json: ::BxBlockCatalogue::CatalogueSerializer
        .new(@catalogues, serialization_options)
        .serializable_hash
    end

    def filter_items
      ethnicity = params[:ethnicity]&.split(',')
      gen = params[:genres]&.split(',')
      min_age = params[:min_age]
      max_age = params[:max_age]
      looking_for = params[:looking_for]
      distance = params[:distance] # distance in miles
      user_location = [current_user.profiles.last.latitude.to_f, current_user.profiles.last.longitude.to_f]

      # Find all profiles that match the filtering parameters
      profiles = BxBlockProfile::Profile.where.not(account_id: current_user.id)
      profiles = profiles.where(gender: looking_for) if looking_for.present? && looking_for != 'everyone'
      profiles = profiles.where(dob: (max_age.to_i + 1).years.ago..min_age.to_i.years.ago) if min_age.present? && max_age.present?
      profiles = profiles.where("favorite_genres && ARRAY[?]::varchar[]", gen) if gen.present?

      # Filter profiles based on distance
      if user_location.present? && distance.present?
        profiles = profiles.near(user_location, distance.to_f, units: :mi)
      end

      if ethnicity.present?
        ethnicity_query = ethnicity.map(&:downcase)
        profiles = profiles.where("LOWER(ethnicity) IN (?)", ethnicity_query)
      end

      render json: FilterSerializer.new(profiles, params: {user_location: user_location}).serializable_hash, status: :ok
    end

    private

    def serialization_options
      { params: { host: request.protocol + request.host_with_port } }
    end
  end
end
