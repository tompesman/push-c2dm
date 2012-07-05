module Push
  class MessageC2dm < Push::Message
    validates :collapse_key, :presence => true
    # TODO: validates max size -> The message size limit is 1024 bytes.
    # TODO" QuotaExceeded — Too many messages sent by the sender. Retry after a while.
    # TODO: DeviceQuotaExceeded — Too many messages sent by the sender to a specific device. Retry after a while.

    store :properties, accessors: [:collapse_key, :delay_when_idle, :payload]
    attr_accessible :device, :collapse_key, :delay_when_idle, :payload

    def to_message
      as_hash.map{|k, v| "&#{k}=#{URI.escape(v.to_s)}"}.reduce{|k, v| k + v}
    end

    def use_connection
      Push::Daemon::C2dmSupport::ConnectionC2dm
    end

    def payload=(attrs)
      raise ArgumentError, "payload must be a Hash" if !attrs.is_a?(Hash)
      properties[:payload] = MultiJson.dump(attrs)
    end

    def payload
      MultiJson.load(properties[:payload]) if properties[:payload]
    end

    private

    def as_hash
      json = ActiveSupport::OrderedHash.new
      json['registration_id'] = device
      json['collapse_key'] = collapse_key
      json['delay_when_idle'] = "1" if delay_when_idle == true
      self.payload.each { |k, v| json["data.#{k.to_s}"] = v.to_s } if payload
      json
    end

    def check_for_error(connection)
      response = connection.response
      error_type = response.body[/Error=(.*)/, 1]
      if response.code.eql? "200" and error_type
        error = Push::DeliveryError.new(response.code, id, error_type, "C2DM")

        # if error_type is one of the following, the registration_id (device) should
        # not be used anymore
        if ["InvalidRegistration", "NotRegistered"].index(error_type)
          with_database_reconnect_and_retry(connection.name) do
            Push::FeedbackC2dm.create!(:failed_at => Time.now, :device => device, :follow_up => 'delete')
          end
        end

        Push::Daemon.logger.error("[#{connection.name}] Error received.")
        raise error if error
      elsif !response.code.eql? "200"
        error = Push::DeliveryError.new(response.code, id, response.description, "C2DM")
        Push::Daemon.logger.error("[#{connection.name}] Error received.")
        raise error if error
      end
    end
  end
end