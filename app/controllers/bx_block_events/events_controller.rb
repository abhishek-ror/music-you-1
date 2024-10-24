module BxBlockEvents
  class EventsController < ApplicationController
    include BuilderJsonWebToken::JsonWebTokenValidation

    before_action :validate_json_web_token
    before_action :set_account
    before_action :set_event, only: [:show, :update, :destroy, :notes_update]

    # def index
    #   # final_events = []
    #   # assigned_events = Event.all.select { |x| (x.assign_to.include?(@account.id.to_s) && x.visibility.include?(@account.id.to_s)) }
    #   assigned_events = BxBlockEvents::Event.all.order(id: :asc)
    #   account_events = @account.events.to_a
    #   final_events = assigned_events + account_events
    #   final_events = final_events.uniq.group_by { |t| t[:event_type] }
    #   total_interested_people_count = BxBlockEvents::Event.sum(:interested_people_count)
    #   render json: { data: final_events }
    # end

    def search_location
      location = params[:location]

      if location.blank?
        return render json: { errors: ["Location parameter is missing"] }, status: :bad_request
      end

      ticketmaster_service = TicketmasterEventService.new(ENV['TICKETMASTER_API_KEY'])
      event_data = ticketmaster_service.search_events(keyword: location.strip)

      if event_data[:error].present?
        Rails.logger.error("Failed to fetch Ticketmaster events: #{event_data[:error]}")
        return render json: { errors: [event_data[:error]] }, status: :unprocessable_entity
      end

      events = event_data[:data] || []

      filtered_locations = events.map do |event|
        address = event[:address] || ""
        city_state_country = address.split(',').last(3).join(', ').strip
        city_state_country if city_state_country.downcase.include?(location.strip.downcase)
      end.compact.uniq

      render json: { data: [{ location: filtered_locations }] }
    end

    def fetch_locations
      ticketmaster_service = TicketmasterEventService.new(ENV['TICKETMASTER_API_KEY'])
      ticketmaster_events = fetch_ticketmaster_events(ticketmaster_service)

      ticketmaster_events_grouped = ticketmaster_events.group_by do |event|
        address_parts = event[:address].split(',')
        state = address_parts[-2].to_s.strip
        city = address_parts[-3].to_s.strip

        "#{state}, #{city}"
      end

      unique_locations = ticketmaster_events_grouped.keys.uniq
      serialized_locations = unique_locations.map do |location|
        location
      end

      render json: { "data": [{ "location": serialized_locations }] }
    end

    def mark_interested
      event_id = params[:id]

      # Check if user has already marked this event as interested
      if @account.event_interests.exists?(event_uniq_id: params[:id], interest: true)
        render json: { error: 'User has already marked this event as interested' }, status: :unprocessable_entity
        return
      end

      # Mark event as interested for current user
      @account.event_interests.create!(event_uniq_id: params[:id], interest: true)
      interested_people_count = EventInterest.where(event_uniq_id: event_id, interest: true).count
      render json: {
        message: 'Event marked as interested',
        event_id: event_id,
        interested_in: true,
        interested_people_count: interested_people_count
      }, status: :ok
    end

    def search_events
      start_date = params[:start_date]
      end_date = params[:end_date]
      location = params[:location]
      genres = params[:genres]

      ticketmaster_service = TicketmasterEventService.new(ENV['TICKETMASTER_API_KEY'])
      event_data = ticketmaster_service.search_events(
        date_range: { start: start_date, end: end_date },
        city: location,
        genres: genres
      )

      if event_data[:error].present?
        Rails.logger.error("Failed to fetch Ticketmaster events: #{event_data[:error]}")
        return render json: { errors: [event_data[:error]] }, status: :unprocessable_entity
      end

      events = event_data[:data] || []

      serialized_events = events.map do |event|
        {
          id: event[:id],
          title: event[:title],
          event_type: event[:event_type],
          date: event[:date],
          time: event[:time],
          address: event[:address],
          image: event[:image]
        }
      end

      render json: { data: serialized_events }
    end

    def event_details
      event_id = params[:id]
      ticketmaster_service = TicketmasterEventService.new(ENV['TICKETMASTER_API_KEY'])
      event_details = ticketmaster_service.get_event_details(event_id)

      if event_details.key?("error")
        render json: { error: event_details["error"] }, status: :unprocessable_entity
      else
        venue = event_details["_embedded"]["venues"]&.first
        address = format_address(venue)

       # Check if current user is interested in the event
        interested = @account&.event_interests&.exists?(event_uniq_id: event_id, interest: true)
        # Get count of users interested in the event
        interested_people_count = EventInterest.where(event_uniq_id: event_id, interest: true).count


        serialized_event = {
          id: event_details["id"],
          title: event_details["name"],
          event_type: event_details["classifications"]&.dig(0, "genre", "name"),
          date: event_details["dates"]["start"]["localDate"],
          time: event_details["dates"]["start"]["localTime"],
          address: address,
          image: event_details["images"]&.dig(0, "url") || "",
          interested_in: interested || false,
          interested_people_count: interested_people_count
        }

        render json: { data: serialized_event }
      end
    end

    def index
      ticketmaster_service = TicketmasterEventService.new(ENV['TICKETMASTER_API_KEY'])
      ticketmaster_events = fetch_ticketmaster_events(ticketmaster_service)

      ticketmaster_events_grouped = ticketmaster_events.group_by { |event| event[:event_type] }

      serialized_events = ticketmaster_events_grouped.transform_values do |events|
        events.map do |event|
          {
            id: event[:id],
            title: event[:title],
            event_type: event[:event_type],
            date: event[:date],
            time: event[:time],
            address: event[:address],
            image: event[:image].present? ? event[:image] : "",
            interested_in: event[:interested_in] || false,
            interested_people_count: event[:interested_people_count] || 0
          }
        end
      end
      render json: { data: serialized_events }
    end

    # def create
    #   @event = Event.new(events_params)
    #   @event.email_account_id = @account.id
    #   @event.time = params[:data][:attributes][:time].to_time.utc if params[:data][:attributes][:time].present?
    #   @event.repeat = "Never" if @event.repeat.nil?
    #   @event.notify = "15 Minutes Before" if @event.notify.nil?
    #   if @event.save
    #     title = "#{@event.title&.strip} has been created."
    #     assign_event_notification_create(title)
    #     vissible_event_notification_create(title)
    #     render json: EventSerializer.new(@event).serializable_hash, status: :created
    #   else
    #     render json: {errors: [format_activerecord_errors(@event.errors)]}, status: 422
    #   end
    # end

    def show
      render json: EventSerializer.new(@event, params: {account: @account, current_account: @account}).serializable_hash, status: 200
    end

    # def update
    #   return render json: {errors: [{account: "You are not authorize to update event"}]}, status: :unprocessable_entity unless @event.owner?(@account)
    #   event_params = events_params
    #   event_params["time"] = event_params["time"].to_time.utc if event_params["time"].present?
    #   if event_params["date"].present?
    #     new_event_date = event_params["date"].to_date
    #     event_params["date"] = @event.event_occurance.occurs_on?(new_event_date) ? @event.date : new_event_date
    #   end
    #   if @event.update(event_params)
    #     title = "#{@event.title&.strip} has been updated."
    #     body = "#{@event.title&.strip} event created on #{@event.created_at.strftime("%d-%m-%Y")} by #{@account.first_name&.strip || @account.email} is updated"
    #     begin
    #       BxBlockPushnotifications::Notification.new.create_notification(@event, {account: @account, body: body, title: title})
    #     rescue
    #       nil
    #     end
    #     render json: EventSerializer.new(@event, params: {account: @account, current_account: @account}).serializable_hash, status: 200
    #   else
    #     render json: {errors: [format_activerecord_errors(@event.errors)]}, status: 422
    #   end
    # end

    def destroy
      if @event.present?
        @event.destroy
        render json: {message: "Successfully deleted the record"}
      else
        render json: {errors: [
          {account: "Event Not Found"}
        ]}, status: :unprocessable_entity
      end
    end

    def overlap_event
      event_data = Event.find_or_initialize_by(events_params)
      events = BxBlockEvents::Event.account_events(@account.id)
      if params[:data][:event_id].present?
        event = Event.find(params[:data][:event_id])
        events = events.reject { |e| e == event }
      end
      event_data.time = params[:data][:attributes][:time].to_time.utc if params[:data][:attributes][:time].present?
      schedule_events = events.select { |event| event.event_occurance.occurs_on?(event_data.date.to_date) && (event.time.strftime("%H:%M") == event_data.time.strftime("%H:%M")) }
      schedule_events.count.zero? ? (render json: {message: "No event overlap"}) : (render json: {message: "Event overlap"})
    end

    def notes_update
      return render json: {errors: [{account: "You are not authorize to update event"}]}, status: :unprocessable_entity unless @event.owner?(@account) || @event.assign_and_accepted?(@account)
      if @event.update(notes: params[:notes])
        title = "#{@event.title&.strip} has been updated."
        body = "The event's note #{@event.title&.strip} created on #{@event.created_at.strftime("%d-%m-%Y")} is updated by #{@account.first_name&.strip || @account.email}"
        begin
          BxBlockPushnotifications::Notification.new.create_notification(@event, {account: @account, body: body, title: title})
        rescue
          nil
        end
        render json: EventSerializer.new(@event, params: {account: @account, current_account: @account}).serializable_hash, status: 200
      else
        render json: {errors: [format_activerecord_errors(@event.errors)]}, status: 422
      end
    end

    private

    def events_params
      jsonapi_deserialize(params)
    end

    def format_activerecord_errors(errors)
      result = []
      errors.each do |attribute, error|
        result << {attribute => error}
      end
      result
    end

    def format_address(venue)
      return "" unless venue

      parts = []
      parts << venue["address"]["line1"] if venue.dig("address", "line1")
      parts << venue["city"]["name"] if venue.dig("city", "name")
      parts << venue["state"]["stateCode"] if venue.dig("state", "stateCode")
      parts << venue["country"]["name"] if venue.dig("country", "name")
      parts.join(", ")
    end

    # def assign_event_notification_create(title)
    #   if @event.assignment_to.any?
    #     entity_users = @event.assignment_to.to_a << @event.email_account
    #     entity_users.delete(@account)
    #     body = "#{@event.title&.strip} by #{@account&.first_name&.strip || @account.email} has been assigned to you."
    #     create_event_notification(title, body, entity_users)
    #   end
    # end

    # def vissible_event_notification_create(title)
    #   if @event.visible_to.any?
    #     entity_users = @event.visible_to.to_a << @event.email_account
    #     entity_users.delete(@account)
    #     body = "#{@event.title&.strip} by #{@account&.first_name&.strip || @account.email} has been made visible to you."
    #     create_event_notification(title, body, entity_users)
    #   end
    # end

    def create_event_notification(title, body, entity_users)
      BxBlockPushnotifications::Notification.new.create_notification(@event, {account: @account, body: body, title: title, users: entity_users})
    rescue
      nil
    end

    def encode(id)
      BuilderJsonWebToken.encode id
    end

    def set_event
      @event = Event.find(params[:id])
    end

    def set_account
      @account ||= AccountBlock::Account.find(@token.id) if @token.present?
    end

    def fetch_ticketmaster_events(ticketmaster_service)
      if params[:source] == 'ticketmaster'
        genres = params[:genres]
        event_data = ticketmaster_service.search_events(
          page: params[:page],
          size: params[:size],
          keyword: params[:keyword],
          city: params[:city],
          state: params[:state],
          country: params[:country],
          date_range: {
            start: params[:start_date],
            end: params[:end_date]
          },
          genres: genres
        )
        if event_data[:error].present?
          Rails.logger.error("Failed to fetch Ticketmaster events: #{event_data[:error]}")
          []
        else
          event_data[:data] || []
        end
      else
        []
      end
    end
  end
end
